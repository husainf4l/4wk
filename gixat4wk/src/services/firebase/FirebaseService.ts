import { firebaseFirestore, firebaseAuth } from '../../config/firebase';
import { ApiResponse } from '../../types';

export class FirebaseService {
  protected db = firebaseFirestore;
  protected auth = firebaseAuth;

  /**
   * Generic method to add a document to a collection
   */
  protected async addDocument<T>(
    collection: string, 
    data: Omit<T, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<ApiResponse<T & { id: string }>> {
    try {
      const currentUser = this.auth.currentUser;
      if (!currentUser) {
        throw new Error('User not authenticated');
      }

      const timestamp = new Date();
      const documentData = {
        ...data,
        createdAt: timestamp,
        updatedAt: timestamp,
        createdBy: currentUser.uid,
      };

      const docRef = await this.db.collection(collection).add(documentData);
      const newDoc = await docRef.get();

      if (!newDoc.exists) {
        throw new Error('Failed to create document');
      }

      return {
        success: true,
        data: {
          id: docRef.id,
          ...newDoc.data(),
        } as T & { id: string },
        message: 'Document created successfully',
      };
    } catch (error) {
      console.error(`Error adding document to ${collection}:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      };
    }
  }

  /**
   * Generic method to update a document
   */
  protected async updateDocument<T>(
    collection: string,
    id: string,
    data: Partial<T>
  ): Promise<ApiResponse<T>> {
    try {
      const currentUser = this.auth.currentUser;
      if (!currentUser) {
        throw new Error('User not authenticated');
      }

      const updateData = {
        ...data,
        updatedAt: new Date(),
        lastModifiedBy: currentUser.uid,
      };

      await this.db.collection(collection).doc(id).update(updateData);
      
      const updatedDoc = await this.db.collection(collection).doc(id).get();
      
      if (!updatedDoc.exists) {
        throw new Error('Document not found');
      }

      return {
        success: true,
        data: {
          id: updatedDoc.id,
          ...updatedDoc.data(),
        } as T,
        message: 'Document updated successfully',
      };
    } catch (error) {
      console.error(`Error updating document in ${collection}:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      };
    }
  }

  /**
   * Generic method to get a document by ID
   */
  protected async getDocument<T>(
    collection: string,
    id: string
  ): Promise<ApiResponse<T>> {
    try {
      const doc = await this.db.collection(collection).doc(id).get();
      
      if (!doc.exists) {
        return {
          success: false,
          error: 'Document not found',
        };
      }

      return {
        success: true,
        data: {
          id: doc.id,
          ...doc.data(),
        } as T,
      };
    } catch (error) {
      console.error(`Error getting document from ${collection}:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      };
    }
  }

  /**
   * Generic method to get documents with filtering and pagination
   */
  protected async getDocuments<T>(
    collection: string,
    options: {
      where?: { field: string; operator: any; value: any }[];
      orderBy?: { field: string; direction: 'asc' | 'desc' };
      limit?: number;
      startAfter?: any;
    } = {}
  ): Promise<ApiResponse<T[]>> {
    try {
      let query: any = this.db.collection(collection);

      // Apply where clauses
      if (options.where) {
        options.where.forEach(({ field, operator, value }) => {
          query = query.where(field, operator, value);
        });
      }

      // Apply ordering
      if (options.orderBy) {
        query = query.orderBy(options.orderBy.field, options.orderBy.direction);
      }

      // Apply limit
      if (options.limit) {
        query = query.limit(options.limit);
      }

      // Apply pagination
      if (options.startAfter) {
        query = query.startAfter(options.startAfter);
      }

      const snapshot = await query.get();
      
      const documents: T[] = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as T[];

      return {
        success: true,
        data: documents,
      };
    } catch (error) {
      console.error(`Error getting documents from ${collection}:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      };
    }
  }

  /**
   * Generic method to delete a document
   */
  protected async deleteDocument(
    collection: string,
    id: string
  ): Promise<ApiResponse<boolean>> {
    try {
      await this.db.collection(collection).doc(id).delete();
      
      return {
        success: true,
        data: true,
        message: 'Document deleted successfully',
      };
    } catch (error) {
      console.error(`Error deleting document from ${collection}:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      };
    }
  }

  /**
   * Check if user is authenticated
   */
  protected isAuthenticated(): boolean {
    return !!this.auth.currentUser;
  }

  /**
   * Get current user ID
   */
  protected getCurrentUserId(): string | null {
    return this.auth.currentUser?.uid || null;
  }

  /**
   * Batch write operations
   */
  protected async batchWrite(
    operations: Array<{
      type: 'set' | 'update' | 'delete';
      collection: string;
      id?: string;
      data?: any;
    }>
  ): Promise<ApiResponse<boolean>> {
    try {
      const batch = this.db.batch();

      operations.forEach(({ type, collection, id, data }) => {
        const docRef = id 
          ? this.db.collection(collection).doc(id)
          : this.db.collection(collection).doc();

        switch (type) {
          case 'set':
            batch.set(docRef, {
              ...data,
              createdAt: new Date(),
              updatedAt: new Date(),
              createdBy: this.getCurrentUserId(),
            });
            break;
          case 'update':
            batch.update(docRef, {
              ...data,
              updatedAt: new Date(),
              lastModifiedBy: this.getCurrentUserId(),
            });
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      });

      await batch.commit();

      return {
        success: true,
        data: true,
        message: 'Batch operation completed successfully',
      };
    } catch (error) {
      console.error('Error in batch operation:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      };
    }
  }
}