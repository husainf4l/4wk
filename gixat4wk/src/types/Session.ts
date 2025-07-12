export type SessionStatus = 'started' | 'inspection_complete' | 'test_drive_complete' | 'report_generated' | 'job_order_created' | 'completed';

export interface Session {
  id: string;
  customerId: string;
  carId: string;
  
  // Basic Session Info
  sessionNumber: string; // Auto-generated unique session number
  status: SessionStatus;
  startDate: Date;
  endDate?: Date;
  
  // Initial Information
  customerRequests: string[]; // Array of customer requests/complaints
  initialMileage: number;
  initialPhotos: string[]; // URLs to initial car photos in S3
  initialNotes?: string;
  
  // Session Progress
  hasInspection: boolean;
  hasTestDrive: boolean;
  hasReport: boolean;
  hasJobOrder: boolean;
  
  // Staff Assignment
  assignedTechnician?: string; // User ID of assigned technician
  assignedServiceAdvisor?: string; // User ID of assigned service advisor
  
  // Timing
  estimatedCompletionTime?: number; // in hours
  actualCompletionTime?: number; // in hours
  
  // Communication
  reportSharedAt?: Date;
  reportSharedVia?: 'whatsapp' | 'email' | 'sms';
  customerNotified: boolean;
  
  // Additional Information
  priority?: 'low' | 'normal' | 'high' | 'urgent';
  tags?: string[]; // For categorization
  internalNotes?: string; // Internal staff notes
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy: string; // User ID who created this session
  
  // Relations
  inspectionId?: string;
  testDriveId?: string;
  reportId?: string;
  jobOrderId?: string;
}

export interface CreateSessionData {
  customerId: string;
  carId: string;
  customerRequests: string[];
  initialMileage: number;
  initialNotes?: string;
  assignedTechnician?: string;
  assignedServiceAdvisor?: string;
  estimatedCompletionTime?: number;
  priority?: 'low' | 'normal' | 'high' | 'urgent';
  tags?: string[];
}

export interface UpdateSessionData extends Partial<CreateSessionData> {
  id: string;
  status?: SessionStatus;
  endDate?: Date;
  actualCompletionTime?: number;
  reportSharedAt?: Date;
  reportSharedVia?: 'whatsapp' | 'email' | 'sms';
  customerNotified?: boolean;
  internalNotes?: string;
}

export interface SessionSummary {
  id: string;
  sessionNumber: string;
  status: SessionStatus;
  customerName: string;
  carInfo: string; // e.g., "Toyota Camry 2020"
  startDate: Date;
  priority?: 'low' | 'normal' | 'high' | 'urgent';
  assignedTechnician?: string;
}