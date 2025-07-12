import AsyncStorage from '@react-native-async-storage/async-storage';
import { loggingService } from './LoggingService';

export interface PersistenceConfig {
  version: number;
  migrations: Record<number, (data: any) => any>;
  encryptionKey?: string;
  compressionEnabled: boolean;
  maxSize: number; // in bytes
}

export interface StorageItem<T = any> {
  version: number;
  data: T;
  timestamp: number;
  checksum?: string;
}

class PersistenceService {
  private config: PersistenceConfig = {
    version: 1,
    migrations: {},
    compressionEnabled: false,
    maxSize: 10 * 1024 * 1024, // 10MB
  };

  constructor(config?: Partial<PersistenceConfig>) {
    if (config) {
      this.config = { ...this.config, ...config };
    }
  }

  private generateChecksum(data: string): string {
    // Simple checksum - in production you'd use a proper hash function
    let hash = 0;
    for (let i = 0; i < data.length; i++) {
      const char = data.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toString();
  }

  private async encrypt(data: string): Promise<string> {
    // Placeholder for encryption - implement with a proper crypto library
    return data;
  }

  private async decrypt(data: string): Promise<string> {
    // Placeholder for decryption - implement with a proper crypto library
    return data;
  }

  private compress(data: string): string {
    // Placeholder for compression - implement with a compression library
    return data;
  }

  private decompress(data: string): string {
    // Placeholder for decompression - implement with a compression library
    return data;
  }

  private async migrateData(item: StorageItem, targetVersion: number): Promise<StorageItem> {
    let migrated = { ...item };
    
    for (let version = item.version; version < targetVersion; version++) {
      const migration = this.config.migrations[version + 1];
      if (migration) {
        migrated.data = migration(migrated.data);
        migrated.version = version + 1;
        loggingService.info(`Data migrated from version ${version} to ${version + 1}`);
      }
    }
    
    return migrated;
  }

  private async validateSize(data: string): Promise<boolean> {
    const size = new Blob([data]).size;
    if (size > this.config.maxSize) {
      loggingService.warn('Data exceeds maximum size limit', { 
        size, 
        maxSize: this.config.maxSize 
      });
      return false;
    }
    return true;
  }

  // Core storage operations
  async store<T>(key: string, data: T, options?: {
    encrypt?: boolean;
    compress?: boolean;
    skipValidation?: boolean;
  }): Promise<void> {
    try {
      const storageItem: StorageItem<T> = {
        version: this.config.version,
        data,
        timestamp: Date.now(),
      };

      let serialized = JSON.stringify(storageItem);

      // Generate checksum
      storageItem.checksum = this.generateChecksum(serialized);
      serialized = JSON.stringify(storageItem);

      // Validate size
      if (!options?.skipValidation && !(await this.validateSize(serialized))) {
        throw new Error('Data size exceeds limit');
      }

      // Compress if enabled
      if (options?.compress || this.config.compressionEnabled) {
        serialized = this.compress(serialized);
      }

      // Encrypt if requested
      if (options?.encrypt && this.config.encryptionKey) {
        serialized = await this.encrypt(serialized);
      }

      await AsyncStorage.setItem(key, serialized);
      
      loggingService.debug('Data stored successfully', { 
        key, 
        size: serialized.length,
        encrypted: !!options?.encrypt,
        compressed: !!(options?.compress || this.config.compressionEnabled)
      });
    } catch (error) {
      loggingService.error('Failed to store data', { 
        key, 
        error: error.message 
      });
      throw error;
    }
  }

  async retrieve<T>(key: string, options?: {
    decrypt?: boolean;
    decompress?: boolean;
    skipMigration?: boolean;
  }): Promise<T | null> {
    try {
      let serialized = await AsyncStorage.getItem(key);
      if (!serialized) {
        return null;
      }

      // Decrypt if necessary
      if (options?.decrypt && this.config.encryptionKey) {
        serialized = await this.decrypt(serialized);
      }

      // Decompress if necessary
      if (options?.decompress || this.config.compressionEnabled) {
        serialized = this.decompress(serialized);
      }

      const item: StorageItem<T> = JSON.parse(serialized);

      // Verify checksum
      const { checksum, ...itemWithoutChecksum } = item;
      const expectedChecksum = this.generateChecksum(JSON.stringify(itemWithoutChecksum));
      
      if (checksum && checksum !== expectedChecksum) {
        loggingService.warn('Data integrity check failed', { key });
        // Optionally, you could throw an error here or attempt recovery
      }

      // Migrate if necessary
      if (!options?.skipMigration && item.version < this.config.version) {
        const migrated = await this.migrateData(item, this.config.version);
        
        // Store the migrated data
        await this.store(key, migrated.data, options);
        
        return migrated.data;
      }

      loggingService.debug('Data retrieved successfully', { 
        key, 
        version: item.version,
        age: Date.now() - item.timestamp
      });

      return item.data;
    } catch (error) {
      loggingService.error('Failed to retrieve data', { 
        key, 
        error: error.message 
      });
      return null;
    }
  }

  async remove(key: string): Promise<void> {
    try {
      await AsyncStorage.removeItem(key);
      loggingService.debug('Data removed successfully', { key });
    } catch (error) {
      loggingService.error('Failed to remove data', { 
        key, 
        error: error.message 
      });
      throw error;
    }
  }

  async clear(): Promise<void> {
    try {
      await AsyncStorage.clear();
      loggingService.info('All persistent data cleared');
    } catch (error) {
      loggingService.error('Failed to clear data', { error: error.message });
      throw error;
    }
  }

  // App state persistence
  async persistAppState(state: any): Promise<void> {
    await this.store('app_state', state, { compress: true });
  }

  async hydrateAppState(): Promise<any | null> {
    return await this.retrieve('app_state', { decompress: true });
  }

  // User preferences
  async persistUserPreferences(userId: string, preferences: any): Promise<void> {
    await this.store(`user_preferences:${userId}`, preferences);
  }

  async hydrateUserPreferences(userId: string): Promise<any | null> {
    return await this.retrieve(`user_preferences:${userId}`);
  }

  // Form data persistence (for incomplete forms)
  async persistFormData(formId: string, data: any): Promise<void> {
    await this.store(`form_data:${formId}`, {
      ...data,
      savedAt: new Date().toISOString(),
    });
  }

  async hydrateFormData(formId: string): Promise<any | null> {
    const data = await this.retrieve(`form_data:${formId}`);
    if (data) {
      loggingService.info('Form data restored', { formId, savedAt: data.savedAt });
    }
    return data;
  }

  async clearFormData(formId: string): Promise<void> {
    await this.remove(`form_data:${formId}`);
  }

  // Draft data persistence
  async persistDraft(type: string, id: string, data: any): Promise<void> {
    await this.store(`draft:${type}:${id}`, {
      ...data,
      draftCreatedAt: new Date().toISOString(),
      draftType: type,
    });
  }

  async hydrateDraft(type: string, id: string): Promise<any | null> {
    return await this.retrieve(`draft:${type}:${id}`);
  }

  async getDrafts(type?: string): Promise<Array<{ key: string; data: any }>> {
    try {
      const keys = await AsyncStorage.getAllKeys();
      const draftKeys = keys.filter(key => 
        type ? key.startsWith(`draft:${type}:`) : key.startsWith('draft:')
      );

      const drafts = await Promise.all(
        draftKeys.map(async key => ({
          key,
          data: await this.retrieve(key)
        }))
      );

      return drafts.filter(draft => draft.data !== null);
    } catch (error) {
      loggingService.error('Failed to get drafts', { error: error.message });
      return [];
    }
  }

  async clearDraft(type: string, id: string): Promise<void> {
    await this.remove(`draft:${type}:${id}`);
  }

  // Session persistence
  async persistSession(sessionData: any): Promise<void> {
    await this.store('current_session', sessionData, { encrypt: true });
  }

  async hydrateSession(): Promise<any | null> {
    return await this.retrieve('current_session', { decrypt: true });
  }

  async clearSession(): Promise<void> {
    await this.remove('current_session');
  }

  // Settings persistence
  async persistSettings(settings: any): Promise<void> {
    await this.store('app_settings', settings);
  }

  async hydrateSettings(): Promise<any | null> {
    return await this.retrieve('app_settings');
  }

  // Offline queue persistence
  async persistOfflineQueue(queue: any[]): Promise<void> {
    await this.store('offline_queue', queue, { compress: true });
  }

  async hydrateOfflineQueue(): Promise<any[] | null> {
    return await this.retrieve('offline_queue', { decompress: true });
  }

  // Search history
  async persistSearchHistory(query: string, type: string): Promise<void> {
    const history = await this.retrieve(`search_history:${type}`) || [];
    const updated = [query, ...history.filter((q: string) => q !== query)].slice(0, 10);
    await this.store(`search_history:${type}`, updated);
  }

  async hydrateSearchHistory(type: string): Promise<string[]> {
    return await this.retrieve(`search_history:${type}`) || [];
  }

  // Recently viewed items
  async persistRecentlyViewed(type: string, item: any): Promise<void> {
    const recent = await this.retrieve(`recent:${type}`) || [];
    const updated = [
      item,
      ...recent.filter((r: any) => r.id !== item.id)
    ].slice(0, 20);
    await this.store(`recent:${type}`, updated);
  }

  async hydrateRecentlyViewed(type: string): Promise<any[]> {
    return await this.retrieve(`recent:${type}`) || [];
  }

  // Storage analytics
  async getStorageInfo(): Promise<{
    totalKeys: number;
    estimatedSize: number;
    keysByPrefix: Record<string, number>;
  }> {
    try {
      const keys = await AsyncStorage.getAllKeys();
      let estimatedSize = 0;
      const keysByPrefix: Record<string, number> = {};

      for (const key of keys) {
        const value = await AsyncStorage.getItem(key);
        if (value) {
          estimatedSize += value.length;
        }

        const prefix = key.split(':')[0];
        keysByPrefix[prefix] = (keysByPrefix[prefix] || 0) + 1;
      }

      return {
        totalKeys: keys.length,
        estimatedSize,
        keysByPrefix,
      };
    } catch (error) {
      loggingService.error('Failed to get storage info', { error: error.message });
      return {
        totalKeys: 0,
        estimatedSize: 0,
        keysByPrefix: {},
      };
    }
  }

  // Cleanup operations
  async cleanupExpiredData(maxAge: number = 7 * 24 * 60 * 60 * 1000): Promise<void> {
    try {
      const keys = await AsyncStorage.getAllKeys();
      const now = Date.now();
      const keysToRemove: string[] = [];

      for (const key of keys) {
        try {
          const serialized = await AsyncStorage.getItem(key);
          if (serialized) {
            const item: StorageItem = JSON.parse(serialized);
            if (now - item.timestamp > maxAge) {
              keysToRemove.push(key);
            }
          }
        } catch {
          // Invalid data, remove it
          keysToRemove.push(key);
        }
      }

      await Promise.all(keysToRemove.map(key => AsyncStorage.removeItem(key)));
      
      loggingService.info('Cleanup completed', { 
        removedKeys: keysToRemove.length,
        maxAge: maxAge 
      });
    } catch (error) {
      loggingService.error('Cleanup failed', { error: error.message });
    }
  }

  // Configuration
  updateConfig(newConfig: Partial<PersistenceConfig>): void {
    this.config = { ...this.config, ...newConfig };
    loggingService.info('Persistence config updated', newConfig);
  }

  getConfig(): PersistenceConfig {
    return { ...this.config };
  }
}

export const persistenceService = new PersistenceService();