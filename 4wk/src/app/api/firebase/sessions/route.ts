import { NextResponse } from 'next/server';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import app from '../../../../firebase';

// Initialize Firestore
const db = getFirestore(app);

interface Session {
  id: string;
  createdAt: string | null;
  updatedAt: string | null;
  userId?: string;
  startTime?: string;
  endTime?: string;
  active?: boolean;
  [key: string]: string | number | boolean | null | undefined;
}

export async function GET() {
  try {
    const sessionsCollection = collection(db, 'sessions');
    const sessionsSnapshot = await getDocs(sessionsCollection);
    
    const sessions: Session[] = [];
    sessionsSnapshot.forEach((doc) => {
      const data = doc.data();
      
      // Process timestamps to string format
      const createdAt = data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt;
      const updatedAt = data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt;
      
      sessions.push({
        id: doc.id,
        ...data,
        createdAt,
        updatedAt
      });
    });
    
    return NextResponse.json(sessions);
  } catch (error) {
    console.error('Error fetching sessions:', error);
    return NextResponse.json({ error: 'Failed to fetch sessions' }, { status: 500 });
  }
}