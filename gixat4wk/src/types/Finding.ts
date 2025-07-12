export type FindingType = 'visual' | 'performance' | 'safety' | 'maintenance' | 'electrical' | 'mechanical' | 'cosmetic';
export type FindingSeverity = 'informational' | 'minor' | 'moderate' | 'major' | 'critical';
export type FindingStatus = 'identified' | 'confirmed' | 'addressed' | 'resolved' | 'deferred';

export interface Finding {
  id: string;
  
  // Classification
  type: FindingType;
  severity: FindingSeverity;
  status: FindingStatus;
  
  // Description
  title: string;
  description: string;
  location: string; // Where on the vehicle
  category: string; // Engine, Brakes, etc.
  
  // Discovery Information
  discoveredBy: string; // User ID who found the issue
  discoveredAt: Date;
  discoveredDuring: 'inspection' | 'test_drive' | 'initial_check' | 'customer_complaint';
  
  // Evidence
  photos: string[]; // URLs to photos in S3
  videos: string[]; // URLs to videos in S3
  notes: string;
  
  // Technical Details
  symptoms: string[];
  possibleCauses: string[];
  recommendedAction: string;
  
  // Priority and Impact
  safetyImpact: boolean;
  drivabilityImpact: boolean;
  estimatedRepairCost?: number;
  estimatedRepairTime?: number; // in hours
  urgency: 'immediate' | 'soon' | 'next_service' | 'monitor';
  
  // Resolution
  resolvedAt?: Date;
  resolvedBy?: string; // User ID who resolved
  resolutionNotes?: string;
  verifiedBy?: string; // User ID who verified the fix
  verifiedAt?: Date;
  
  // Relations
  sessionId: string;
  inspectionId?: string;
  testDriveId?: string;
  relatedRequestIds: string[]; // Related customer requests
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}

export interface CreateFindingData {
  sessionId: string;
  inspectionId?: string;
  testDriveId?: string;
  type: FindingType;
  severity: FindingSeverity;
  title: string;
  description: string;
  location: string;
  category: string;
  discoveredBy: string;
  discoveredDuring: 'inspection' | 'test_drive' | 'initial_check' | 'customer_complaint';
  notes: string;
  symptoms: string[];
  possibleCauses: string[];
  recommendedAction: string;
  safetyImpact: boolean;
  drivabilityImpact: boolean;
  estimatedRepairCost?: number;
  estimatedRepairTime?: number;
  urgency: 'immediate' | 'soon' | 'next_service' | 'monitor';
  relatedRequestIds?: string[];
}

export interface UpdateFindingData extends Partial<CreateFindingData> {
  id: string;
  status?: FindingStatus;
  resolvedBy?: string;
  resolutionNotes?: string;
  verifiedBy?: string;
}

export interface FindingSummary {
  id: string;
  title: string;
  type: FindingType;
  severity: FindingSeverity;
  status: FindingStatus;
  location: string;
  urgency: 'immediate' | 'soon' | 'next_service' | 'monitor';
  discoveredAt: Date;
  safetyImpact: boolean;
  estimatedRepairCost?: number;
}