import { NextResponse } from 'next/server';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import app from '../../../../firebase';

// Define interface for car data
interface Car {
  id: string;
  createdAt: string | null;
  updatedAt: string | null;
  make?: string;
  model?: string;
  year?: number;
  vin?: string;
  licensePlate?: string;
  // Add other specific car properties as needed
  [key: string]: string | number | boolean | null | undefined;
}

// Initialize Firestore
const db = getFirestore(app);

export async function GET() {
  try {
    const carsCollection = collection(db, 'cars');
    const carsSnapshot = await getDocs(carsCollection);
    
    const cars: Car[] = [];
    carsSnapshot.forEach((doc) => {
      const data = doc.data();
      
      // Process timestamps to string format
      const createdAt = data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt;
      const updatedAt = data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt;
      
      cars.push({
        id: doc.id,
        ...data,
        createdAt,
        updatedAt
      });
    });
    
    return NextResponse.json(cars);
  } catch (error) {
    console.error('Error fetching cars:', error);
    return NextResponse.json({ error: 'Failed to fetch cars' }, { status: 500 });
  }
}