import { NextResponse } from 'next/server';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import app from '../../../../firebase';

// Initialize Firestore
const db = getFirestore(app);
interface Clients {
  id: string;
  createdAt: string | null;
  updatedAt: string | null;
  name?: string;
  email?: string;
  phone?: string;
  address?: string;
  [key: string]: string | number | boolean | null | undefined;
}

export async function GET() {
  try {
    const clientsCollection = collection(db, 'clients');
    const clientsSnapshot = await getDocs(clientsCollection);
    
    const clients: Clients[] = [];
    clientsSnapshot.forEach((doc) => {
      const data = doc.data();
      
      // Process timestamps to string format
      const createdAt = data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt;
      const updatedAt = data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt;
      
      clients.push({
        id: doc.id,
        ...data,
        createdAt,
        updatedAt
      });
    });
    
    return NextResponse.json(clients);
  } catch (error) {
    console.error('Error fetching clients:', error);
    return NextResponse.json({ error: 'Failed to fetch clients' }, { status: 500 });
  }
}