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

// Type definitions for client data
export interface ClientData {
  id: string;
  name: string;
  phone: string;
  email?: string;
  address?: {
    street?: string;
    city: string;
    state?: string;
    zipCode?: string;
    country: string;
  };
  garageId: string;
  carsId: string[];
  sessionsId: string[];
  createdAt: string;
  updatedAt: string;
}

/**
 * Get all clients
 * @param garageId Optional parameter to filter clients by garage
 * @returns Promise resolving to array of client data
 */
export const getAllClients = async (garageId?: string): Promise<ClientData[]> => {
  try {
    let clientsQuery;
    
    if (garageId) {
      clientsQuery = query(
        collection(db, 'clients'),
        where('garageId', '==', garageId),
        orderBy('createdAt', 'desc')
      );
    } else {
      clientsQuery = query(
        collection(db, 'clients'),
        orderBy('createdAt', 'desc')
      );
    }

    const querySnapshot = await getDocs(clientsQuery);
    const clients: ClientData[] = [];
    
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      
      // Process timestamps to string format
      const createdAt = data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt;
      const updatedAt = data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt;
      
      clients.push({
        id: doc.id,
        ...data,
        createdAt,
        updatedAt
      } as ClientData);
    });
    
    return clients;
  } catch (error) {
    console.error('Error fetching clients:', error);
    throw error;
  }
};

/**
 * Get a client by ID
 * @param id Client ID
 * @returns Promise resolving to client data or null if not found
 */
export const getClientById = async (id: string): Promise<ClientData | null> => {
  try {
    const clientRef = doc(db, 'clients', id);
    const clientDoc = await getDoc(clientRef);

    if (clientDoc.exists()) {
      const data = clientDoc.data();
      
      // Process timestamps to string format
      const createdAt = data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt;
      const updatedAt = data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt;
      
      return {
        id: clientDoc.id,
        ...data,
        createdAt,
        updatedAt
      } as ClientData;
    }
    
    return null;
  } catch (error) {
    console.error('Error fetching client:', error);
    throw error;
  }
};

/**
 * Create a new client
 * @param clientData Client data to create
 * @returns Promise resolving to the new client ID
 */
export const createClient = async (clientData: Omit<ClientData, 'id' | 'createdAt' | 'updatedAt'>): Promise<string> => {
  try {
    const now = Timestamp.now();
    
    const newClientData = {
      ...clientData,
      carsId: clientData.carsId || [],
      sessionsId: clientData.sessionsId || [],
      createdAt: now,
      updatedAt: now
    };
    
    const docRef = await addDoc(collection(db, 'clients'), newClientData);
    return docRef.id;
  } catch (error) {
    console.error('Error creating client:', error);
    throw error;
  }
};

/**
 * Update an existing client
 * @param id Client ID
 * @param clientData Updated client data
 */
export const updateClient = async (id: string, clientData: Partial<Omit<ClientData, 'id' | 'createdAt' | 'updatedAt'>>): Promise<void> => {
  try {
    const clientRef = doc(db, 'clients', id);
    
    await updateDoc(clientRef, {
      ...clientData,
      updatedAt: Timestamp.now()
    });
  } catch (error) {
    console.error('Error updating client:', error);
    throw error;
  }
};

/**
 * Delete a client
 * @param id Client ID
 */
export const deleteClient = async (id: string): Promise<void> => {
  try {
    const clientRef = doc(db, 'clients', id);
    await deleteDoc(clientRef);
  } catch (error) {
    console.error('Error deleting client:', error);
    throw error;
  }
};