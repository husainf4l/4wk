// Main type exports for 4WK Garage Management System

// Core entities
export * from './Customer';
export * from './Car';
export * from './User';

// Session workflow
export * from './Session';
export * from './Inspection';
export * from './TestDrive';
export * from './Report';

// Work management
export * from './JobOrder';
export * from './Finding';
export * from './Request';

// Common types used across the application
export interface BaseEntity {
  id: string;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
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

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
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

// Media upload types
export interface MediaUpload {
  uri: string;
  type: 'image' | 'video';
  name: string;
  size?: number;
  mimeType?: string;
}

export interface UploadProgress {
  loaded: number;
  total: number;
  progress: number;
}

// Notification types
export interface Notification {
  id: string;
  userId: string;
  title: string;
  message: string;
  type: 'info' | 'success' | 'warning' | 'error';
  read: boolean;
  actionUrl?: string;
  createdAt: Date;
}

// Dashboard summary types
export interface DashboardStats {
  totalCustomers: number;
  totalCars: number;
  activeSessions: number;
  completedSessions: number;
  pendingReports: number;
  activeJobOrders: number;
  totalRevenue?: number;
  monthlyStats?: MonthlyStats;
}

export interface MonthlyStats {
  sessionsCompleted: number;
  reportsGenerated: number;
  jobOrdersCompleted: number;
  revenue?: number;
  customerSatisfaction?: number;
}

// Search and filtering
export interface SearchResult {
  type: 'customer' | 'car' | 'session' | 'report' | 'job_order';
  id: string;
  title: string;
  subtitle: string;
  status?: string;
  date?: Date;
}

// Settings and configuration
export interface AppSettings {
  garageInfo: {
    name: string;
    address: string;
    phone: string;
    email: string;
    logo?: string;
  };
  defaultSettings: {
    sessionTimeout: number;
    reportTemplate: string;
    defaultLanguage: 'en' | 'ar';
    currency: string;
    timezone: string;
  };
  integrations: {
    whatsappEnabled: boolean;
    emailEnabled: boolean;
    smsEnabled: boolean;
  };
}

// Error handling
export interface AppError {
  code: string;
  message: string;
  details?: string;
  timestamp: Date;
  userId?: string;
  context?: Record<string, any>;
}