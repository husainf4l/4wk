export type UserRole = 'admin' | 'manager' | 'service_advisor' | 'technician' | 'inspector' | 'cashier' | 'viewer';
export type UserStatus = 'active' | 'inactive' | 'suspended';

export interface UserPermissions {
  // Customer Management
  canCreateCustomers: boolean;
  canEditCustomers: boolean;
  canDeleteCustomers: boolean;
  canViewCustomers: boolean;
  
  // Car Management
  canCreateCars: boolean;
  canEditCars: boolean;
  canDeleteCars: boolean;
  canViewCars: boolean;
  
  // Session Management
  canCreateSessions: boolean;
  canEditSessions: boolean;
  canDeleteSessions: boolean;
  canViewSessions: boolean;
  canAssignSessions: boolean;
  
  // Inspection
  canCreateInspections: boolean;
  canEditInspections: boolean;
  canApproveInspections: boolean;
  canViewInspections: boolean;
  
  // Test Drive
  canCreateTestDrives: boolean;
  canEditTestDrives: boolean;
  canApproveTestDrives: boolean;
  canViewTestDrives: boolean;
  
  // Reports
  canGenerateReports: boolean;
  canEditReports: boolean;
  canShareReports: boolean;
  canViewReports: boolean;
  
  // Job Orders
  canCreateJobOrders: boolean;
  canEditJobOrders: boolean;
  canApproveJobOrders: boolean;
  canAssignTasks: boolean;
  canUpdateTaskStatus: boolean;
  canViewJobOrders: boolean;
  
  // User Management
  canCreateUsers: boolean;
  canEditUsers: boolean;
  canDeleteUsers: boolean;
  canViewUsers: boolean;
  canAssignRoles: boolean;
  
  // Financial
  canViewCosts: boolean;
  canEditCosts: boolean;
  canGenerateInvoices: boolean;
  
  // Analytics and Reports
  canViewAnalytics: boolean;
  canExportData: boolean;
  
  // System Settings
  canEditSettings: boolean;
  canManageSystem: boolean;
}

export interface User {
  id: string;
  
  // Personal Information
  firstName: string;
  lastName: string;
  fullName: string; // Computed: firstName + lastName
  email: string;
  phone?: string;
  
  // Employment Information
  employeeId?: string;
  role: UserRole;
  department?: string;
  position?: string;
  
  // Authentication
  isEmailVerified: boolean;
  lastLoginAt?: Date;
  lastActiveAt?: Date;
  
  // Status and Permissions
  status: UserStatus;
  permissions: UserPermissions;
  
  // Profile
  profilePhoto?: string; // URL to profile photo
  bio?: string;
  skills?: string[];
  certifications?: string[];
  
  // Work Information
  hourlyRate?: number;
  specializations?: string[];
  languages?: string[]; // Spoken languages
  
  // Preferences
  notifications: {
    email: boolean;
    push: boolean;
    sms: boolean;
  };
  theme?: 'light' | 'dark' | 'auto';
  language: 'en' | 'ar';
  timezone?: string;
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy?: string; // User ID who created this user
  lastModifiedBy?: string;
}

export interface CreateUserData {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  employeeId?: string;
  role: UserRole;
  department?: string;
  position?: string;
  hourlyRate?: number;
  specializations?: string[];
  languages?: string[];
  temporaryPassword: string;
}

export interface UpdateUserData extends Partial<CreateUserData> {
  id: string;
  status?: UserStatus;
  permissions?: Partial<UserPermissions>;
  bio?: string;
  skills?: string[];
  certifications?: string[];
  notifications?: {
    email: boolean;
    push: boolean;
    sms: boolean;
  };
  theme?: 'light' | 'dark' | 'auto';
  language?: 'en' | 'ar';
  timezone?: string;
}

export interface UserSummary {
  id: string;
  fullName: string;
  email: string;
  role: UserRole;
  status: UserStatus;
  department?: string;
  lastActiveAt?: Date;
  profilePhoto?: string;
}

// Role-based permission templates
export const ROLE_PERMISSIONS: Record<UserRole, UserPermissions> = {
  admin: {
    // Full permissions for admin
    canCreateCustomers: true,
    canEditCustomers: true,
    canDeleteCustomers: true,
    canViewCustomers: true,
    canCreateCars: true,
    canEditCars: true,
    canDeleteCars: true,
    canViewCars: true,
    canCreateSessions: true,
    canEditSessions: true,
    canDeleteSessions: true,
    canViewSessions: true,
    canAssignSessions: true,
    canCreateInspections: true,
    canEditInspections: true,
    canApproveInspections: true,
    canViewInspections: true,
    canCreateTestDrives: true,
    canEditTestDrives: true,
    canApproveTestDrives: true,
    canViewTestDrives: true,
    canGenerateReports: true,
    canEditReports: true,
    canShareReports: true,
    canViewReports: true,
    canCreateJobOrders: true,
    canEditJobOrders: true,
    canApproveJobOrders: true,
    canAssignTasks: true,
    canUpdateTaskStatus: true,
    canViewJobOrders: true,
    canCreateUsers: true,
    canEditUsers: true,
    canDeleteUsers: true,
    canViewUsers: true,
    canAssignRoles: true,
    canViewCosts: true,
    canEditCosts: true,
    canGenerateInvoices: true,
    canViewAnalytics: true,
    canExportData: true,
    canEditSettings: true,
    canManageSystem: true,
  },
  
  manager: {
    // Management permissions
    canCreateCustomers: true,
    canEditCustomers: true,
    canDeleteCustomers: false,
    canViewCustomers: true,
    canCreateCars: true,
    canEditCars: true,
    canDeleteCars: false,
    canViewCars: true,
    canCreateSessions: true,
    canEditSessions: true,
    canDeleteSessions: false,
    canViewSessions: true,
    canAssignSessions: true,
    canCreateInspections: true,
    canEditInspections: true,
    canApproveInspections: true,
    canViewInspections: true,
    canCreateTestDrives: true,
    canEditTestDrives: true,
    canApproveTestDrives: true,
    canViewTestDrives: true,
    canGenerateReports: true,
    canEditReports: true,
    canShareReports: true,
    canViewReports: true,
    canCreateJobOrders: true,
    canEditJobOrders: true,
    canApproveJobOrders: true,
    canAssignTasks: true,
    canUpdateTaskStatus: true,
    canViewJobOrders: true,
    canCreateUsers: false,
    canEditUsers: false,
    canDeleteUsers: false,
    canViewUsers: true,
    canAssignRoles: false,
    canViewCosts: true,
    canEditCosts: true,
    canGenerateInvoices: true,
    canViewAnalytics: true,
    canExportData: true,
    canEditSettings: false,
    canManageSystem: false,
  },
  
  service_advisor: {
    // Service advisor permissions
    canCreateCustomers: true,
    canEditCustomers: true,
    canDeleteCustomers: false,
    canViewCustomers: true,
    canCreateCars: true,
    canEditCars: true,
    canDeleteCars: false,
    canViewCars: true,
    canCreateSessions: true,
    canEditSessions: true,
    canDeleteSessions: false,
    canViewSessions: true,
    canAssignSessions: true,
    canCreateInspections: false,
    canEditInspections: false,
    canApproveInspections: false,
    canViewInspections: true,
    canCreateTestDrives: false,
    canEditTestDrives: false,
    canApproveTestDrives: false,
    canViewTestDrives: true,
    canGenerateReports: true,
    canEditReports: true,
    canShareReports: true,
    canViewReports: true,
    canCreateJobOrders: true,
    canEditJobOrders: true,
    canApproveJobOrders: false,
    canAssignTasks: true,
    canUpdateTaskStatus: false,
    canViewJobOrders: true,
    canCreateUsers: false,
    canEditUsers: false,
    canDeleteUsers: false,
    canViewUsers: true,
    canAssignRoles: false,
    canViewCosts: true,
    canEditCosts: false,
    canGenerateInvoices: false,
    canViewAnalytics: false,
    canExportData: false,
    canEditSettings: false,
    canManageSystem: false,
  },
  
  technician: {
    // Technician permissions
    canCreateCustomers: false,
    canEditCustomers: false,
    canDeleteCustomers: false,
    canViewCustomers: true,
    canCreateCars: false,
    canEditCars: false,
    canDeleteCars: false,
    canViewCars: true,
    canCreateSessions: false,
    canEditSessions: false,
    canDeleteSessions: false,
    canViewSessions: true,
    canAssignSessions: false,
    canCreateInspections: true,
    canEditInspections: true,
    canApproveInspections: false,
    canViewInspections: true,
    canCreateTestDrives: true,
    canEditTestDrives: true,
    canApproveTestDrives: false,
    canViewTestDrives: true,
    canGenerateReports: false,
    canEditReports: false,
    canShareReports: false,
    canViewReports: true,
    canCreateJobOrders: false,
    canEditJobOrders: false,
    canApproveJobOrders: false,
    canAssignTasks: false,
    canUpdateTaskStatus: true,
    canViewJobOrders: true,
    canCreateUsers: false,
    canEditUsers: false,
    canDeleteUsers: false,
    canViewUsers: false,
    canAssignRoles: false,
    canViewCosts: false,
    canEditCosts: false,
    canGenerateInvoices: false,
    canViewAnalytics: false,
    canExportData: false,
    canEditSettings: false,
    canManageSystem: false,
  },
  
  inspector: {
    // Inspector permissions
    canCreateCustomers: false,
    canEditCustomers: false,
    canDeleteCustomers: false,
    canViewCustomers: true,
    canCreateCars: false,
    canEditCars: false,
    canDeleteCars: false,
    canViewCars: true,
    canCreateSessions: false,
    canEditSessions: false,
    canDeleteSessions: false,
    canViewSessions: true,
    canAssignSessions: false,
    canCreateInspections: true,
    canEditInspections: true,
    canApproveInspections: true,
    canViewInspections: true,
    canCreateTestDrives: true,
    canEditTestDrives: true,
    canApproveTestDrives: true,
    canViewTestDrives: true,
    canGenerateReports: false,
    canEditReports: false,
    canShareReports: false,
    canViewReports: true,
    canCreateJobOrders: false,
    canEditJobOrders: false,
    canApproveJobOrders: false,
    canAssignTasks: false,
    canUpdateTaskStatus: false,
    canViewJobOrders: true,
    canCreateUsers: false,
    canEditUsers: false,
    canDeleteUsers: false,
    canViewUsers: false,
    canAssignRoles: false,
    canViewCosts: false,
    canEditCosts: false,
    canGenerateInvoices: false,
    canViewAnalytics: false,
    canExportData: false,
    canEditSettings: false,
    canManageSystem: false,
  },
  
  cashier: {
    // Cashier permissions
    canCreateCustomers: false,
    canEditCustomers: false,
    canDeleteCustomers: false,
    canViewCustomers: true,
    canCreateCars: false,
    canEditCars: false,
    canDeleteCars: false,
    canViewCars: true,
    canCreateSessions: false,
    canEditSessions: false,
    canDeleteSessions: false,
    canViewSessions: true,
    canAssignSessions: false,
    canCreateInspections: false,
    canEditInspections: false,
    canApproveInspections: false,
    canViewInspections: true,
    canCreateTestDrives: false,
    canEditTestDrives: false,
    canApproveTestDrives: false,
    canViewTestDrives: true,
    canGenerateReports: false,
    canEditReports: false,
    canShareReports: false,
    canViewReports: true,
    canCreateJobOrders: false,
    canEditJobOrders: false,
    canApproveJobOrders: false,
    canAssignTasks: false,
    canUpdateTaskStatus: false,
    canViewJobOrders: true,
    canCreateUsers: false,
    canEditUsers: false,
    canDeleteUsers: false,
    canViewUsers: false,
    canAssignRoles: false,
    canViewCosts: true,
    canEditCosts: false,
    canGenerateInvoices: true,
    canViewAnalytics: false,
    canExportData: false,
    canEditSettings: false,
    canManageSystem: false,
  },
  
  viewer: {
    // View-only permissions
    canCreateCustomers: false,
    canEditCustomers: false,
    canDeleteCustomers: false,
    canViewCustomers: true,
    canCreateCars: false,
    canEditCars: false,
    canDeleteCars: false,
    canViewCars: true,
    canCreateSessions: false,
    canEditSessions: false,
    canDeleteSessions: false,
    canViewSessions: true,
    canAssignSessions: false,
    canCreateInspections: false,
    canEditInspections: false,
    canApproveInspections: false,
    canViewInspections: true,
    canCreateTestDrives: false,
    canEditTestDrives: false,
    canApproveTestDrives: false,
    canViewTestDrives: true,
    canGenerateReports: false,
    canEditReports: false,
    canShareReports: false,
    canViewReports: true,
    canCreateJobOrders: false,
    canEditJobOrders: false,
    canApproveJobOrders: false,
    canAssignTasks: false,
    canUpdateTaskStatus: false,
    canViewJobOrders: true,
    canCreateUsers: false,
    canEditUsers: false,
    canDeleteUsers: false,
    canViewUsers: false,
    canAssignRoles: false,
    canViewCosts: false,
    canEditCosts: false,
    canGenerateInvoices: false,
    canViewAnalytics: false,
    canExportData: false,
    canEditSettings: false,
    canManageSystem: false,
  },
};