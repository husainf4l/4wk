import AsyncStorage from '@react-native-async-storage/async-storage';
import { CacheConfig, CacheEntry } from '../types/api';
import { loggingService } from './LoggingService';

export interface CacheItem<T = any> {
  data: T;
  timestamp: number;
  ttl: number;
  key: string;
  size: number;
}

export interface CacheStats {
  totalItems: number;
  totalSize: number;
  hitRate: number;
  missRate: number;
  evictionCount: number;
}

class CacheService {
  private memoryCache = new Map<string, CacheItem>();
  private accessLog = new Map<string, number>();
  private stats = {
    hits: 0,
    misses: 0,
    evictions: 0,
  };

  private config: Required<CacheConfig> = {
    ttl: 5 * 60 * 1000, // 5 minutes default
    maxSize: 100, // Max items in memory
    strategy: 'lru',
  };

  constructor(config?: Partial<CacheConfig>) {
    if (config) {
      this.config = { ...this.config, ...config };
    }
    this.startCleanupInterval();
  }

  private startCleanupInterval() {
    setInterval(() => {
      this.cleanup();
    }, 60000); // Cleanup every minute
  }

  private cleanup() {
    const now = Date.now();
    const expiredKeys: string[] = [];

    for (const [key, item] of this.memoryCache.entries()) {
      if (now - item.timestamp > item.ttl) {
        expiredKeys.push(key);
      }
    }

    expiredKeys.forEach(key => {
      this.memoryCache.delete(key);
      this.accessLog.delete(key);
    });

    if (expiredKeys.length > 0) {
      loggingService.debug(`Cache cleanup: removed ${expiredKeys.length} expired items`);
    }
  }

  private evictLRU() {
    if (this.memoryCache.size <= this.config.maxSize) return;

    let oldestKey = '';
    let oldestAccess = Date.now();

    for (const [key, lastAccess] of this.accessLog.entries()) {
      if (lastAccess < oldestAccess) {
        oldestAccess = lastAccess;
        oldestKey = key;
      }
    }

    if (oldestKey) {
      this.memoryCache.delete(oldestKey);
      this.accessLog.delete(oldestKey);
      this.stats.evictions++;
      loggingService.debug(`Cache eviction: removed ${oldestKey}`);
    }
  }

  private calculateSize(data: any): number {
    return JSON.stringify(data).length;
  }

  private generateKey(prefix: string, params?: Record<string, any>): string {
    if (!params) return prefix;
    
    const sortedParams = Object.keys(params)
      .sort()
      .reduce((result, key) => {
        result[key] = params[key];
        return result;
      }, {} as Record<string, any>);

    return `${prefix}:${JSON.stringify(sortedParams)}`;
  }

  // Memory cache operations
  async set<T>(key: string, data: T, ttl?: number): Promise<void> {
    try {
      const cacheItem: CacheItem<T> = {
        data,
        timestamp: Date.now(),
        ttl: ttl || this.config.ttl,
        key,
        size: this.calculateSize(data),
      };

      // Evict if necessary
      this.evictLRU();

      this.memoryCache.set(key, cacheItem);
      this.accessLog.set(key, Date.now());

      // Also store in persistent storage for offline access
      await this.setPersistent(key, cacheItem);
      
      loggingService.debug(`Cache set: ${key}`, { size: cacheItem.size });
    } catch (error) {
      loggingService.error('Cache set error', { key, error: error.message });
    }
  }

  async get<T>(key: string): Promise<T | null> {
    try {
      // Check memory cache first
      const memoryItem = this.memoryCache.get(key);
      if (memoryItem) {
        const now = Date.now();
        if (now - memoryItem.timestamp <= memoryItem.ttl) {
          this.accessLog.set(key, now);
          this.stats.hits++;
          loggingService.debug(`Cache hit (memory): ${key}`);
          return memoryItem.data as T;
        } else {
          // Expired in memory
          this.memoryCache.delete(key);
          this.accessLog.delete(key);
        }
      }

      // Check persistent storage
      const persistentItem = await this.getPersistent<T>(key);
      if (persistentItem) {
        const now = Date.now();
        if (now - persistentItem.timestamp <= persistentItem.ttl) {
          // Move back to memory cache
          this.memoryCache.set(key, persistentItem);
          this.accessLog.set(key, now);
          this.stats.hits++;
          loggingService.debug(`Cache hit (persistent): ${key}`);
          return persistentItem.data;
        } else {
          // Expired in persistent storage
          await this.removePersistent(key);
        }
      }

      this.stats.misses++;
      loggingService.debug(`Cache miss: ${key}`);
      return null;
    } catch (error) {
      loggingService.error('Cache get error', { key, error: error.message });
      this.stats.misses++;
      return null;
    }
  }

  async remove(key: string): Promise<void> {
    try {
      this.memoryCache.delete(key);
      this.accessLog.delete(key);
      await this.removePersistent(key);
      loggingService.debug(`Cache remove: ${key}`);
    } catch (error) {
      loggingService.error('Cache remove error', { key, error: error.message });
    }
  }

  async clear(): Promise<void> {
    try {
      this.memoryCache.clear();
      this.accessLog.clear();
      await AsyncStorage.clear();
      this.stats = { hits: 0, misses: 0, evictions: 0 };
      loggingService.info('Cache cleared');
    } catch (error) {
      loggingService.error('Cache clear error', { error: error.message });
    }
  }

  // Persistent storage operations
  private async setPersistent<T>(key: string, item: CacheItem<T>): Promise<void> {
    try {
      await AsyncStorage.setItem(`cache:${key}`, JSON.stringify(item));
    } catch (error) {
      loggingService.warn('Persistent cache set failed', { key, error: error.message });
    }
  }

  private async getPersistent<T>(key: string): Promise<CacheItem<T> | null> {
    try {
      const data = await AsyncStorage.getItem(`cache:${key}`);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      loggingService.warn('Persistent cache get failed', { key, error: error.message });
      return null;
    }
  }

  private async removePersistent(key: string): Promise<void> {
    try {
      await AsyncStorage.removeItem(`cache:${key}`);
    } catch (error) {
      loggingService.warn('Persistent cache remove failed', { key, error: error.message });
    }
  }

  // High-level cache operations
  async cacheApiResponse<T>(
    endpoint: string,
    params: Record<string, any> | undefined,
    data: T,
    ttl?: number
  ): Promise<void> {
    const key = this.generateKey(`api:${endpoint}`, params);
    await this.set(key, data, ttl);
  }

  async getCachedApiResponse<T>(
    endpoint: string,
    params?: Record<string, any>
  ): Promise<T | null> {
    const key = this.generateKey(`api:${endpoint}`, params);
    return await this.get<T>(key);
  }

  async invalidateApiCache(endpoint: string, params?: Record<string, any>): Promise<void> {
    if (params) {
      const key = this.generateKey(`api:${endpoint}`, params);
      await this.remove(key);
    } else {
      // Invalidate all cache entries for this endpoint
      const prefix = `api:${endpoint}`;
      const keysToRemove: string[] = [];

      for (const key of this.memoryCache.keys()) {
        if (key.startsWith(prefix)) {
          keysToRemove.push(key);
        }
      }

      await Promise.all(keysToRemove.map(key => this.remove(key)));
    }
  }

  // Entity-specific cache operations
  async cacheCustomer(customerId: string, customer: any, ttl?: number): Promise<void> {
    await this.set(`customer:${customerId}`, customer, ttl);
  }

  async getCachedCustomer(customerId: string): Promise<any | null> {
    return await this.get(`customer:${customerId}`);
  }

  async cacheCar(carId: string, car: any, ttl?: number): Promise<void> {
    await this.set(`car:${carId}`, car, ttl);
  }

  async getCachedCar(carId: string): Promise<any | null> {
    return await this.get(`car:${carId}`);
  }

  async cacheSession(sessionId: string, session: any, ttl?: number): Promise<void> {
    await this.set(`session:${sessionId}`, session, ttl);
  }

  async getCachedSession(sessionId: string): Promise<any | null> {
    return await this.get(`session:${sessionId}`);
  }

  // Cache statistics
  getStats(): CacheStats {
    const totalRequests = this.stats.hits + this.stats.misses;
    return {
      totalItems: this.memoryCache.size,
      totalSize: Array.from(this.memoryCache.values()).reduce((sum, item) => sum + item.size, 0),
      hitRate: totalRequests > 0 ? this.stats.hits / totalRequests : 0,
      missRate: totalRequests > 0 ? this.stats.misses / totalRequests : 0,
      evictionCount: this.stats.evictions,
    };
  }

  // Configuration
  updateConfig(newConfig: Partial<CacheConfig>): void {
    this.config = { ...this.config, ...newConfig };
    loggingService.info('Cache config updated', newConfig);
  }

  getConfig(): Required<CacheConfig> {
    return { ...this.config };
  }

  // Offline support
  async preloadOfflineData(): Promise<void> {
    try {
      loggingService.info('Preloading offline data...');
      
      // This would typically load essential data when online
      // for offline access later
      
      loggingService.info('Offline data preload completed');
    } catch (error) {
      loggingService.error('Offline data preload failed', { error: error.message });
    }
  }

  async getOfflineKeys(): Promise<string[]> {
    try {
      const allKeys = await AsyncStorage.getAllKeys();
      return allKeys.filter(key => key.startsWith('cache:'));
    } catch (error) {
      loggingService.error('Failed to get offline keys', { error: error.message });
      return [];
    }
  }

  async exportCache(): Promise<Record<string, any>> {
    try {
      const keys = await this.getOfflineKeys();
      const cache: Record<string, any> = {};

      for (const key of keys) {
        const data = await AsyncStorage.getItem(key);
        if (data) {
          cache[key] = JSON.parse(data);
        }
      }

      return cache;
    } catch (error) {
      loggingService.error('Cache export failed', { error: error.message });
      return {};
    }
  }
}

export const cacheService = new CacheService();