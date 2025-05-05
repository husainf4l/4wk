import { NextRequest, NextResponse } from 'next/server';
import { handleChatMessage, getChatHistory, clearChatHistory } from '@/services/chatbot.service';
import { v4 as uuidv4 } from 'uuid';

// Removed the "runtime = 'edge'" declaration since it's incompatible with Firestore operations

/**
 * POST handler for chatbot API
 * 
 * Request body should contain:
 * - sessionId: string (optional unique identifier for the chat session, will be generated if not provided)
 * - message: string (the user's message)
 * - reset?: boolean (optional, if true, clears chat history)
 * - userId?: string (optional, to associate chat with a user)
 * - clientId?: string (optional, to associate chat with a client)
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    // Generate sessionId if not provided
    const sessionId = body.sessionId || uuidv4();
    
    // Handle reset request if specified
    if (body.reset === true) {
      await clearChatHistory(sessionId);
      return NextResponse.json({
        sessionId: sessionId,
        reply: "Chat history has been cleared. How can I help you today?",
        messages: []
      });
    }
    
    // Validate message for normal chat requests
    if (!body.message || typeof body.message !== 'string') {
      return NextResponse.json(
        { error: 'Message is required and must be a string' },
        { status: 400 }
      );
    }

    // Process the chat message
    const response = await handleChatMessage(
      sessionId, 
      body.message,
      body.userId,
      body.clientId
    );
    
    // Get updated chat history
    const messages = await getChatHistory(sessionId);
    
    // Return response with chat history
    return NextResponse.json({
      sessionId, // Return the sessionId (new or existing)
      reply: response.reply,
      messages,
      ...(response.databaseInfo ? { databaseInfo: response.databaseInfo } : {}),
      ...(response.error ? { error: response.error } : {})
    });
  } catch (error) {
    console.error('Error in chatbot API:', error);
    
    return NextResponse.json(
      { error: 'Internal server error processing chat request' },
      { status: 500 }
    );
  }
}

/**
 * GET handler for retrieving chat history
 * 
 * Query parameters:
 * - sessionId: string (unique identifier for the chat session)
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const sessionId = searchParams.get('sessionId');
    
    if (!sessionId) {
      return NextResponse.json(
        { error: 'Session ID is required as a query parameter' },
        { status: 400 }
      );
    }
    
    const messages = await getChatHistory(sessionId);
    
    return NextResponse.json({
      sessionId,
      messages
    });
  } catch (error) {
    console.error('Error retrieving chat history:', error);
    
    return NextResponse.json(
      { error: 'Internal server error retrieving chat history' },
      { status: 500 }
    );
  }
}