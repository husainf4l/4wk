export type TestDriveStatus = 'not_started' | 'in_progress' | 'completed';
export type DrivingCondition = 'excellent' | 'good' | 'fair' | 'poor';

export interface TestDriveCheckpoint {
  id: string;
  name: string;
  description: string;
  status: DrivingCondition;
  notes?: string;
  photos?: string[]; // URLs to photos in S3
  videos?: string[]; // URLs to videos in S3
  issuesFound?: string[];
}

export interface TestDrive {
  id: string;
  sessionId: string;
  
  // Basic Information
  testDriveDate: Date;
  testedBy: string; // User ID of technician
  driverName?: string; // If different from technician
  
  // Pre-Drive Information
  startingMileage: number;
  endingMileage: number;
  fuelLevel: string; // e.g., "3/4 tank", "Half tank"
  
  // Route and Duration
  routeTaken?: string;
  durationMinutes: number;
  weatherConditions?: string;
  roadConditions?: string;
  
  // Performance Checkpoints
  checkpoints: TestDriveCheckpoint[];
  
  // Overall Assessment
  overallPerformance: DrivingCondition;
  drivabilityRating: number; // 1-10 scale
  
  // Specific Areas
  enginePerformance: DrivingCondition;
  transmissionPerformance: DrivingCondition;
  brakingPerformance: DrivingCondition;
  steeringPerformance: DrivingCondition;
  suspensionPerformance: DrivingCondition;
  
  // Issues and Observations
  issuesIdentified: string[];
  recommendations: string[];
  requiresFollowUpDrive: boolean;
  
  // Media
  beforeDrivePhotos?: string[];
  duringDriveVideos?: string[];
  afterDrivePhotos?: string[];
  
  // Notes
  generalNotes?: string;
  customerFeedback?: string; // If customer was present
  
  // Status
  isComplete: boolean;
  approvedBy?: string; // User ID of supervisor who approved
  approvedAt?: Date;
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}

export interface CreateTestDriveData {
  sessionId: string;
  testedBy: string;
  driverName?: string;
  startingMileage: number;
  endingMileage: number;
  fuelLevel: string;
  routeTaken?: string;
  durationMinutes: number;
  weatherConditions?: string;
  roadConditions?: string;
  checkpoints: Omit<TestDriveCheckpoint, 'id'>[];
  overallPerformance: DrivingCondition;
  drivabilityRating: number;
  enginePerformance: DrivingCondition;
  transmissionPerformance: DrivingCondition;
  brakingPerformance: DrivingCondition;
  steeringPerformance: DrivingCondition;
  suspensionPerformance: DrivingCondition;
  issuesIdentified: string[];
  recommendations: string[];
  requiresFollowUpDrive: boolean;
  generalNotes?: string;
  customerFeedback?: string;
}

export interface UpdateTestDriveData extends Partial<CreateTestDriveData> {
  id: string;
  isComplete?: boolean;
  approvedBy?: string;
}

export interface TestDriveSummary {
  id: string;
  sessionId: string;
  testDriveDate: Date;
  overallPerformance: DrivingCondition;
  drivabilityRating: number;
  issuesCount: number;
  testedBy: string;
  isComplete: boolean;
  requiresFollowUpDrive: boolean;
}

// Predefined test drive checkpoints
export const DEFAULT_CHECKPOINTS: Omit<TestDriveCheckpoint, 'id' | 'status' | 'notes' | 'photos' | 'videos' | 'issuesFound'>[] = [
  {
    name: 'Engine Start',
    description: 'Engine starting smoothness and idle quality',
  },
  {
    name: 'Initial Movement',
    description: 'Car response when moving from stationary position',
  },
  {
    name: 'Low Speed Driving',
    description: 'Performance at city driving speeds (0-50 km/h)',
  },
  {
    name: 'Highway Speed',
    description: 'Performance at highway speeds (50+ km/h)',
  },
  {
    name: 'Acceleration',
    description: 'Engine and transmission response during acceleration',
  },
  {
    name: 'Braking Test',
    description: 'Brake performance and stopping distance',
  },
  {
    name: 'Steering Response',
    description: 'Steering wheel responsiveness and alignment',
  },
  {
    name: 'Gear Changes',
    description: 'Transmission shifting smoothness',
  },
  {
    name: 'Parking Maneuvers',
    description: 'Low speed maneuvering and parking assistance',
  },
  {
    name: 'Engine Off',
    description: 'Engine shutdown behavior and any unusual sounds',
  },
];