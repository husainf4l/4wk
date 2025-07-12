import { StackNavigationProp } from '@react-navigation/stack';
import { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import { RouteProp } from '@react-navigation/native';

// Main Stack Navigator
export type RootStackParamList = {
  // Auth
  Login: undefined;
  Register: undefined;
  
  // Main App
  MainTabs: undefined;
  
  // Customer Flow
  AddCustomer: { customerId?: string };
  CustomerDetails: { customerId: string };
  EditCustomer: { customerId: string };
  
  // Car Flow
  AddCar: { customerId: string; carId?: string };
  CarDetails: { carId: string };
  EditCar: { carId: string };
  
  // Session Flow
  CreateSession: { customerId: string; carId: string; sessionId?: string };
  SessionDetails: { sessionId: string };
  EditSession: { sessionId: string };
  
  // Inspection Flow
  Inspection: { sessionId: string };
  InspectionDetails: { inspectionId: string };
  
  // Test Drive Flow
  TestDrive: { sessionId: string };
  TestDriveDetails: { testDriveId: string };
  
  // Report Flow
  Report: { sessionId: string };
  ReportPreview: { sessionId: string };
  ShareReport: { sessionId: string };
  
  // Job Order Flow
  JobOrder: { sessionId: string };
  JobOrderDetails: { jobOrderId: string };
  
  // Settings
  Settings: undefined;
  Profile: undefined;
  
  // Modals
  ImageViewer: { images: string[]; initialIndex?: number };
  DocumentViewer: { url: string; title?: string };
  QRScanner: undefined;
};

// Bottom Tab Navigator
export type MainTabParamList = {
  Dashboard: undefined;
  Customers: undefined;
  Sessions: undefined;
  Reports: undefined;
  Profile: undefined;
};

// Customer Stack Navigator
export type CustomerStackParamList = {
  CustomersList: undefined;
  CustomerDetails: { customerId: string };
  AddCustomer: { customerId?: string };
  EditCustomer: { customerId: string };
};

// Session Stack Navigator
export type SessionStackParamList = {
  SessionsList: undefined;
  SessionDetails: { sessionId: string };
  CreateSession: { customerId: string; carId: string };
  EditSession: { sessionId: string };
};

// Navigation Props Types
export type RootStackNavigationProp<T extends keyof RootStackParamList> = StackNavigationProp<
  RootStackParamList,
  T
>;

export type MainTabNavigationProp<T extends keyof MainTabParamList> = BottomTabNavigationProp<
  MainTabParamList,
  T
>;

export type CustomerStackNavigationProp<T extends keyof CustomerStackParamList> = StackNavigationProp<
  CustomerStackParamList,
  T
>;

export type SessionStackNavigationProp<T extends keyof SessionStackParamList> = StackNavigationProp<
  SessionStackParamList,
  T
>;

// Route Props Types
export type RootStackRouteProp<T extends keyof RootStackParamList> = RouteProp<
  RootStackParamList,
  T
>;

export type MainTabRouteProp<T extends keyof MainTabParamList> = RouteProp<MainTabParamList, T>;

export type CustomerStackRouteProp<T extends keyof CustomerStackParamList> = RouteProp<
  CustomerStackParamList,
  T
>;

export type SessionStackRouteProp<T extends keyof SessionStackParamList> = RouteProp<
  SessionStackParamList,
  T
>;

// Screen Props Types
export interface ScreenProps<
  NavigationProp extends any,
  RouteProp extends any
> {
  navigation: NavigationProp;
  route: RouteProp;
}

// Workflow navigation helpers
export interface WorkflowNavigationState {
  currentStep: 'customer' | 'car' | 'session' | 'inspection' | 'test-drive' | 'report' | 'job-order';
  customerId?: string;
  carId?: string;
  sessionId?: string;
  canGoBack: boolean;
  canGoNext: boolean;
  progress: number;
}

export interface NavigationOptions {
  title?: string;
  headerShown?: boolean;
  headerBackTitle?: string;
  headerLeft?: () => React.ReactElement;
  headerRight?: () => React.ReactElement;
  gestureEnabled?: boolean;
  animation?: 'slide' | 'fade' | 'none';
}

// Deep linking types
export interface DeepLinkConfig {
  screens: {
    [key in keyof RootStackParamList]?: string | DeepLinkConfig;
  };
}

export interface LinkingOptions {
  prefixes: string[];
  config: DeepLinkConfig;
}