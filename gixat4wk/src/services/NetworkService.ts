import NetInfo from '@react-native-community/netinfo';
import { NetworkResponse, RequestConfig } from '../types/api';
import { loggingService } from './LoggingService';
import { analyticsService } from './AnalyticsService';

export interface RetryConfig {
  maxRetries: number;
  baseDelay: number;
  maxDelay: number;
  backoffFactor: number;
  retryCondition: (error: any, attempt: number) => boolean;
}

export interface NetworkStatus {
  isConnected: boolean;
  type: string;
  isInternetReachable: boolean;
  details: any;
}

export interface QueuedRequest {
  id: string;
  url: string;
  options: RequestInit;
  config: RequestConfig;
  resolve: (response: NetworkResponse) => void;
  reject: (error: Error) => void;
  createdAt: number;
  retries: number;
}

class NetworkService {
  private isOnline = true;
  private networkStatus: NetworkStatus = {
    isConnected: false,
    type: 'unknown',
    isInternetReachable: false,
    details: null,
  };
  
  private requestQueue: QueuedRequest[] = [];
  private isProcessingQueue = false;
  private listeners: Array<(status: NetworkStatus) => void> = [];

  private defaultRetryConfig: RetryConfig = {
    maxRetries: 3,
    baseDelay: 1000,
    maxDelay: 30000,
    backoffFactor: 2,
    retryCondition: (error: any, attempt: number) => {
      // Retry on network errors and 5xx server errors
      if (error.name === 'TypeError' && error.message.includes('Network request failed')) {
        return true;
      }
      if (error.status >= 500 && error.status < 600) {
        return true;
      }
      // Don't retry 4xx errors (client errors)
      if (error.status >= 400 && error.status < 500) {
        return false;
      }
      return attempt < 3;
    },
  };

  constructor() {
    this.initializeNetworkMonitoring();
  }

  private async initializeNetworkMonitoring(): Promise<void> {
    try {
      // Get initial network state
      const state = await NetInfo.fetch();
      this.updateNetworkStatus(state);

      // Subscribe to network state changes
      NetInfo.addEventListener((state) => {
        this.updateNetworkStatus(state);
      });

      loggingService.info('Network monitoring initialized');
    } catch (error) {
      loggingService.error('Failed to initialize network monitoring', { 
        error: error.message 
      });
    }
  }

  private updateNetworkStatus(state: any): void {
    const wasOnline = this.isOnline;
    
    this.networkStatus = {
      isConnected: state.isConnected ?? false,
      type: state.type ?? 'unknown',
      isInternetReachable: state.isInternetReachable ?? false,
      details: state.details,
    };

    this.isOnline = this.networkStatus.isConnected && this.networkStatus.isInternetReachable;

    loggingService.info('Network status updated', {
      isOnline: this.isOnline,
      type: this.networkStatus.type,
      isConnected: this.networkStatus.isConnected,
      isInternetReachable: this.networkStatus.isInternetReachable,
    });

    analyticsService.trackEvent('network_status_changed', {
      was_online: wasOnline,
      is_online: this.isOnline,
      connection_type: this.networkStatus.type,
    });

    // Notify listeners
    this.listeners.forEach(listener => {
      try {
        listener(this.networkStatus);
      } catch (error) {
        loggingService.error('Network status listener error', { error: error.message });
      }
    });

    // Process queue when coming back online
    if (!wasOnline && this.isOnline && this.requestQueue.length > 0) {
      loggingService.info('Back online, processing request queue', { 
        queueSize: this.requestQueue.length 
      });
      this.processRequestQueue();
    }
  }

  // Public API
  addNetworkListener(listener: (status: NetworkStatus) => void): () => void {
    this.listeners.push(listener);
    
    // Return unsubscribe function
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        this.listeners.splice(index, 1);
      }
    };
  }

  getNetworkStatus(): NetworkStatus {
    return { ...this.networkStatus };
  }

  isOnlineNow(): boolean {
    return this.isOnline;
  }

  async request<T = any>(
    url: string,
    options: RequestInit = {},
    config: RequestConfig = {}
  ): Promise<NetworkResponse<T>> {
    const requestId = this.generateRequestId();
    const startTime = Date.now();

    try {
      loggingService.debug('Network request started', { 
        requestId,
        url,
        method: options.method || 'GET',
      });

      // If offline, queue the request
      if (!this.isOnline) {
        return await this.queueRequest(url, options, config);
      }

      // Apply timeout
      const controller = new AbortController();
      const timeoutId = setTimeout(() => {
        controller.abort();
      }, config.timeout || 30000);

      const requestOptions: RequestInit = {
        ...options,
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          ...config.headers,
          ...options.headers,
        },
      };

      let response: Response;
      let attempt = 0;
      const maxRetries = config.retries || this.defaultRetryConfig.maxRetries;

      while (attempt <= maxRetries) {
        try {
          response = await fetch(url, requestOptions);
          clearTimeout(timeoutId);
          break;
        } catch (error) {
          attempt++;
          
          if (attempt > maxRetries) {
            throw error;
          }

          // Check if we should retry
          const shouldRetry = this.defaultRetryConfig.retryCondition(error, attempt);
          if (!shouldRetry) {
            throw error;
          }

          // Calculate delay
          const delay = Math.min(
            this.defaultRetryConfig.baseDelay * Math.pow(this.defaultRetryConfig.backoffFactor, attempt - 1),
            this.defaultRetryConfig.maxDelay
          );

          loggingService.warn('Request failed, retrying', {
            requestId,
            url,
            attempt,
            delay,
            error: error.message,
          });

          analyticsService.trackEvent('network_request_retry', {
            url,
            attempt,
            delay,
            error_type: error.name,
          });

          // Wait before retry
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }

      const duration = Date.now() - startTime;

      // Check if response is ok
      if (!response!.ok) {
        const error = new Error(`HTTP ${response!.status}: ${response!.statusText}`);
        (error as any).status = response!.status;
        (error as any).statusText = response!.statusText;
        throw error;
      }

      // Parse response
      let data: T;
      const contentType = response!.headers.get('content-type');
      
      if (contentType && contentType.includes('application/json')) {
        data = await response!.json();
      } else {
        data = (await response!.text()) as any;
      }

      const networkResponse: NetworkResponse<T> = {
        data,
        status: response!.status,
        statusText: response!.statusText,
        headers: this.headersToObject(response!.headers),
      };

      loggingService.debug('Network request completed', {
        requestId,
        url,
        status: response!.status,
        duration,
        attempts: attempt,
      });

      analyticsService.trackEvent('network_request_success', {
        url,
        status: response!.status,
        duration,
        attempts: attempt,
      });

      return networkResponse;

    } catch (error) {
      const duration = Date.now() - startTime;
      
      loggingService.error('Network request failed', {
        requestId,
        url,
        error: error.message,
        duration,
      });

      analyticsService.trackEvent('network_request_error', {
        url,
        error_type: error.name,
        error_message: error.message,
        duration,
      });

      throw error;
    }
  }

  private async queueRequest<T = any>(
    url: string,
    options: RequestInit,
    config: RequestConfig
  ): Promise<NetworkResponse<T>> {
    return new Promise((resolve, reject) => {
      const queuedRequest: QueuedRequest = {
        id: this.generateRequestId(),
        url,
        options,
        config,
        resolve: resolve as any,
        reject,
        createdAt: Date.now(),
        retries: 0,
      };

      this.requestQueue.push(queuedRequest);
      
      loggingService.info('Request queued for offline processing', {
        requestId: queuedRequest.id,
        url,
        queueSize: this.requestQueue.length,
      });

      analyticsService.trackEvent('network_request_queued', {
        url,
        queue_size: this.requestQueue.length,
      });
    });
  }

  private async processRequestQueue(): Promise<void> {
    if (this.isProcessingQueue || this.requestQueue.length === 0) {
      return;
    }

    this.isProcessingQueue = true;
    loggingService.info('Processing request queue', { queueSize: this.requestQueue.length });

    const requestsToProcess = [...this.requestQueue];
    this.requestQueue = [];

    for (const queuedRequest of requestsToProcess) {
      try {
        // Check if request is too old (optional)
        const age = Date.now() - queuedRequest.createdAt;
        const maxAge = 5 * 60 * 1000; // 5 minutes
        
        if (age > maxAge) {
          queuedRequest.reject(new Error('Request expired in queue'));
          continue;
        }

        const response = await this.request(
          queuedRequest.url,
          queuedRequest.options,
          queuedRequest.config
        );
        
        queuedRequest.resolve(response);
        
        loggingService.debug('Queued request processed successfully', {
          requestId: queuedRequest.id,
          url: queuedRequest.url,
        });

      } catch (error) {
        queuedRequest.retries++;
        
        if (queuedRequest.retries < (queuedRequest.config.retries || this.defaultRetryConfig.maxRetries)) {
          // Requeue for retry
          this.requestQueue.push(queuedRequest);
          loggingService.warn('Queued request failed, will retry', {
            requestId: queuedRequest.id,
            url: queuedRequest.url,
            retries: queuedRequest.retries,
          });
        } else {
          queuedRequest.reject(error);
          loggingService.error('Queued request failed permanently', {
            requestId: queuedRequest.id,
            url: queuedRequest.url,
            error: error.message,
          });
        }
      }
    }

    this.isProcessingQueue = false;
    
    // Process any remaining requests
    if (this.requestQueue.length > 0) {
      setTimeout(() => this.processRequestQueue(), 1000);
    }
  }

  // Helper methods
  private generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private headersToObject(headers: Headers): Record<string, string> {
    const result: Record<string, string> = {};
    headers.forEach((value, key) => {
      result[key] = value;
    });
    return result;
  }

  // Convenience methods
  async get<T = any>(url: string, config?: RequestConfig): Promise<NetworkResponse<T>> {
    return this.request<T>(url, { method: 'GET' }, config);
  }

  async post<T = any>(
    url: string,
    data?: any,
    config?: RequestConfig
  ): Promise<NetworkResponse<T>> {
    return this.request<T>(
      url,
      {
        method: 'POST',
        body: data ? JSON.stringify(data) : undefined,
      },
      config
    );
  }

  async put<T = any>(
    url: string,
    data?: any,
    config?: RequestConfig
  ): Promise<NetworkResponse<T>> {
    return this.request<T>(
      url,
      {
        method: 'PUT',
        body: data ? JSON.stringify(data) : undefined,
      },
      config
    );
  }

  async delete<T = any>(url: string, config?: RequestConfig): Promise<NetworkResponse<T>> {
    return this.request<T>(url, { method: 'DELETE' }, config);
  }

  // Queue management
  getQueueSize(): number {
    return this.requestQueue.length;
  }

  clearQueue(): void {
    const rejectedCount = this.requestQueue.length;
    this.requestQueue.forEach(request => {
      request.reject(new Error('Request queue cleared'));
    });
    this.requestQueue = [];
    
    loggingService.info('Request queue cleared', { rejectedCount });
  }

  getQueuedRequests(): Array<{
    id: string;
    url: string;
    method: string;
    createdAt: number;
    retries: number;
  }> {
    return this.requestQueue.map(request => ({
      id: request.id,
      url: request.url,
      method: request.options.method || 'GET',
      createdAt: request.createdAt,
      retries: request.retries,
    }));
  }

  // Configuration
  updateRetryConfig(config: Partial<RetryConfig>): void {
    this.defaultRetryConfig = { ...this.defaultRetryConfig, ...config };
    loggingService.info('Retry configuration updated', config);
  }

  getRetryConfig(): RetryConfig {
    return { ...this.defaultRetryConfig };
  }

  // Health check
  async healthCheck(url: string = 'https://www.google.com'): Promise<boolean> {
    try {
      const response = await this.request(url, 
        { method: 'HEAD' }, 
        { timeout: 5000, retries: 0 }
      );
      return response.status >= 200 && response.status < 300;
    } catch (error) {
      loggingService.warn('Health check failed', { url, error: error.message });
      return false;
    }
  }

  // Cleanup
  cleanup(): void {
    this.clearQueue();
    this.listeners = [];
    loggingService.info('Network service cleaned up');
  }
}

export const networkService = new NetworkService();