import { 
  getFirestore, 
  collection, 
  query, 
  where, 
  getDocs, 
  doc, 
  getDoc, 
  updateDoc, 
  serverTimestamp,
  limit,
  Timestamp,
  addDoc
} from 'firebase/firestore';
import app from '../firebase';
import { processChatMessage, ChatMessage, ChatbotResponse } from './openai.service';
import { ReportData } from './firebase.service';

// Initialize Firestore
const db = getFirestore(app);

/**
 * Interface for chat history document in Firestore
 */
export interface ChatHistoryDocument {
  id?: string;
  sessionId: string;
  userId?: string; // Optional, can link to a user account
  clientId?: string; // Optional, can link to a client
  messages: ChatMessage[];
  createdAt: Timestamp | Date;
  updatedAt: Timestamp | Date;
  metadata?: {
    userAgent?: string;
    ipAddress?: string;
    lastTopic?: string;
    lastInteraction?: string;
    wasCleared?: boolean;
    clearedAt?: string;
  };
}

// Local cache to improve performance and reduce database reads
const chatSessionCache: Map<string, ChatHistoryDocument> = new Map();
// Expiry time for cache items in milliseconds (5 minutes)
const CACHE_EXPIRY = 5 * 60 * 1000;
// Cache metadata for tracking when items were added
const cacheTimestamps: Map<string, number> = new Map();

/**
 * Handle a chat message and maintain session history in both cache and database
 * @param sessionId Unique identifier for the chat session
 * @param message The user's message
 * @param userId Optional user ID to associate with this chat
 * @param clientId Optional client ID to associate with this chat
 * @returns The chatbot's response
 */
export const handleChatMessage = async (
  sessionId: string, 
  message: string,
  userId?: string,
  clientId?: string
): Promise<ChatbotResponse> => {
  try {
    console.log(`Processing message for session ${sessionId}: ${message}`);
    
    // Get session from cache or database
    let chatHistory = await getChatHistoryDocument(sessionId);
    let isNewSession = false;
    
    // If no session exists, create a new one
    if (!chatHistory) {
      console.log(`Creating new chat session: ${sessionId}`);
      isNewSession = true;
      chatHistory = {
        sessionId,
        messages: [],
        createdAt: new Date(),
        updatedAt: new Date(),
        ...(userId && { userId }),
        ...(clientId && { clientId }),
        metadata: {
          lastInteraction: new Date().toISOString()
        }
      };
    }
    
    // Check if the message might need database access
    const dbData = await retrieveRelevantDatabaseData(message);
    
    // Process the message with OpenAI and any database context
    const response = await processChatMessage(chatHistory.messages, message, dbData);
    
    // Update session with the new message pair
    chatHistory.messages.push(
      { role: 'user', content: message },
      { role: 'assistant', content: response.reply }
    );
    
    // Keep only the last 20 messages to prevent context size issues
    if (chatHistory.messages.length > 20) {
      chatHistory.messages = chatHistory.messages.slice(-20);
    }
    
    // Update the timestamp
    chatHistory.updatedAt = new Date();
    
    // Update metadata
    if (!chatHistory.metadata) {
      chatHistory.metadata = {};
    }
    chatHistory.metadata.lastInteraction = new Date().toISOString();
    
    // Save to database
    await saveChatHistory(chatHistory, isNewSession);
    
    // Update cache
    updateChatHistoryCache(sessionId, chatHistory);
    
    return response;
  } catch (error) {
    console.error('Error handling chat message:', error);
    return {
      reply: "I'm sorry, I encountered an error processing your request. Please try again later.",
      error: error instanceof Error ? error.message : "Unknown error"
    };
  }
};

/**
 * Retrieve chat history document for a specific session from cache or Firestore
 * @param sessionId The chat session ID
 * @returns ChatHistoryDocument or null if not found
 */
async function getChatHistoryDocument(sessionId: string): Promise<ChatHistoryDocument | null> {
  try {
    // Clean expired cache items 
    cleanExpiredCacheItems();
    
    // Check cache first
    if (chatSessionCache.has(sessionId)) {
      console.log(`Chat history found in cache for session: ${sessionId}`);
      return chatSessionCache.get(sessionId) || null;
    }
    
    // Not in cache, query Firestore
    console.log(`Querying database for chat history: ${sessionId}`);
    const chatHistoryRef = collection(db, 'chatHistories');
    const q = query(chatHistoryRef, where('sessionId', '==', sessionId), limit(1));
    const querySnapshot = await getDocs(q);
    
    if (querySnapshot.empty) {
      console.log(`No chat history found for session: ${sessionId}`);
      return null;
    }
    
    // Get the document data
    const docSnapshot = querySnapshot.docs[0];
    const data = docSnapshot.data() as ChatHistoryDocument;
    
    // Update with ID
    data.id = docSnapshot.id;
    
    // Add to cache
    updateChatHistoryCache(sessionId, data);
    
    return data;
  } catch (error) {
    console.error(`Error retrieving chat history for ${sessionId}:`, error);
    return null;
  }
}

/**
 * Save chat history to Firestore
 * @param chatHistory The chat history document to save
 * @param isNew Whether this is a new document or an update
 */
async function saveChatHistory(chatHistory: ChatHistoryDocument, isNew: boolean = false): Promise<void> {
  try {
    const chatHistoryRef = collection(db, 'chatHistories');
    
    // Make sure we have valid metadata to prevent Firebase errors
    const metadata = chatHistory.metadata || {};
    
    if (isNew || !chatHistory.id) {
      // Create new document
      const docRef = await addDoc(chatHistoryRef, {
        sessionId: chatHistory.sessionId,
        messages: chatHistory.messages,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        ...(chatHistory.userId && { userId: chatHistory.userId }),
        ...(chatHistory.clientId && { clientId: chatHistory.clientId }),
        metadata: metadata
      });
      
      // Update the ID in our object
      chatHistory.id = docRef.id;
      console.log(`Created new chat history with ID: ${docRef.id}`);
    } else {
      // Update existing document
      const docRef = doc(db, 'chatHistories', chatHistory.id);
      await updateDoc(docRef, {
        messages: chatHistory.messages,
        updatedAt: serverTimestamp(),
        metadata: metadata
      });
      
      console.log(`Updated chat history with ID: ${chatHistory.id}`);
    }
  } catch (error) {
    console.error('Error saving chat history:', error);
    throw error;
  }
}

/**
 * Update the in-memory cache with a chat history document
 * @param sessionId Session ID as the cache key
 * @param chatHistory Chat history document
 */
function updateChatHistoryCache(sessionId: string, chatHistory: ChatHistoryDocument): void {
  chatSessionCache.set(sessionId, chatHistory);
  cacheTimestamps.set(sessionId, Date.now());
}

/**
 * Clean expired items from the cache to prevent memory leaks
 */
function cleanExpiredCacheItems(): void {
  const now = Date.now();
  for (const [sessionId, timestamp] of cacheTimestamps.entries()) {
    if (now - timestamp > CACHE_EXPIRY) {
      chatSessionCache.delete(sessionId);
      cacheTimestamps.delete(sessionId);
    }
  }
}

/**
 * Retrieve chat history for a specific session
 * @param sessionId The chat session ID
 * @returns Array of chat messages or empty array if session not found
 */
export const getChatHistory = async (sessionId: string): Promise<ChatMessage[]> => {
  try {
    const chatHistory = await getChatHistoryDocument(sessionId);
    return chatHistory?.messages || [];
  } catch (error) {
    console.error(`Error retrieving chat history for ${sessionId}:`, error);
    return [];
  }
};

/**
 * Clear chat history for a specific session
 * @param sessionId The chat session ID
 */
export const clearChatHistory = async (sessionId: string): Promise<void> => {
  try {
    // Remove from cache
    chatSessionCache.delete(sessionId);
    cacheTimestamps.delete(sessionId);
    
    // Get the document reference
    const chatHistoryRef = collection(db, 'chatHistories');
    const q = query(chatHistoryRef, where('sessionId', '==', sessionId), limit(1));
    const querySnapshot = await getDocs(q);
    
    if (!querySnapshot.empty) {
      const docId = querySnapshot.docs[0].id;
      const docData = querySnapshot.docs[0].data();
      // Update the document to have empty messages array but don't delete it
      const docRef = doc(db, 'chatHistories', docId);
      
      // Make sure we have valid metadata
      const metadata = docData.metadata || {};
      
      await updateDoc(docRef, {
        messages: [],
        updatedAt: serverTimestamp(),
        metadata: {
          ...metadata,
          wasCleared: true,
          clearedAt: new Date().toISOString()
        }
      });
      
      console.log(`Cleared chat history for session ${sessionId}`);
    }
  } catch (error) {
    console.error(`Error clearing chat history for ${sessionId}:`, error);
    throw error;
  }
}

/**
 * Define types for database data to replace 'any'
 */
interface DatabaseData {
  type?: string;
  [key: string]: unknown;
}

/**
 * Type for database query results that might be arrays
 */
type DatabaseQueryResult = DatabaseData | Record<string, unknown>[] | null;

/**
 * Retrieve relevant database data based on the message content
 * @param message The user's message
 * @returns Relevant data or null if no specific data is found
 */
async function retrieveRelevantDatabaseData(message: string): Promise<DatabaseQueryResult> {
  // Convert message to lowercase for easier comparison
  const lowerMessage = message.toLowerCase();
  
  try {
    // Check for mechanic-specific queries
    if (containsTerms(lowerMessage, ['diagnostic', 'error code', 'check engine', 'obd', 'dtc', 'warning light', 'sensor'])) {
      return await findDiagnosticData(lowerMessage);
    }
    
    if (containsTerms(lowerMessage, ['repair', 'fix', 'replace', 'install', 'remove', 'service', 'maintenance'])) {
      return await findRepairProcedures(lowerMessage);
    }
    
    if (containsTerms(lowerMessage, ['symptom', 'noise', 'vibration', 'leak', 'smoke', 'overheat', 'coolant', 'oil', 'brake'])) {
      return await findTroubleshootingGuides(lowerMessage);
    }
    
    // Still check for vehicle data, as it's relevant for mechanics
    if (containsTerms(lowerMessage, ['vehicle', 'car', 'automobile', 'make', 'model', 'engine', 'transmission'])) {
      return await findRelevantVehicleData(lowerMessage); 
    }
    
    if (containsTerms(lowerMessage, ['report', 'inspection', 'finding', 'diagnosis'])) {
      return await findRelevantReportData(lowerMessage);
    }
    
    // If no specific data is requested, return null
    return null;
  } catch (error) {
    console.error('Error retrieving database data:', error);
    return null;
  }
}

/**
 * Helper function to check if message contains any terms from an array
 */
function containsTerms(message: string, terms: string[]): boolean {
  return terms.some(term => message.includes(term));
}

/**
 * Extract potential identifiers from a message (like names, IDs, etc.)
 */
function extractIdentifiers(message: string): string[] {
  const identifiers: string[] = [];
  
  // Look for patterns that might be names (capitalized words)
  const namePattern = /\b[A-Z][a-z]+(?:\s[A-Z][a-z]+)+\b/g;
  const names = message.match(namePattern);
  if (names) identifiers.push(...names);
  
  // Look for patterns that might be IDs (alphanumeric sequences)
  const idPattern = /\b[a-zA-Z0-9]{6,}\b/g;
  const ids = message.match(idPattern);
  if (ids) identifiers.push(...ids);
  
  // Look for anything that might be a phone number
  const phonePattern = /\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b/g;
  const phones = message.match(phonePattern);
  if (phones) identifiers.push(...phones);
  
  return identifiers;
}

/**
 * Find relevant vehicle data based on message content
 */
async function findRelevantVehicleData(message: string): Promise<DatabaseQueryResult> {
  const identifiers = extractIdentifiers(message);
  
  // Extract potential vehicle make/model combinations
  const vehicleMakes = ['toyota', 'honda', 'ford', 'chevrolet', 'bmw', 'mercedes', 'audi', 'volkswagen', 'nissan', 'subaru'];
  const foundMakes = vehicleMakes.filter(make => message.toLowerCase().includes(make));
  
  const carsCollection = collection(db, 'cars');
  
  // Try to find vehicles by make if any were mentioned
  if (foundMakes.length > 0) {
    for (const make of foundMakes) {
      const carQuery = query(
        carsCollection,
        where('make', '==', make.charAt(0).toUpperCase() + make.slice(1)), // Capitalize the make
        limit(3)
      );
      
      const querySnapshot = await getDocs(carQuery);
      if (!querySnapshot.empty) {
        // Return an object that wraps the array
        return {
          type: 'vehicles',
          data: querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))
        };
      }
    }
  }
  
  // Try to find vehicles by the extracted identifiers (like VIN, plate number)
  if (identifiers.length > 0) {
    for (const identifier of identifiers) {
      // Try by VIN
      let carQuery = query(
        carsCollection,
        where('vin', '==', identifier),
        limit(1)
      );
      
      let querySnapshot = await getDocs(carQuery);
      if (!querySnapshot.empty) {
        return {
          type: 'vehicles',
          data: querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))
        };
      }
      
      // Try by plate number
      carQuery = query(
        carsCollection,
        where('plateNumber', '==', identifier),
        limit(1)
      );
      
      querySnapshot = await getDocs(carQuery);
      if (!querySnapshot.empty) {
        return {
          type: 'vehicles',
          data: querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))
        };
      }
    }
  }
  
  return null;
}

/**
 * Find relevant report data based on message content
 */
async function findRelevantReportData(message: string): Promise<DatabaseQueryResult> {
  const identifiers = extractIdentifiers(message);
  if (identifiers.length === 0) {
    // If no specific identifiers, return the most recent reports
    const reportsCollection = collection(db, 'reports');
    const reportsQuery = query(reportsCollection, limit(3));
    const querySnapshot = await getDocs(reportsQuery);
    
    if (!querySnapshot.empty) {
      return {
        type: 'reports',
        data: querySnapshot.docs.map(doc => {
          const data = doc.data() as ReportData;
          // Return simplified report data to avoid large responses
          return {
            id: doc.id,
            carInfo: data.carData?.make + ' ' + data.carData?.model + ' (' + data.carData?.year + ')',
            clientName: data.clientData?.name,
            findings: data.inspectionFindings?.map(f => f.finding) || [],
            createdAt: data.createdAt
          };
        })
      };
    }
    
    return null;
  }
  
  // Try to find reports by sessionId or other identifier
  for (const identifier of identifiers) {
    try {
      // Try to get the report directly by ID
      const reportRef = doc(db, 'reports', identifier);
      const reportSnap = await getDoc(reportRef);
      
      if (reportSnap.exists()) {
        const data = reportSnap.data() as ReportData;
        // Return simplified report data to avoid large responses
        return {
          type: 'report',
          id: reportSnap.id,
          carInfo: data.carData?.make + ' ' + data.carData?.model + ' (' + data.carData?.year + ')',
          clientName: data.clientData?.name,
          findings: data.inspectionFindings?.map(f => f.finding) || [],
          observations: data.testDriveObservations?.map(o => o.observation) || [],
          recommendations: data.recommendations,
          summary: data.summary,
          createdAt: data.createdAt
        };
      }
    } catch (error) {
      console.error(`Error querying for report ${identifier}:`, error);
      // Continue to next identifier if there's an error
    }
  }
  
  return null;
}

/**
 * Find diagnostic data related to error codes and diagnostic trouble codes (DTCs)
 * @param message The user's message with potential diagnostic codes
 * @returns Diagnostic information or null if nothing found
 */
async function findDiagnosticData(message: string): Promise<DatabaseData | null> {
  try {
    // Extract potential error codes - common formats like P0123, B1234, C0123, etc.
    const dtcPattern = /\b[PCBU][0-9]{4}\b/gi;
    const dtcCodes = message.match(dtcPattern) || [];
    
    if (dtcCodes.length > 0) {
      const diagnosticsCollection = collection(db, 'diagnostics');
      
      // Search for each code
      for (const code of dtcCodes) {
        const codeQuery = query(
          diagnosticsCollection, 
          where('code', '==', code.toUpperCase()),
          limit(1)
        );
        
        const querySnapshot = await getDocs(codeQuery);
        if (!querySnapshot.empty) {
          return {
            type: 'diagnostic',
            codes: dtcCodes,
            results: querySnapshot.docs.map(doc => ({
              id: doc.id,
              ...doc.data()
            }))
          };
        }
      }
      
      // If we didn't find any specific codes in our database
      return {
        type: 'diagnostic',
        codes: dtcCodes,
        note: 'Diagnostic codes detected but specific details not found in database. Responding with general information.'
      };
    }
    
    // Look for general diagnostic system descriptions
    if (containsTerms(message, ['check engine light', 'warning light', 'dashboard light'])) {
      // Return general information about warning lights
      return {
        type: 'diagnostic_general',
        system: 'warning_lights',
        generalInfo: 'Warning light troubleshooting information needed'
      };
    }
    
    return null;
  } catch (error) {
    console.error('Error searching for diagnostic data:', error);
    return null;
  }
}

/**
 * Find repair procedures based on user message
 * @param message The user message possibly containing repair-related terms
 * @returns Repair procedure information or null if nothing relevant found
 */
async function findRepairProcedures(message: string): Promise<DatabaseData | null> {
  try {
    // Extract vehicle-related terms to narrow down the repair procedures
    const vehicleMakes = ['toyota', 'honda', 'ford', 'chevrolet', 'bmw', 'mercedes', 'audi', 'volkswagen', 'nissan', 'subaru'];
    const vehicleSystems = ['engine', 'transmission', 'brake', 'suspension', 'cooling', 'electrical', 'steering', 'fuel', 'exhaust'];
    
    const detectedMakes = vehicleMakes.filter(make => message.toLowerCase().includes(make));
    const detectedSystems = vehicleSystems.filter(system => message.toLowerCase().includes(system));
    
    // Look for common repair procedure terms
    const repairActions = ['replace', 'repair', 'rebuild', 'install', 'remove', 'service', 'reset', 'adjust', 'calibrate'];
    const detectedActions = repairActions.filter(action => message.toLowerCase().includes(action));
    
    const repairCollection = collection(db, 'repairProcedures');
    let procedureQuery;
    
    // Build query based on detected terms
    if (detectedSystems.length > 0 && detectedActions.length > 0) {
      procedureQuery = query(
        repairCollection,
        where('system', '==', detectedSystems[0]),
        where('actionType', '==', detectedActions[0]),
        limit(3)
      );
      
      const querySnapshot = await getDocs(procedureQuery);
      if (!querySnapshot.empty) {
        return {
          type: 'repair_procedure',
          system: detectedSystems[0],
          action: detectedActions[0],
          procedures: querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
          }))
        };
      }
    }
    
    // If no specific procedures found, check for general maintenance procedures
    if (message.includes('maintenance') || message.includes('service')) {
      procedureQuery = query(
        repairCollection, 
        where('category', '==', 'maintenance'),
        limit(3)
      );
      
      const querySnapshot = await getDocs(procedureQuery);
      if (!querySnapshot.empty) {
        return {
          type: 'maintenance_procedure',
          procedures: querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
          }))
        };
      }
    }
    
    return {
      type: 'repair_general',
      detectedSystems,
      detectedActions,
      detectedMakes,
      note: 'Technical repair information needed but specific procedures not found in database.'
    };
  } catch (error) {
    console.error('Error searching for repair procedures:', error);
    return null;
  }
}

/**
 * Find troubleshooting guides related to vehicle symptoms
 * @param message The user message with potential symptom descriptions
 * @returns Troubleshooting information or null if nothing relevant found
 */
async function findTroubleshootingGuides(message: string): Promise<DatabaseData | null> {
  try {
    // Define common symptom categories to look for
    const symptomCategories = [
      { name: 'noise', terms: ['noise', 'sound', 'knock', 'rattle', 'squeal', 'hiss', 'clunk'] },
      { name: 'vibration', terms: ['vibration', 'shake', 'shimmy', 'wobble'] },
      { name: 'fluid_leak', terms: ['leak', 'drip', 'puddle', 'oil', 'coolant', 'transmission fluid', 'brake fluid'] },
      { name: 'smell', terms: ['smell', 'odor', 'burning'] },
      { name: 'performance', terms: ['stall', 'hesitation', 'rough idle', 'misfire', 'backfire', 'no start', 'hard start'] },
      { name: 'temperature', terms: ['overheat', 'temperature', 'hot', 'cold', 'fan'] },
      { name: 'electrical', terms: ['battery', 'alternator', 'starter', 'spark', 'fuse', 'light', 'short'] }
    ];
    
    // Detect which symptom categories are in the message
    const detectedSymptoms = symptomCategories
      .filter(category => category.terms.some(term => message.toLowerCase().includes(term)))
      .map(category => category.name);
    
    if (detectedSymptoms.length > 0) {
      const troubleshootingCollection = collection(db, 'troubleshootingGuides');
      
      // Query for guides related to the first detected symptom
      const guideQuery = query(
        troubleshootingCollection,
        where('symptomCategory', '==', detectedSymptoms[0]),
        limit(3)
      );
      
      const querySnapshot = await getDocs(guideQuery);
      if (!querySnapshot.empty) {
        return {
          type: 'troubleshooting',
          symptomCategory: detectedSymptoms[0],
          guides: querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
          }))
        };
      }
      
      // Return detected symptoms even if no specific guides found
      return {
        type: 'troubleshooting_general',
        detectedSymptoms,
        note: 'Symptom analysis needed but specific troubleshooting guides not found in database.'
      };
    }
    
    return null;
  } catch (error) {
    console.error('Error searching for troubleshooting guides:', error);
    return null;
  }
}