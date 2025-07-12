export type ReportStatus = 'draft' | 'generated' | 'shared' | 'viewed_by_customer';

export interface ReportSection {
  id: string;
  title: string;
  content: string;
  order: number;
  includeInReport: boolean;
  photos?: string[]; // URLs to photos in S3
  videos?: string[]; // URLs to videos in S3
}

export interface Report {
  id: string;
  sessionId: string;
  
  // Basic Information
  reportNumber: string; // Auto-generated unique report number
  generatedDate: Date;
  generatedBy: string; // User ID who generated the report
  
  // Customer and Car Information
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
  carDetails: {
    make: string;
    model: string;
    year: number;
    plateNumber: string;
    mileage: number;
  };
  
  // Session Summary
  sessionSummary: {
    sessionNumber: string;
    startDate: Date;
    endDate?: Date;
    customerRequests: string[];
    assignedTechnician?: string;
    serviceAdvisor?: string;
  };
  
  // Report Sections
  sections: ReportSection[];
  
  // Inspection Summary
  inspectionSummary?: {
    overallCondition: string;
    totalIssuesFound: number;
    criticalIssues: number;
    recommendations: string[];
  };
  
  // Test Drive Summary
  testDriveSummary?: {
    overallPerformance: string;
    drivabilityRating: number;
    issuesIdentified: string[];
    recommendations: string[];
  };
  
  // Findings and Recommendations
  keyFindings: string[];
  priorityRecommendations: string[];
  optionalRecommendations: string[];
  
  // Cost Estimates
  estimatedRepairCost?: number;
  estimatedRepairTime?: number;
  
  // Report Metadata
  status: ReportStatus;
  isPublic: boolean; // Can customer access without login
  publicAccessToken?: string; // Token for public access
  
  // Sharing Information
  sharedAt?: Date;
  sharedVia?: 'whatsapp' | 'email' | 'sms' | 'link';
  viewedByCustomer: boolean;
  customerViewedAt?: Date;
  customerFeedback?: string;
  customerRating?: number; // 1-5 stars
  
  // Report Settings
  includePhotos: boolean;
  includeVideos: boolean;
  includeDetailedFindings: boolean;
  includeCostEstimates: boolean;
  brandedTemplate: boolean;
  language: 'en' | 'ar';
  
  // Files
  pdfUrl?: string; // URL to generated PDF in S3
  htmlContent?: string; // HTML version of the report
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}

export interface CreateReportData {
  sessionId: string;
  generatedBy: string;
  includePhotos?: boolean;
  includeVideos?: boolean;
  includeDetailedFindings?: boolean;
  includeCostEstimates?: boolean;
  brandedTemplate?: boolean;
  language?: 'en' | 'ar';
  customSections?: Omit<ReportSection, 'id'>[];
}

export interface UpdateReportData extends Partial<CreateReportData> {
  id: string;
  status?: ReportStatus;
  keyFindings?: string[];
  priorityRecommendations?: string[];
  optionalRecommendations?: string[];
  estimatedRepairCost?: number;
  estimatedRepairTime?: number;
  customerFeedback?: string;
  customerRating?: number;
}

export interface ShareReportData {
  reportId: string;
  shareVia: 'whatsapp' | 'email' | 'sms' | 'link';
  recipientPhone?: string;
  recipientEmail?: string;
  message?: string;
}

export interface ReportSummary {
  id: string;
  reportNumber: string;
  sessionId: string;
  customerName: string;
  carInfo: string;
  generatedDate: Date;
  status: ReportStatus;
  viewedByCustomer: boolean;
  sharedVia?: 'whatsapp' | 'email' | 'sms' | 'link';
}

// Default report sections template
export const DEFAULT_REPORT_SECTIONS: Omit<ReportSection, 'id'>[] = [
  {
    title: 'Executive Summary',
    content: 'Brief overview of the inspection and test drive results.',
    order: 1,
    includeInReport: true,
  },
  {
    title: 'Customer Requests',
    content: 'Original customer concerns and requests addressed during this session.',
    order: 2,
    includeInReport: true,
  },
  {
    title: 'Visual Inspection Results',
    content: 'Detailed findings from the comprehensive vehicle inspection.',
    order: 3,
    includeInReport: true,
  },
  {
    title: 'Test Drive Results',
    content: 'Performance evaluation results from the test drive.',
    order: 4,
    includeInReport: true,
  },
  {
    title: 'Priority Recommendations',
    content: 'Critical and high-priority items that require immediate attention.',
    order: 5,
    includeInReport: true,
  },
  {
    title: 'Optional Recommendations',
    content: 'Additional maintenance and improvement suggestions.',
    order: 6,
    includeInReport: true,
  },
  {
    title: 'Cost Estimates',
    content: 'Estimated costs and time requirements for recommended services.',
    order: 7,
    includeInReport: false,
  },
  {
    title: 'Next Steps',
    content: 'Recommended actions and follow-up procedures.',
    order: 8,
    includeInReport: true,
  },
];