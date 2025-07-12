export type RequestType = 'complaint' | 'service' | 'inspection' | 'repair' | 'maintenance' | 'modification' | 'inquiry';
export type RequestPriority = 'low' | 'normal' | 'high' | 'urgent';
export type RequestStatus = 'received' | 'acknowledged' | 'investigating' | 'diagnosed' | 'quoted' | 'approved' | 'in_progress' | 'completed' | 'cancelled';

export interface CustomerRequest {
  id: string;
  
  // Classification
  type: RequestType;
  priority: RequestPriority;
  status: RequestStatus;
  
  // Description
  title: string;
  description: string;
  symptoms?: string[];
  customerConcerns: string[];
  
  // Customer Information
  customerId: string;
  carId: string;
  sessionId: string;
  
  // Request Details
  requestedBy: string; // Customer name
  requestedAt: Date;
  receivedBy: string; // User ID who received the request
  
  // Investigation
  investigatedBy?: string; // User ID who investigated
  investigatedAt?: Date;
  investigationNotes?: string;
  
  // Diagnosis
  diagnosedBy?: string; // User ID who diagnosed
  diagnosedAt?: Date;
  diagnosisNotes?: string;
  relatedFindingIds: string[]; // Related findings
  
  // Solution
  recommendedSolution?: string;
  alternativeSolutions?: string[];
  estimatedCost?: number;
  estimatedTime?: number; // in hours
  
  // Quote and Approval
  quotedAt?: Date;
  quotedBy?: string; // User ID who created quote
  customerApproved?: boolean;
  customerApprovedAt?: Date;
  customerSignature?: string; // Base64 or URL to signature
  
  // Work Assignment
  assignedTo?: string; // User ID assigned to work on this
  assignedAt?: Date;
  
  // Completion
  completedAt?: Date;
  completedBy?: string; // User ID who completed
  completionNotes?: string;
  customerSatisfied?: boolean;
  customerFeedback?: string;
  customerRating?: number; // 1-5 stars
  
  // Communication
  customerNotified: boolean;
  lastCustomerUpdate?: Date;
  communicationLog: string[]; // Array of communication entries
  
  // Additional Information
  warrantyCovered?: boolean;
  warrantyClaimNumber?: string;
  internalNotes?: string;
  tags?: string[];
  
  // Relations
  relatedJobOrderId?: string;
  relatedTaskIds: string[]; // Related job order tasks
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}

export interface CreateRequestData {
  customerId: string;
  carId: string;
  sessionId: string;
  type: RequestType;
  priority: RequestPriority;
  title: string;
  description: string;
  symptoms?: string[];
  customerConcerns: string[];
  requestedBy: string;
  receivedBy: string;
  warrantyCovered?: boolean;
  warrantyClaimNumber?: string;
  internalNotes?: string;
  tags?: string[];
}

export interface UpdateRequestData extends Partial<CreateRequestData> {
  id: string;
  status?: RequestStatus;
  investigatedBy?: string;
  investigationNotes?: string;
  diagnosedBy?: string;
  diagnosisNotes?: string;
  relatedFindingIds?: string[];
  recommendedSolution?: string;
  alternativeSolutions?: string[];
  estimatedCost?: number;
  estimatedTime?: number;
  quotedBy?: string;
  customerApproved?: boolean;
  customerSignature?: string;
  assignedTo?: string;
  completedBy?: string;
  completionNotes?: string;
  customerSatisfied?: boolean;
  customerFeedback?: string;
  customerRating?: number;
  relatedJobOrderId?: string;
  relatedTaskIds?: string[];
}

export interface RequestSummary {
  id: string;
  title: string;
  type: RequestType;
  priority: RequestPriority;
  status: RequestStatus;
  customerName: string;
  carInfo: string;
  requestedAt: Date;
  estimatedCost?: number;
  assignedTo?: string;
  customerApproved?: boolean;
}

export interface CommunicationEntry {
  id: string;
  requestId: string;
  timestamp: Date;
  method: 'phone' | 'email' | 'whatsapp' | 'sms' | 'in_person';
  direction: 'inbound' | 'outbound';
  summary: string;
  details?: string;
  handledBy: string; // User ID
  followUpRequired: boolean;
  followUpDate?: Date;
}

// Request workflow templates
export const REQUEST_WORKFLOWS: Record<RequestType, RequestStatus[]> = {
  complaint: [
    'received',
    'acknowledged',
    'investigating',
    'diagnosed',
    'quoted',
    'approved',
    'in_progress',
    'completed'
  ],
  service: [
    'received',
    'acknowledged',
    'quoted',
    'approved',
    'in_progress',
    'completed'
  ],
  inspection: [
    'received',
    'acknowledged',
    'in_progress',
    'completed'
  ],
  repair: [
    'received',
    'acknowledged',
    'investigating',
    'diagnosed',
    'quoted',
    'approved',
    'in_progress',
    'completed'
  ],
  maintenance: [
    'received',
    'acknowledged',
    'quoted',
    'approved',
    'in_progress',
    'completed'
  ],
  modification: [
    'received',
    'acknowledged',
    'investigating',
    'quoted',
    'approved',
    'in_progress',
    'completed'
  ],
  inquiry: [
    'received',
    'acknowledged',
    'completed'
  ]
};