import { 
  getFirestore, 
  collection, 
  doc, 
  getDoc, 
  getDocs, 
  query, 
  where,
  orderBy,
  addDoc,
  updateDoc,
  deleteDoc,
  Timestamp 
} from 'firebase/firestore';
import app from '../firebase';

// Initialize Firestore
const db = getFirestore(app);

// Type definitions for job card data
export interface JobCardData {
  id: string;
  
  // Basic info
  jobNumber: string;
  title: string;
  description: string;
  status: 'pending' | 'in-progress' | 'completed' | 'cancelled';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  
  // Related entities
  carId: string;
  clientId: string;
  garageId: string;
  sessionId?: string;
  reportId?: string;
  
  // Tasks and costs
  tasks: {
    id: string;
    name: string;
    description?: string;
    status: 'pending' | 'in-progress' | 'completed' | 'cancelled';
    estimatedHours?: number;
    actualHours?: number;
    assignedTo?: string;
  }[];
  
  parts: {
    id: string;
    name: string;
    quantity: number;
    unitPrice: number;
    totalPrice: number;
  }[];
  
  // Pricing
  laborCost: number;
  partsCost: number;
  additionalCost: number;
  totalCost: number;
  
  // Dates
  createdAt: string;
  updatedAt: string;
  scheduledDate?: string;
  startDate?: string;
  completionDate?: string;
  
  // Additional info
  notes?: string;
  customerNotes?: string;
  technicianNotes?: string;
  images?: string[];
  approvedByClient: boolean;
  paymentStatus?: 'unpaid' | 'partially-paid' | 'paid';
}

/**
 * Get all job cards
 * @param garageId Optional parameter to filter job cards by garage
 * @returns Promise resolving to array of job card data
 */
export const getAllJobCards = async (garageId?: string): Promise<JobCardData[]> => {
  try {
    let jobCardsQuery;
    
    if (garageId) {
      jobCardsQuery = query(
        collection(db, 'jobCards'),
        where('garageId', '==', garageId),
        orderBy('createdAt', 'desc')
      );
    } else {
      jobCardsQuery = query(
        collection(db, 'jobCards'),
        orderBy('createdAt', 'desc')
      );
    }

    const querySnapshot = await getDocs(jobCardsQuery);
    const jobCards: JobCardData[] = [];
    
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      
      // Process timestamps to string format
      const createdAt = data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt;
      const updatedAt = data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt;
      const scheduledDate = data.scheduledDate?.toDate?.() ? data.scheduledDate.toDate().toISOString() : data.scheduledDate;
      const startDate = data.startDate?.toDate?.() ? data.startDate.toDate().toISOString() : data.startDate;
      const completionDate = data.completionDate?.toDate?.() ? data.completionDate.toDate().toISOString() : data.completionDate;
      
      jobCards.push({
        id: doc.id,
        ...data,
        createdAt,
        updatedAt,
        scheduledDate,
        startDate,
        completionDate
      } as JobCardData);
    });
    
    return jobCards;
  } catch (error) {
    console.error('Error fetching job cards:', error);
    throw error;
  }
};

/**
 * Get a job card by ID
 * @param id Job card ID
 * @returns Promise resolving to job card data or null if not found
 */
export const getJobCardById = async (id: string): Promise<JobCardData | null> => {
  try {
    const jobCardRef = doc(db, 'jobCards', id);
    const jobCardDoc = await getDoc(jobCardRef);

    if (jobCardDoc.exists()) {
      const data = jobCardDoc.data();
      
      // Process timestamps to string format
      const createdAt = data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt;
      const updatedAt = data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt;
      const scheduledDate = data.scheduledDate?.toDate?.() ? data.scheduledDate.toDate().toISOString() : data.scheduledDate;
      const startDate = data.startDate?.toDate?.() ? data.startDate.toDate().toISOString() : data.startDate;
      const completionDate = data.completionDate?.toDate?.() ? data.completionDate.toDate().toISOString() : data.completionDate;
      
      return {
        id: jobCardDoc.id,
        ...data,
        createdAt,
        updatedAt,
        scheduledDate,
        startDate,
        completionDate
      } as JobCardData;
    }
    
    return null;
  } catch (error) {
    console.error('Error fetching job card:', error);
    throw error;
  }
};

/**
 * Get job cards by car ID
 * @param carId Car ID
 * @returns Promise resolving to array of job card data
 */
export const getJobCardsByCarId = async (carId: string): Promise<JobCardData[]> => {
  try {
    const jobCardsQuery = query(
      collection(db, 'jobCards'),
      where('carId', '==', carId),
      orderBy('createdAt', 'desc')
    );
    
    const querySnapshot = await getDocs(jobCardsQuery);
    const jobCards: JobCardData[] = [];
    
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      
      // Process timestamps to string format
      const createdAt = data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt;
      const updatedAt = data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt;
      const scheduledDate = data.scheduledDate?.toDate?.() ? data.scheduledDate.toDate().toISOString() : data.scheduledDate;
      const startDate = data.startDate?.toDate?.() ? data.startDate.toDate().toISOString() : data.startDate;
      const completionDate = data.completionDate?.toDate?.() ? data.completionDate.toDate().toISOString() : data.completionDate;
      
      jobCards.push({
        id: doc.id,
        ...data,
        createdAt,
        updatedAt,
        scheduledDate,
        startDate,
        completionDate
      } as JobCardData);
    });
    
    return jobCards;
  } catch (error) {
    console.error('Error fetching job cards by car ID:', error);
    throw error;
  }
};

/**
 * Create a new job card
 * @param jobCardData Job card data to create
 * @returns Promise resolving to the new job card ID
 */
export const createJobCard = async (jobCardData: Omit<JobCardData, 'id' | 'createdAt' | 'updatedAt'>): Promise<string> => {
  try {
    const now = Timestamp.now();
    
    // Generate job number if not provided
    let jobNumber = jobCardData.jobNumber;
    if (!jobNumber) {
      const date = new Date();
      const year = date.getFullYear().toString().slice(2);
      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
      jobNumber = `JC-${year}${month}-${random}`;
    }
    
    const newJobCardData = {
      ...jobCardData,
      jobNumber,
      tasks: jobCardData.tasks || [],
      parts: jobCardData.parts || [],
      laborCost: jobCardData.laborCost || 0,
      partsCost: jobCardData.partsCost || 0,
      additionalCost: jobCardData.additionalCost || 0,
      totalCost: jobCardData.totalCost || 0,
      approvedByClient: jobCardData.approvedByClient || false,
      createdAt: now,
      updatedAt: now
    };
    
    const docRef = await addDoc(collection(db, 'jobCards'), newJobCardData);
    return docRef.id;
  } catch (error) {
    console.error('Error creating job card:', error);
    throw error;
  }
};

/**
 * Update an existing job card
 * @param id Job card ID
 * @param jobCardData Updated job card data
 */
export const updateJobCard = async (id: string, jobCardData: Partial<Omit<JobCardData, 'id' | 'createdAt' | 'updatedAt'>>): Promise<void> => {
  try {
    const jobCardRef = doc(db, 'jobCards', id);
    
    await updateDoc(jobCardRef, {
      ...jobCardData,
      updatedAt: Timestamp.now()
    });
  } catch (error) {
    console.error('Error updating job card:', error);
    throw error;
  }
};

/**
 * Delete a job card
 * @param id Job card ID
 */
export const deleteJobCard = async (id: string): Promise<void> => {
  try {
    const jobCardRef = doc(db, 'jobCards', id);
    await deleteDoc(jobCardRef);
  } catch (error) {
    console.error('Error deleting job card:', error);
    throw error;
  }
};