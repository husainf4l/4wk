import firestore from '@react-native-firebase/firestore';
import { RealtimeEvent, RealtimeSubscription } from '../types/api';
import { loggingService } from './LoggingService';
import { cacheService } from './CacheService';

export interface RealtimeCallback<T = any> {
  (event: RealtimeEvent<T>): void;
}

export interface SyncQueueItem {
  id: string;
  operation: 'create' | 'update' | 'delete';
  collection: string;
  documentId: string;
  data?: any;
  timestamp: number;
  retries: number;
  maxRetries: number;
}

class RealtimeService {
  private subscriptions = new Map<string, () => void>();
  private syncQueue: SyncQueueItem[] = [];
  private isOnline = true;
  private syncInProgress = false;

  constructor() {
    this.setupNetworkListener();
    this.startSyncProcessor();
  }

  private setupNetworkListener() {
    // This would integrate with NetInfo in a real implementation
    // For now, we'll simulate network state changes
  }

  private startSyncProcessor() {
    setInterval(() => {
      if (this.isOnline && !this.syncInProgress && this.syncQueue.length > 0) {
        this.processSyncQueue();
      }
    }, 5000); // Process sync queue every 5 seconds
  }

  private async processSyncQueue() {
    if (this.syncInProgress) return;
    
    this.syncInProgress = true;
    loggingService.info('Processing sync queue', { queueSize: this.syncQueue.length });

    const itemsToProcess = [...this.syncQueue];
    this.syncQueue = [];

    for (const item of itemsToProcess) {
      try {
        await this.executeQueueItem(item);
        loggingService.debug('Sync item processed', { 
          operation: item.operation, 
          collection: item.collection,
          documentId: item.documentId 
        });
      } catch (error) {
        item.retries++;
        if (item.retries < item.maxRetries) {
          this.syncQueue.push(item);
          loggingService.warn('Sync item failed, retrying', { 
            operation: item.operation,
            retries: item.retries,
            error: error.message 
          });
        } else {
          loggingService.error('Sync item failed permanently', { 
            operation: item.operation,
            error: error.message 
          });
        }
      }
    }

    this.syncInProgress = false;
  }

  private async executeQueueItem(item: SyncQueueItem) {
    const docRef = firestore().collection(item.collection).doc(item.documentId);

    switch (item.operation) {
      case 'create':
      case 'update':
        await docRef.set(item.data, { merge: item.operation === 'update' });
        break;
      case 'delete':
        await docRef.delete();
        break;
    }
  }

  private generateSubscriptionId(): string {
    return `sub_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Real-time subscriptions
  subscribeToCollection<T>(
    collection: string,
    callback: RealtimeCallback<T>,
    query?: any
  ): string {
    const subscriptionId = this.generateSubscriptionId();

    try {
      let ref = firestore().collection(collection);

      // Apply query constraints if provided
      if (query) {
        if (query.where) {
          query.where.forEach(([field, operator, value]: [string, any, any]) => {
            ref = ref.where(field, operator, value);
          });
        }
        if (query.orderBy) {
          ref = ref.orderBy(query.orderBy.field, query.orderBy.direction);
        }
        if (query.limit) {
          ref = ref.limit(query.limit);
        }
      }

      const unsubscribe = ref.onSnapshot(
        (snapshot) => {
          snapshot.docChanges().forEach((change) => {
            const event: RealtimeEvent<T> = {
              type: change.type === 'added' ? 'create' : 
                    change.type === 'modified' ? 'update' : 'delete',
              collection,
              documentId: change.doc.id,
              data: change.doc.data() as T,
              timestamp: new Date(),
            };

            // Update cache
            if (event.type === 'delete') {
              cacheService.remove(`${collection}:${event.documentId}`);
            } else {
              cacheService.set(`${collection}:${event.documentId}`, event.data);
            }

            callback(event);
          });
        },
        (error) => {
          loggingService.error('Realtime subscription error', {
            collection,
            subscriptionId,
            error: error.message,
          });
        }
      );

      this.subscriptions.set(subscriptionId, unsubscribe);
      
      loggingService.info('Realtime subscription created', { 
        collection, 
        subscriptionId 
      });

      return subscriptionId;
    } catch (error) {
      loggingService.error('Failed to create realtime subscription', {
        collection,
        error: error.message,
      });
      throw error;
    }
  }

  subscribeToDocument<T>(
    collection: string,
    documentId: string,
    callback: RealtimeCallback<T>
  ): string {
    const subscriptionId = this.generateSubscriptionId();

    try {
      const unsubscribe = firestore()
        .collection(collection)
        .doc(documentId)
        .onSnapshot(
          (snapshot) => {
            const event: RealtimeEvent<T> = {
              type: snapshot.exists ? 'update' : 'delete',
              collection,
              documentId,
              data: snapshot.data() as T,
              timestamp: new Date(),
            };

            // Update cache
            if (event.type === 'delete') {
              cacheService.remove(`${collection}:${documentId}`);
            } else {
              cacheService.set(`${collection}:${documentId}`, event.data);
            }

            callback(event);
          },
          (error) => {
            loggingService.error('Document subscription error', {
              collection,
              documentId,
              subscriptionId,
              error: error.message,
            });
          }
        );

      this.subscriptions.set(subscriptionId, unsubscribe);
      
      loggingService.info('Document subscription created', { 
        collection, 
        documentId,
        subscriptionId 
      });

      return subscriptionId;
    } catch (error) {
      loggingService.error('Failed to create document subscription', {
        collection,
        documentId,
        error: error.message,
      });
      throw error;
    }
  }

  unsubscribe(subscriptionId: string): void {
    const unsubscribe = this.subscriptions.get(subscriptionId);
    if (unsubscribe) {
      unsubscribe();
      this.subscriptions.delete(subscriptionId);
      loggingService.info('Subscription removed', { subscriptionId });
    }
  }

  unsubscribeAll(): void {
    this.subscriptions.forEach((unsubscribe, subscriptionId) => {
      unsubscribe();
      loggingService.debug('Subscription removed', { subscriptionId });
    });
    this.subscriptions.clear();
    loggingService.info('All subscriptions removed');
  }

  // Offline sync operations
  queueCreate(collection: string, documentId: string, data: any): void {
    const item: SyncQueueItem = {
      id: this.generateSyncId(),
      operation: 'create',
      collection,
      documentId,
      data,
      timestamp: Date.now(),
      retries: 0,
      maxRetries: 3,
    };

    this.syncQueue.push(item);
    loggingService.info('Create operation queued', { collection, documentId });

    // Also cache locally for immediate UI updates
    cacheService.set(`${collection}:${documentId}`, { id: documentId, ...data });
  }

  queueUpdate(collection: string, documentId: string, data: any): void {
    const item: SyncQueueItem = {
      id: this.generateSyncId(),
      operation: 'update',
      collection,
      documentId,
      data,
      timestamp: Date.now(),
      retries: 0,
      maxRetries: 3,
    };

    this.syncQueue.push(item);
    loggingService.info('Update operation queued', { collection, documentId });

    // Update cache optimistically
    cacheService.get(`${collection}:${documentId}`).then(cached => {
      if (cached) {
        cacheService.set(`${collection}:${documentId}`, { ...cached, ...data });
      }
    });
  }

  queueDelete(collection: string, documentId: string): void {
    const item: SyncQueueItem = {
      id: this.generateSyncId(),
      operation: 'delete',
      collection,
      documentId,
      timestamp: Date.now(),
      retries: 0,
      maxRetries: 3,
    };

    this.syncQueue.push(item);
    loggingService.info('Delete operation queued', { collection, documentId });

    // Remove from cache
    cacheService.remove(`${collection}:${documentId}`);
  }

  private generateSyncId(): string {
    return `sync_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Entity-specific subscriptions
  subscribeToCustomerUpdates(customerId: string, callback: RealtimeCallback): string {
    return this.subscribeToDocument('customers', customerId, callback);
  }

  subscribeToCustomerCars(customerId: string, callback: RealtimeCallback): string {
    return this.subscribeToCollection('cars', callback, {
      where: [['customerId', '==', customerId]],
      orderBy: { field: 'createdAt', direction: 'desc' },
    });
  }

  subscribeToSessionUpdates(sessionId: string, callback: RealtimeCallback): string {
    return this.subscribeToDocument('sessions', sessionId, callback);
  }

  subscribeToActiveSessions(userId: string, callback: RealtimeCallback): string {
    return this.subscribeToCollection('sessions', callback, {
      where: [
        ['assignedTo', '==', userId],
        ['status', 'in', ['in_progress', 'inspection', 'test_drive']],
      ],
      orderBy: { field: 'createdAt', direction: 'desc' },
    });
  }

  subscribeToUserNotifications(userId: string, callback: RealtimeCallback): string {
    return this.subscribeToCollection('notifications', callback, {
      where: [
        ['userId', '==', userId],
        ['read', '==', false],
      ],
      orderBy: { field: 'createdAt', direction: 'desc' },
      limit: 50,
    });
  }

  // Batch operations
  async executeBatch(operations: Array<{
    type: 'create' | 'update' | 'delete';
    collection: string;
    documentId: string;
    data?: any;
  }>): Promise<void> {
    if (!this.isOnline) {
      // Queue all operations for later
      operations.forEach(op => {
        switch (op.type) {
          case 'create':
            this.queueCreate(op.collection, op.documentId, op.data);
            break;
          case 'update':
            this.queueUpdate(op.collection, op.documentId, op.data);
            break;
          case 'delete':
            this.queueDelete(op.collection, op.documentId);
            break;
        }
      });
      return;
    }

    try {
      const batch = firestore().batch();

      operations.forEach(op => {
        const docRef = firestore().collection(op.collection).doc(op.documentId);
        
        switch (op.type) {
          case 'create':
          case 'update':
            batch.set(docRef, op.data, { merge: op.type === 'update' });
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      });

      await batch.commit();
      loggingService.info('Batch operation completed', { operationCount: operations.length });
    } catch (error) {
      loggingService.error('Batch operation failed', { 
        operationCount: operations.length,
        error: error.message 
      });
      throw error;
    }
  }

  // Status and monitoring
  setOnlineStatus(isOnline: boolean): void {
    this.isOnline = isOnline;
    loggingService.info('Network status changed', { isOnline });

    if (isOnline && this.syncQueue.length > 0) {
      loggingService.info('Back online, processing sync queue');
    }
  }

  getSyncQueueStatus(): {
    queueSize: number;
    syncInProgress: boolean;
    isOnline: boolean;
  } {
    return {
      queueSize: this.syncQueue.length,
      syncInProgress: this.syncInProgress,
      isOnline: this.isOnline,
    };
  }

  getActiveSubscriptions(): Array<{ id: string; collection?: string }> {
    return Array.from(this.subscriptions.keys()).map(id => ({ id }));
  }

  // Force sync
  async forceSyncNow(): Promise<void> {
    if (!this.isOnline) {
      throw new Error('Cannot sync while offline');
    }

    await this.processSyncQueue();
  }

  // Clear sync queue (use with caution)
  clearSyncQueue(): void {
    this.syncQueue = [];
    loggingService.warn('Sync queue cleared manually');
  }
}

export const realtimeService = new RealtimeService();