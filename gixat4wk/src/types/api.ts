// API Response types for better error handling and type safety

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginationParams {
  page: number;
  limit: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  hasNext: boolean;
  hasPrev: boolean;
}

export interface FilterParams {
  search?: string;
  status?: string;
  dateFrom?: Date;
  dateTo?: Date;
  assignedTo?: string;
  customerId?: string;
  carId?: string;
  sessionId?: string;
}

// Service Response Types
export interface ServiceError {
  code: string;
  message: string;
  details?: any;
  timestamp: Date;
}

export interface ValidationError {
  field: string;
  message: string;
  value?: any;
}

export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
}

// Loading states
export type LoadingState = 'idle' | 'loading' | 'success' | 'error';

export interface AsyncState<T = any> {
  data: T | null;
  loading: LoadingState;
  error: string | null;
  lastFetched?: Date;
}

// Network request types
export interface RequestConfig {
  timeout?: number;
  retries?: number;
  retryDelay?: number;
  headers?: Record<string, string>;
}

export interface NetworkResponse<T = any> {
  data: T;
  status: number;
  statusText: string;
  headers: Record<string, string>;
}

// File upload types
export interface UploadProgress {
  loaded: number;
  total: number;
  progress: number;
}

export interface UploadResult {
  url: string;
  key: string;
  size: number;
}

export interface MediaFile {
  uri: string;
  name: string;
  type: 'image' | 'video';
  size?: number;
  mimeType?: string;
}

// Search and filtering
export interface SearchResult<T = any> {
  items: T[];
  total: number;
  query: string;
  facets?: Record<string, any>;
}

export interface SearchParams {
  query: string;
  filters?: Record<string, any>;
  sort?: {
    field: string;
    direction: 'asc' | 'desc';
  };
  pagination?: PaginationParams;
}

// Cache types
export interface CacheConfig {
  ttl?: number; // Time to live in milliseconds
  maxSize?: number;
  strategy?: 'lru' | 'fifo';
}

export interface CacheEntry<T = any> {
  data: T;
  timestamp: Date;
  ttl: number;
}

// Analytics and logging
export interface LogEntry {
  level: 'debug' | 'info' | 'warn' | 'error';
  message: string;
  timestamp: Date;
  context?: Record<string, any>;
  userId?: string;
  sessionId?: string;
}

export interface AnalyticsEvent {
  name: string;
  properties?: Record<string, any>;
  timestamp: Date;
  userId?: string;
  sessionId?: string;
}

// Notification types
export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, any>;
  sound?: string;
  badge?: number;
}

export interface PushNotificationConfig {
  topic?: string;
  priority?: 'high' | 'normal';
  ttl?: number;
  collapseKey?: string;
}

// Real-time updates
export interface RealtimeEvent<T = any> {
  type: 'create' | 'update' | 'delete';
  collection: string;
  documentId: string;
  data?: T;
  timestamp: Date;
}

export interface RealtimeSubscription {
  id: string;
  collection: string;
  query?: any;
  callback: (event: RealtimeEvent) => void;
  isActive: boolean;
}

// Export/Import types
export interface ExportConfig {
  format: 'csv' | 'xlsx' | 'json' | 'pdf';
  fields?: string[];
  filters?: FilterParams;
  includeMedia?: boolean;
}

export interface ImportConfig {
  format: 'csv' | 'xlsx' | 'json';
  mapping: Record<string, string>;
  validateOnly?: boolean;
  skipErrors?: boolean;
}

export interface ImportResult {
  success: boolean;
  processed: number;
  errors: Array<{
    row: number;
    message: string;
    data?: any;
  }>;
  warnings: Array<{
    row: number;
    message: string;
    data?: any;
  }>;
}

// Background job types
export interface JobConfig {
  name: string;
  schedule?: string; // Cron expression
  data?: any;
  retries?: number;
  timeout?: number;
}

export interface JobResult {
  success: boolean;
  output?: any;
  error?: string;
  duration: number;
  startedAt: Date;
  completedAt?: Date;
}

// Health check types
export interface HealthCheck {
  service: string;
  status: 'healthy' | 'unhealthy' | 'degraded';
  latency?: number;
  message?: string;
  timestamp: Date;
}

export interface SystemHealth {
  overall: 'healthy' | 'unhealthy' | 'degraded';
  services: HealthCheck[];
  version: string;
  uptime: number;
}