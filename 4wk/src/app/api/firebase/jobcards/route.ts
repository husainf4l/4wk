import { NextResponse } from 'next/server';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import app from '../../../../firebase';

// Initialize Firestore
const db = getFirestore(app);
interface JobCard {
  id: string;
  createdAt: string | null;
  updatedAt: string | null;
  scheduledDate?: string | null;
  startDate?: string | null;
  completionDate?: string | null;
  clientId?: string;
  vehicleId?: string;
  description?: string;
  status?: string;
  [key: string]: string | number | boolean | null | undefined;
}

export async function GET() {
  try {
    const jobCardsCollection = collection(db, 'jobCards');
    const jobCardsSnapshot = await getDocs(jobCardsCollection);
    
    const jobCards: JobCard[] = [];
    jobCardsSnapshot.forEach((doc) => {
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
      });
    });
    
    return NextResponse.json(jobCards);
  } catch (error) {
    console.error('Error fetching job cards:', error);
    return NextResponse.json({ error: 'Failed to fetch job cards' }, { status: 500 });
  }
}