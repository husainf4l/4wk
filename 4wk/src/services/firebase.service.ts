import { getFirestore, doc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import app from '../firebase';
import { generateRecommendations, generateSummary } from './openai.service';

// Initialize Firestore
const db = getFirestore(app);

// Type definitions for report data with complex object structures
export interface ReportData {
  id: string;
  sessionId: string;
  
  // Timestamps
  createdAt: string;
  updatedAt: string;
  
  // Vehicle information
  carData: {
    make: string;
    model: string;
    year: number;
    plateNumber: string;
    vin: string;
    clientId: string;
    clientName: string;
    clientPhoneNumber: string;
    garageId: string;
    sessions: string[];
  };
  
  // Client information
  clientData: {
    name: string;
    phone: string;
    garageId: string;
    carsId: string[];
    sessionsId: string[];
    address: {
      city: string;
      country: string;
    };
  };
  
  // Inspection data
  conditionRating: number;
  inspectionNotes: string;
  inspectionFindings: Array<{ finding: string; argancy: string; price: number }>;
  inspectionImages: string[];
  
  // Client requests and notes
  clientRequests: Array<{ request: string; argancy: string; price: number }>;
  clientNotes: string;
  clientNotesImages: string[];
  
  // Test drive data
  testDriveNotes: string;
  testDriveObservations: Array<{ observation: string; argancy: string; price: number; id?: string; visible?: boolean }>;
  testDriveImages: string[];
  
  // Additional report data
  recommendations: string;
  summary: string;
  
  // IDs
  clientId: string;
  carId: string;
}

/**
 * Fetch a report by its ID directly from the Firestore 'reports' collection
 * @param id - The document ID for the report
 * @returns Promise resolving to the report data or null if not found
 */
export const getReportBySessionId = async (id: string): Promise<ReportData | null> => {
  try {
    // Check if ID is valid
    if (!id || typeof id !== 'string') {
      console.error('Invalid report ID:', id);
      return null;
    }
    
    // Get document reference using collection and document ID
    const reportRef = doc(db, 'reports', id);
    
    // Get the document
    const docSnap = await getDoc(reportRef);
    
    // Check if document exists
    if (docSnap.exists()) {
      const data = docSnap.data();
      
      // Process timestamps to string format if needed
      const createdAt = data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt;
      const updatedAt = data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt;
      
      // Return the data with the ID
      return { 
        id: docSnap.id,
        ...data,
        createdAt,
        updatedAt
      } as ReportData;
    } else {
      console.log('No report found with ID:', id);
      return null;
    }
  } catch (error) {
    console.error('Error fetching report:', error);
    // Instead of re-throwing the error, return null to prevent 500 errors
    return null;
  }
};

/**
 * Generates professional recommendations and summary for a report using AI
 * and updates the report in Firestore
 * @param reportId The ID of the report to update
 */
export const generateAndUpdateReportAI = async (reportId: string): Promise<void> => {
  try {
    console.log(`Starting AI generation for report ${reportId}`);
    
    // Get the current report data
    const reportRef = doc(db, "reports", reportId);
    const reportSnapshot = await getDoc(reportRef);
    
    if (!reportSnapshot.exists()) {
      console.error(`Report with ID ${reportId} not found`);
      throw new Error(`Report with ID ${reportId} not found`);
    }
    
    const reportData = reportSnapshot.data() as ReportData;
    console.log(`Retrieved report data for ${reportId}`);
    
    // Format the data for the OpenAI service
    const openAIInput = {
      inspectionFindings: reportData.inspectionFindings || [],
      inspectionNotes: reportData.inspectionNotes || "",
      testDriveObservations: reportData.testDriveObservations || [],
      testDriveNotes: reportData.testDriveNotes || "",
      clientRequests: reportData.clientRequests || [],
      carData: {
        make: reportData.carData?.make || "",
        model: reportData.carData?.model || "",
        year: reportData.carData?.year || "",
      }
    };
    
    console.log('OpenAI input prepared:', JSON.stringify(openAIInput));
    
    // Generate recommendations and summary using OpenAI
    console.log('Calling OpenAI services for recommendations and summary...');
    const [recommendations, summary] = await Promise.all([
      generateRecommendations(openAIInput),
      generateSummary(openAIInput)
    ]);
    
    console.log('AI content generated successfully');
    console.log('Recommendations:', recommendations);
    console.log('Summary:', summary);
    
    // Update the report with the AI-generated content
    console.log(`Updating report ${reportId} with AI-generated content`);
    await updateDoc(reportRef, {
      recommendations,
      summary,
      updatedAt: serverTimestamp()
    });
    
    console.log(`Report ${reportId} successfully updated with AI content`);
  } catch (error) {
    console.error("Error in generateAndUpdateReportAI:", error);
    throw error;
  }
};

/**
 * Updates a report with client feedback notes
 * @param reportId The ID of the report to update
 * @param feedbackNotes The feedback notes from the client
 */
export const updateReportFeedback = async (reportId: string, feedbackNotes: string): Promise<void> => {
  try {
    console.log(`Updating feedback notes for report ${reportId}`);
    
    // Get the document reference
    const reportRef = doc(db, "reports", reportId);
    
    // Update the document with the feedback notes and timestamp
    await updateDoc(reportRef, {
      feedbackNotes,
      updatedAt: serverTimestamp()
    });
    
    console.log(`Report ${reportId} successfully updated with feedback notes`);
  } catch (error) {
    console.error("Error in updateReportFeedback:", error);
    throw error;
  }
};