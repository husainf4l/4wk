export type JobOrderStatus = 'pending' | 'approved' | 'in_progress' | 'completed' | 'delivered' | 'cancelled';
export type TaskStatus = 'pending' | 'in_progress' | 'completed' | 'cancelled' | 'on_hold';
export type TaskPriority = 'low' | 'normal' | 'high' | 'critical';
export type TaskType = 'repair' | 'replacement' | 'maintenance' | 'inspection' | 'diagnostic';

export interface JobOrderTask {
  id: string;
  name: string;
  description: string;
  type: TaskType;
  priority: TaskPriority;
  status: TaskStatus;
  
  // Assignment
  assignedTo?: string; // User ID of assigned technician
  assignedAt?: Date;
  
  // Time Estimates
  estimatedHours: number;
  actualHours?: number;
  
  // Cost Estimates
  estimatedCost: number;
  actualCost?: number;
  laborCost?: number;
  partsCost?: number;
  
  // Parts and Materials
  partsRequired?: string[];
  partsOrdered?: boolean;
  partsReceived?: boolean;
  
  // Progress Tracking
  startedAt?: Date;
  completedAt?: Date;
  notes?: string;
  photos?: string[]; // Before/after photos
  
  // Quality Control
  qualityChecked?: boolean;
  qualityCheckedBy?: string;
  qualityNotes?: string;
  
  // Dependencies
  dependsOn?: string[]; // Array of task IDs that must be completed first
  blockedBy?: string[]; // Array of task IDs that are blocking this task
}

export interface JobOrder {
  id: string;
  sessionId: string;
  reportId: string;
  
  // Basic Information
  jobOrderNumber: string; // Auto-generated unique job order number
  status: JobOrderStatus;
  createdDate: Date;
  approvedDate?: Date;
  startDate?: Date;
  completedDate?: Date;
  deliveryDate?: Date;
  
  // Customer and Car Information
  customerId: string;
  carId: string;
  
  // Authorization
  createdBy: string; // User ID who created the job order
  approvedBy?: string; // User ID who approved the job order
  customerApproved: boolean;
  customerApprovedAt?: Date;
  customerSignature?: string; // Base64 or URL to signature image
  
  // Tasks
  tasks: JobOrderTask[];
  
  // Summary
  totalEstimatedHours: number;
  totalActualHours?: number;
  totalEstimatedCost: number;
  totalActualCost?: number;
  totalLaborCost?: number;
  totalPartsCost?: number;
  
  // Progress
  completedTasks: number;
  totalTasks: number;
  progressPercentage: number;
  
  // Priority and Classification
  overallPriority: TaskPriority;
  workType: 'warranty' | 'paid' | 'insurance' | 'goodwill';
  
  // Scheduling
  scheduledStartDate?: Date;
  estimatedCompletionDate?: Date;
  actualCompletionDate?: Date;
  
  // Communication
  customerNotified: boolean;
  lastCustomerUpdate?: Date;
  customerNotes?: string;
  internalNotes?: string;
  
  // Quality and Delivery
  qualityInspectionComplete: boolean;
  qualityInspectedBy?: string;
  readyForDelivery: boolean;
  deliveryNotes?: string;
  customerFeedback?: string;
  customerRating?: number; // 1-5 stars
  
  // Documentation
  photos?: string[]; // Progress photos
  documents?: string[]; // Additional documents
  invoiceGenerated?: boolean;
  invoiceNumber?: string;
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateJobOrderData {
  sessionId: string;
  reportId: string;
  customerId: string;
  carId: string;
  createdBy: string;
  tasks: Omit<JobOrderTask, 'id' | 'status' | 'startedAt' | 'completedAt' | 'actualHours' | 'actualCost'>[];
  overallPriority: TaskPriority;
  workType: 'warranty' | 'paid' | 'insurance' | 'goodwill';
  scheduledStartDate?: Date;
  estimatedCompletionDate?: Date;
  customerNotes?: string;
  internalNotes?: string;
}

export interface UpdateJobOrderData extends Partial<CreateJobOrderData> {
  id: string;
  status?: JobOrderStatus;
  approvedBy?: string;
  customerApproved?: boolean;
  customerSignature?: string;
  actualCompletionDate?: Date;
  deliveryDate?: Date;
  qualityInspectionComplete?: boolean;
  qualityInspectedBy?: string;
  readyForDelivery?: boolean;
  deliveryNotes?: string;
  customerFeedback?: string;
  customerRating?: number;
  invoiceGenerated?: boolean;
  invoiceNumber?: string;
}

export interface UpdateTaskData {
  taskId: string;
  jobOrderId: string;
  status?: TaskStatus;
  assignedTo?: string;
  actualHours?: number;
  actualCost?: number;
  laborCost?: number;
  partsCost?: number;
  partsOrdered?: boolean;
  partsReceived?: boolean;
  notes?: string;
  qualityChecked?: boolean;
  qualityCheckedBy?: string;
  qualityNotes?: string;
}

export interface JobOrderSummary {
  id: string;
  jobOrderNumber: string;
  status: JobOrderStatus;
  customerName: string;
  carInfo: string;
  createdDate: Date;
  estimatedCompletionDate?: Date;
  totalEstimatedCost: number;
  progressPercentage: number;
  overallPriority: TaskPriority;
  assignedTechnicians: string[];
}

export interface TaskSummary {
  id: string;
  name: string;
  type: TaskType;
  priority: TaskPriority;
  status: TaskStatus;
  assignedTo?: string;
  estimatedHours: number;
  estimatedCost: number;
  jobOrderNumber: string;
  customerName: string;
}