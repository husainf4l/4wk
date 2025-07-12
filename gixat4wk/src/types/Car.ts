export interface Car {
  id: string;
  customerId: string;
  
  // Basic Information
  make: string; // Toyota, BMW, Mercedes, etc.
  model: string; // Camry, X5, C-Class, etc.
  year: number;
  color: string;
  plateNumber: string;
  emirate?: string; // Dubai, Abu Dhabi, etc.
  
  // Technical Details
  vin?: string; // Vehicle Identification Number
  engineNumber?: string;
  chassisNumber?: string;
  fuelType?: 'petrol' | 'diesel' | 'hybrid' | 'electric';
  transmission?: 'manual' | 'automatic';
  engineCapacity?: string; // 2.0L, 3.5L, etc.
  
  // Current Status
  currentMileage?: number;
  lastServiceDate?: Date;
  nextServiceDue?: Date;
  insuranceExpiry?: Date;
  registrationExpiry?: Date;
  
  // Additional Information
  notes?: string;
  photos?: string[]; // URLs to car photos in S3
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy: string; // User ID who created this car
  isActive: boolean;
  
  // Relations
  sessionIds: string[]; // Array of session IDs for this car
}

export interface CreateCarData {
  customerId: string;
  make: string;
  model: string;
  year: number;
  color: string;
  plateNumber: string;
  emirate?: string;
  vin?: string;
  engineNumber?: string;
  chassisNumber?: string;
  fuelType?: 'petrol' | 'diesel' | 'hybrid' | 'electric';
  transmission?: 'manual' | 'automatic';
  engineCapacity?: string;
  currentMileage?: number;
  lastServiceDate?: Date;
  nextServiceDue?: Date;
  insuranceExpiry?: Date;
  registrationExpiry?: Date;
  notes?: string;
}

export interface UpdateCarData extends Partial<CreateCarData> {
  id: string;
}

export interface CarSummary {
  id: string;
  make: string;
  model: string;
  year: number;
  plateNumber: string;
  color: string;
  currentMileage?: number;
}