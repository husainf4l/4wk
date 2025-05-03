import { getFirestore, doc, getDoc } from 'firebase/firestore';
import app from '../firebase';

// Initialize Firestore
const db = getFirestore(app);

// Type definitions for report data
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
  inspectionFindings: string[];
  inspectionImages: string[];
  
  // Client requests and notes
  clientRequests: string[];
  clientNotes: string;
  clientNotesImages: string[];
  
  // Test drive data
  testDriveNotes: string;
  testDriveObservations: string[];
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