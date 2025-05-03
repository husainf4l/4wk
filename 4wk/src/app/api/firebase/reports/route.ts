import { NextResponse } from 'next/server';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import app from '../../../../firebase';

// Initialize Firestore
const db = getFirestore(app);

interface Report {
  id: string;
  createdAt: string | null;
  updatedAt: string | null;
  title?: string;
  content?: string;
  jobCardId?: string;
  clientId?: string;
  vehicleId?: string;
  [key: string]: string | number | boolean | null | undefined;
}

export async function GET() {
  try {
    const reportsCollection = collection(db, 'reports');
    const reportsSnapshot = await getDocs(reportsCollection);
    
    const reports: Report[] = [];
    
    reportsSnapshot.forEach((doc) => {
      const data = doc.data();
      
      // Process timestamps to string format
      const createdAt = data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt;
      const updatedAt = data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt;
      
      reports.push({
        id: doc.id,
        ...data,
        createdAt,
        updatedAt
      });
    });
    
    return NextResponse.json(reports);
  } catch (error) {
    console.error('Error fetching reports:', error);
    return NextResponse.json({ error: 'Failed to fetch reports' }, { status: 500 });
  }
}