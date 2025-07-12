export interface Customer {
  id: string;
  name: string;
  email?: string;
  phone: string;
  address?: string;
  nationalId?: string;
  emiratesId?: string;
  dateOfBirth?: Date;
  
  // Company information
  isCompany: boolean;
  companyName?: string;
  
  // Additional information
  notes?: string;
  preferredContactMethod?: 'phone' | 'email' | 'whatsapp';
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy: string; // User ID who created this customer
  isActive: boolean;
  
  // Relations
  carIds: string[]; // Array of car IDs belonging to this customer
  sessionIds: string[]; // Array of session IDs for this customer
}

export interface CreateCustomerData {
  name: string;
  phone: string;
  email?: string;
  address?: string;
  nationalId?: string;
  emiratesId?: string;
  dateOfBirth?: Date;
  isCompany: boolean;
  companyName?: string;
  notes?: string;
  preferredContactMethod?: 'phone' | 'email' | 'whatsapp';
}

export interface UpdateCustomerData extends Partial<CreateCustomerData> {
  id: string;
}