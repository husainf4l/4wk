export type InspectionItemStatus = 'good' | 'fair' | 'poor' | 'needs_attention' | 'not_checked';
export type InspectionCategory = 'engine' | 'transmission' | 'brakes' | 'suspension' | 'electrical' | 'ac_system' | 'exterior' | 'interior' | 'tires' | 'fluids' | 'other';

export interface InspectionItem {
  id: string;
  category: InspectionCategory;
  name: string;
  status: InspectionItemStatus;
  notes?: string;
  photos?: string[]; // URLs to photos in S3
  videos?: string[]; // URLs to videos in S3
  recommendedAction?: string;
  priority?: 'low' | 'medium' | 'high' | 'critical';
}

export interface Inspection {
  id: string;
  sessionId: string;
  
  // Basic Information
  inspectionDate: Date;
  inspectedBy: string; // User ID of technician
  overallCondition: 'excellent' | 'good' | 'fair' | 'poor';
  
  // Inspection Items
  items: InspectionItem[];
  
  // Summary
  totalIssuesFound: number;
  criticalIssues: number;
  highPriorityIssues: number;
  mediumPriorityIssues: number;
  lowPriorityIssues: number;
  
  // General Information
  generalNotes?: string;
  recommendations?: string;
  estimatedRepairTime?: number; // in hours
  estimatedRepairCost?: number; // estimated cost
  
  // Media
  overviewPhotos?: string[]; // General overview photos
  overviewVideos?: string[]; // General overview videos
  
  // Status
  isComplete: boolean;
  approvedBy?: string; // User ID of supervisor who approved
  approvedAt?: Date;
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}

export interface CreateInspectionData {
  sessionId: string;
  inspectedBy: string;
  overallCondition: 'excellent' | 'good' | 'fair' | 'poor';
  items: Omit<InspectionItem, 'id'>[];
  generalNotes?: string;
  recommendations?: string;
  estimatedRepairTime?: number;
  estimatedRepairCost?: number;
}

export interface UpdateInspectionData extends Partial<CreateInspectionData> {
  id: string;
  isComplete?: boolean;
  approvedBy?: string;
}

export interface InspectionSummary {
  id: string;
  sessionId: string;
  inspectionDate: Date;
  overallCondition: 'excellent' | 'good' | 'fair' | 'poor';
  totalIssuesFound: number;
  criticalIssues: number;
  inspectedBy: string;
  isComplete: boolean;
}

// Predefined inspection categories and items
export const INSPECTION_CATEGORIES: Record<InspectionCategory, string[]> = {
  engine: [
    'Engine oil level and condition',
    'Coolant level and condition',
    'Air filter condition',
    'Spark plugs condition',
    'Engine performance',
    'Engine noises',
    'Oil leaks',
    'Coolant leaks',
  ],
  transmission: [
    'Transmission fluid level',
    'Transmission performance',
    'Gear shifting',
    'Clutch operation',
    'Transmission leaks',
  ],
  brakes: [
    'Brake pads condition',
    'Brake discs condition',
    'Brake fluid level',
    'Brake performance',
    'Handbrake operation',
    'Brake warning lights',
  ],
  suspension: [
    'Shock absorbers',
    'Springs condition',
    'Steering components',
    'Wheel alignment',
    'Suspension noises',
  ],
  electrical: [
    'Battery condition',
    'Headlights',
    'Taillights',
    'Indicators',
    'Dashboard lights',
    'Electrical systems',
  ],
  ac_system: [
    'AC cooling performance',
    'AC blower operation',
    'AC refrigerant level',
    'AC filters',
    'Heating system',
  ],
  exterior: [
    'Body condition',
    'Paint condition',
    'Windows condition',
    'Mirrors condition',
    'Bumpers condition',
  ],
  interior: [
    'Seats condition',
    'Dashboard condition',
    'Interior lights',
    'Seat belts',
    'Interior cleanliness',
  ],
  tires: [
    'Tire tread depth',
    'Tire pressure',
    'Tire condition',
    'Wheel condition',
    'Spare tire condition',
  ],
  fluids: [
    'Engine oil',
    'Brake fluid',
    'Power steering fluid',
    'Windshield washer fluid',
    'Transmission fluid',
  ],
  other: [
    'Documentation',
    'Keys and remotes',
    'Personal items',
    'Special equipment',
  ],
};