import { NextRequest, NextResponse } from "next/server";
import { generateRecommendations, generateSummary } from "@/services/openai.service";
import { doc, getDoc, updateDoc, serverTimestamp, getFirestore } from "firebase/firestore";
import app from "@/firebase";

// Initialize Firestore
const db = getFirestore(app);

/**
 * POST handler for generating AI recommendations and summaries
 * Can be called from external clients like a Flutter app
 */
export async function POST(req: NextRequest) {
  try {
    // Parse request body
    const body = await req.json();
    const { reportId, updateFirebase = false } = body;
    
    // Validate request
    if (!reportId) {
      return NextResponse.json(
        { error: "Missing required field: reportId" },
        { status: 400 }
      );
    }

    // Get report data if we have a reportId
    const reportRef = doc(db, "reports", reportId);
    const reportSnapshot = await getDoc(reportRef);
    
    if (!reportSnapshot.exists()) {
      return NextResponse.json(
        { error: `Report with ID ${reportId} not found` },
        { status: 404 }
      );
    }
    
    const reportData = reportSnapshot.data();
    
    // Prepare input data for OpenAI
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
    
    // Generate AI content
    const [recommendations, summary] = await Promise.all([
      generateRecommendations(openAIInput),
      generateSummary(openAIInput)
    ]);
    
    // Update Firebase if requested
    if (updateFirebase) {
      await updateDoc(reportRef, {
        recommendations,
        summary,
        updatedAt: serverTimestamp()
      });
    }
    
    // Return the generated content
    return NextResponse.json({
      success: true,
      data: {
        recommendations,
        summary,
        updatedFirebase: updateFirebase,
        reportId
      }
    });
    
  } catch (error) {
    console.error("Error generating AI content:", error);
    
    return NextResponse.json(
      { error: "Failed to generate AI content", details: (error as Error).message },
      { status: 500 }
    );
  }
}

/**
 * GET handler for generating AI content with query parameters
 * Useful for simple testing and direct browser access
 */
export async function GET(req: NextRequest) {
  try {
    // Get reportId from query string
    const { searchParams } = new URL(req.url);
    const reportId = searchParams.get('reportId');
    const updateFirebase = searchParams.get('update') === 'true';
    
    // Validate request
    if (!reportId) {
      return NextResponse.json(
        { error: "Missing required query parameter: reportId" },
        { status: 400 }
      );
    }
    
    // Get report data
    const reportRef = doc(db, "reports", reportId);
    const reportSnapshot = await getDoc(reportRef);
    
    if (!reportSnapshot.exists()) {
      return NextResponse.json(
        { error: `Report with ID ${reportId} not found` },
        { status: 404 }
      );
    }
    
    const reportData = reportSnapshot.data();
    
    // Prepare input data for OpenAI
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
    
    // Generate AI content
    const [recommendations, summary] = await Promise.all([
      generateRecommendations(openAIInput),
      generateSummary(openAIInput)
    ]);
    
    // Update Firebase if requested
    if (updateFirebase) {
      await updateDoc(reportRef, {
        recommendations,
        summary,
        updatedAt: serverTimestamp()
      });
    }
    
    // Return the generated content
    return NextResponse.json({
      success: true,
      data: {
        recommendations,
        summary,
        updatedFirebase: updateFirebase,
        reportId
      }
    });
    
  } catch (error) {
    console.error("Error generating AI content:", error);
    
    return NextResponse.json(
      { error: "Failed to generate AI content", details: (error as Error).message },
      { status: 500 }
    );
  }
}