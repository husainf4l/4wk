import OpenAI from 'openai';

// Check if API key is available
const OPENAI_API_KEY = process.env.NEXT_PUBLIC_OPENAI_API_KEY;
if (!OPENAI_API_KEY) {
  console.warn('OpenAI API key is not defined in environment variables. AI features will use fallback text instead.');
}

// Initialize OpenAI client with a try-catch to handle potential initialization errors
let openai: OpenAI | null = null;
try {
  if (OPENAI_API_KEY) {
    openai = new OpenAI({
      apiKey: OPENAI_API_KEY,
      dangerouslyAllowBrowser: true // Only if using in browser environments
    });
  }
} catch (error) {
  console.error('Failed to initialize OpenAI client:', error);
}

// Fallback texts to use when OpenAI is not available
const FALLBACK_RECOMMENDATION = 
  "Based on our thorough inspection, we recommend addressing the following issues: First, prioritize any safety-critical items like brake wear or steering anomalies. Second, address engine or transmission concerns to prevent further damage. Regular maintenance including oil changes, filter replacements, and fluid checks are essential for optimal vehicle performance and longevity. We suggest following the manufacturer's recommended service schedule.";

const FALLBACK_SUMMARY = 
  "Vehicle inspection reveals several issues requiring attention. The most critical findings include issues identified during the test drive and visual inspection. These concerns may affect vehicle safety, performance, and reliability if not addressed promptly. Overall condition rating indicates necessary maintenance. We recommend scheduling service according to the prioritized recommendations provided in this report.";

/**
 * Interface for the report data that will be used to generate recommendations and summaries
 */
interface ReportDataInput {
  inspectionFindings?: Array<{ finding: string; argancy: string }>;
  inspectionNotes?: string;
  testDriveObservations?: Array<{ observation: string; argancy: string }>;
  testDriveNotes?: string;
  clientRequests?: Array<{ request: string; argancy: string }>;
  carData?: {
    make?: string;
    model?: string;
    year?: string | number;
  };
}

/**
 * Interface for chat messages
 */
export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

/**
 * Interface for chatbot response
 */
export interface ChatbotResponse {
  reply: string;
  databaseInfo?: DatabaseInfo;
  error?: string;
}

/**
 * Interface for database information returned from queries
 */
interface DatabaseInfo {
  type?: string;
  [key: string]: unknown;
}

/**
 * Generates professional recommendations based on inspection data
 * @param reportData The report data to base recommendations on
 * @returns A professional recommendation text
 */
export const generateRecommendations = async (reportData: ReportDataInput): Promise<string> => {
  // If OpenAI is not initialized, return fallback text
  if (!openai || !OPENAI_API_KEY) {
    console.log('Using fallback recommendation text as OpenAI is not available');
    return FALLBACK_RECOMMENDATION;
  }

  try {
    // Create a structured prompt from the report data
    const prompt = createRecommendationPrompt(reportData);
    console.log('Sending recommendation prompt to OpenAI:', prompt);

    const response = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",  // Use gpt-3.5-turbo for cost efficiency
      messages: [
        { 
          role: "system", 
          content: "You are an automotive service advisor expert. Write professional recommendations based on vehicle inspection data. Use technical terminology appropriately. Be concise and clear. Limit response to 100 words."
        },
        { role: "user", content: prompt }
      ],
      max_tokens: 150,  // Limit tokens to get approximately 100 words
      temperature: 0.7,
    });

    const recommendationText = response.choices[0]?.message?.content?.trim();
    console.log('Generated recommendation:', recommendationText);
    
    return recommendationText || FALLBACK_RECOMMENDATION;

  } catch (error: unknown) {
    console.error("Error generating recommendations:", error);
    return FALLBACK_RECOMMENDATION;
  }
};

/**
 * Generates a professional summary based on inspection data
 * @param reportData The report data to summarize
 * @returns A professional summary text
 */
export const generateSummary = async (reportData: ReportDataInput): Promise<string> => {
  // If OpenAI is not initialized, return fallback text
  if (!openai || !OPENAI_API_KEY) {
    console.log('Using fallback summary text as OpenAI is not available');
    return FALLBACK_SUMMARY;
  }

  try {
    // Create a structured prompt from the report data
    const prompt = createSummaryPrompt(reportData);
    console.log('Sending summary prompt to OpenAI:', prompt);

    const response = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",  // Use gpt-3.5-turbo for cost efficiency
      messages: [
        { 
          role: "system", 
          content: "You are an automotive service advisor expert. Provide a concise, professional summary of a vehicle inspection report. Prioritize critical issues. Use technical terminology appropriately. Limit response to 100 words."
        },
        { role: "user", content: prompt }
      ],
      max_tokens: 150,  // Limit tokens to get approximately 100 words
      temperature: 0.7,
    });

    const summaryText = response.choices[0]?.message?.content?.trim();
    console.log('Generated summary:', summaryText);
    
    return summaryText || FALLBACK_SUMMARY;

  } catch (error: unknown) {
    console.error("Error generating summary:", error);
    return FALLBACK_SUMMARY;
  }
};

/**
 * Process a chat message with the AI and provide a response
 * Optionally includes database information if requested in the message
 * 
 * @param messages Previous chat messages for context
 * @param newMessage New message from the user
 * @param dbData Optional database data that can be accessed by the chatbot
 * @returns Chatbot response with reply text and optional database info
 */
export const processChatMessage = async (
  messages: ChatMessage[], 
  newMessage: string,
  dbData?: DatabaseInfo | Record<string, unknown>[] | null
): Promise<ChatbotResponse> => {
  // If OpenAI is not initialized, return error
  if (!openai || !OPENAI_API_KEY) {
    console.log('OpenAI is not available for chat');
    return { 
      reply: "Sorry, the AI service is currently unavailable. Please try again later.",
      error: "OpenAI service not initialized"
    };
  }

  try {
    // Create a system message that explains the chatbot's capabilities
    const systemMessage: ChatMessage = {
      role: 'system',
      content: `You are an automotive service assistant for 4WK, helping with vehicle repair and maintenance questions.
      
You have access to the following data if needed:
- Vehicle reports and diagnostics
- Client information
- Maintenance records

Provide helpful, accurate information about vehicle maintenance, repair processes, and interpreting diagnostic reports.
Be professional but conversational. If you don't know something specific, acknowledge it and provide general guidance.
If the user asks about specific database information, you can include it in your response.`
    };

    // Create updated message history including the new message
    const updatedMessages: ChatMessage[] = [
      systemMessage,
      ...messages.slice(-10), // Keep only the last 10 messages for context
      { role: 'user', content: newMessage }
    ];

    // Check if this is a request for database information
    const isDbRequest = checkForDatabaseRequest(newMessage);

    // Prepare database context if requested
    if (isDbRequest && dbData) {
      // Add context about the available database information
      updatedMessages.push({
        role: 'system',
        content: `The following database information is available to answer this query:\n${JSON.stringify(dbData, null, 2)}`
      });
    }

    console.log('Sending chat messages to OpenAI:', updatedMessages);

    const response = await openai.chat.completions.create({
      model: "gpt-4o",  // Using a more advanced model for better conversation
      messages: updatedMessages,
      max_tokens: 500,
      temperature: 0.7,
    });

    const reply = response.choices[0]?.message?.content?.trim() || "I'm sorry, I couldn't generate a response.";
    
    return {
      reply,
      databaseInfo: dbData as DatabaseInfo
    };

  } catch (error: unknown) {
    console.error("Error processing chat message:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return { 
      reply: "Sorry, I encountered an error while processing your message. Please try again.",
      error: errorMessage
    };
  }
};

/**
 * Checks if the user message is requesting database information
 */
function checkForDatabaseRequest(message: string): boolean {
  const dbKeywords = [
    'database', 'record', 'client', 'vehicle', 'car', 'report', 'history',
    'maintenance', 'repair', 'service', 'data', 'information', 'lookup',
    'find', 'search', 'get', 'show', 'display'
  ];
  
  const questionIndicators = ['?', 'what', 'who', 'when', 'where', 'how', 'which', 'can you'];
  
  const lowercaseMsg = message.toLowerCase();
  
  // Check for database keywords
  const hasDbKeyword = dbKeywords.some(keyword => lowercaseMsg.includes(keyword));
  
  // Check for question indicators
  const isQuestion = questionIndicators.some(indicator => lowercaseMsg.includes(indicator));
  
  // If the message contains both a database keyword and is a question, it's likely requesting database info
  return hasDbKeyword && isQuestion;
}

/**
 * Creates a structured prompt for the recommendation generation
 */
function createRecommendationPrompt(reportData: ReportDataInput): string {
  const vehicleInfo = reportData.carData ? 
    `${reportData.carData.year || ''} ${reportData.carData.make || ''} ${reportData.carData.model || ''}`.trim() : 
    'Vehicle';
  
  let prompt = `Based on the inspection of a ${vehicleInfo}, please provide professional service recommendations. Include maintenance schedule advice and prioritize repairs.\n\n`;
  
  // Add findings with urgency levels
  if (reportData.inspectionFindings && reportData.inspectionFindings.length > 0) {
    prompt += "Inspection findings:\n";
    reportData.inspectionFindings.forEach(finding => {
      prompt += `- ${finding.finding} (Urgency: ${finding.argancy})\n`;
    });
    prompt += "\n";
  }
  
  // Add test drive observations
  if (reportData.testDriveObservations && reportData.testDriveObservations.length > 0) {
    prompt += "Test drive observations:\n";
    reportData.testDriveObservations.forEach(observation => {
      prompt += `- ${observation.observation} (Urgency: ${observation.argancy})\n`;
    });
    prompt += "\n";
  }
  
  // Add client requests
  if (reportData.clientRequests && reportData.clientRequests.length > 0) {
    prompt += "Client requests:\n";
    reportData.clientRequests.forEach(request => {
      prompt += `- ${request.request} (Urgency: ${request.argancy})\n`;
    });
    prompt += "\n";
  }
  
  // Add notes
  if (reportData.inspectionNotes) {
    prompt += `Inspection notes: ${reportData.inspectionNotes}\n\n`;
  }
  
  if (reportData.testDriveNotes) {
    prompt += `Test drive notes: ${reportData.testDriveNotes}\n\n`;
  }
  
  prompt += "Provide a professional recommendation for servicing and maintenance, prioritizing safety-critical items first. Keep your response under 100 words.";
  
  return prompt;
}

/**
 * Creates a structured prompt for the summary generation
 */
function createSummaryPrompt(reportData: ReportDataInput): string {
  const vehicleInfo = reportData.carData ? 
    `${reportData.carData.year || ''} ${reportData.carData.make || ''} ${reportData.carData.model || ''}`.trim() : 
    'Vehicle';
  
  let prompt = `Summarize the inspection findings for a ${vehicleInfo}. Create a concise and professional summary.\n\n`;
  
  // Add findings with urgency levels
  if (reportData.inspectionFindings && reportData.inspectionFindings.length > 0) {
    prompt += "Inspection findings:\n";
    reportData.inspectionFindings.forEach(finding => {
      prompt += `- ${finding.finding} (Urgency: ${finding.argancy})\n`;
    });
    prompt += "\n";
  }
  
  // Add test drive observations
  if (reportData.testDriveObservations && reportData.testDriveObservations.length > 0) {
    prompt += "Test drive observations:\n";
    reportData.testDriveObservations.forEach(observation => {
      prompt += `- ${observation.observation} (Urgency: ${observation.argancy})\n`;
    });
    prompt += "\n";
  }
  
  // Add notes
  if (reportData.inspectionNotes) {
    prompt += `Inspection notes: ${reportData.inspectionNotes}\n\n`;
  }
  
  if (reportData.testDriveNotes) {
    prompt += `Test drive notes: ${reportData.testDriveNotes}\n\n`;
  }
  
  prompt += "Provide a concise, professional summary of the overall vehicle condition and key findings. Keep your response under 100 words.";
  
  return prompt;
}