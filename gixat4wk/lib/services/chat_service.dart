import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import 'error_service.dart';

class ChatService extends GetxService {
  // Base URL for the API
  String _baseUrl;
  final ErrorService _errorService = Get.find<ErrorService>(
    tag: 'ErrorService',
  );
  final uuid = const Uuid();

  // Observable lists for reactive UI updates
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxList<ChatSession> sessions = <ChatSession>[].obs;
  final RxBool isLoading = false.obs;

  // Current active session
  final Rx<ChatSession?> currentSession = Rx<ChatSession?>(null);

  // HTTP client with longer timeout
  final http.Client _client = http.Client();

  ChatService({String? baseUrl})
    : _baseUrl = baseUrl ?? 'http://192.168.0.156:3000';

  // Initialize the service
  Future<ChatService> init() async {
    try {
      // Load any saved sessions from local storage
      await _loadSavedSessions();

      // Try to load saved domain configuration
      await _loadDomainConfig();

      // Validate the API endpoint
      await _validateApiEndpoint();

      return this;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ChatService.init',
        stackTrace: stackTrace,
      );
      return this;
    }
  }

  // Validate API endpoint
  Future<void> _validateApiEndpoint() async {
    try {
      debugPrint('Validating API endpoint: $_baseUrl/api/ai/chatbot');
      final testRequest = await _client
          .get(
            Uri.parse('$_baseUrl/api/ai'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (testRequest.statusCode >= 400) {
        debugPrint(
          'API endpoint validation failed with status: ${testRequest.statusCode}',
        );
        // If production URL fails, try fallback to development
        if (_baseUrl.contains('4wk.ae')) {
          _baseUrl = 'http://192.168.0.156:3000';
          await setBaseUrl(_baseUrl);
        }
      } else {
        debugPrint('API endpoint validation succeeded');
      }
    } catch (e) {
      debugPrint('API endpoint validation error: $e');
      // If production URL fails with an error, try fallback to development
      if (_baseUrl.contains('4wk.ae')) {
        _baseUrl = 'http://192.168.0.156:3000';
        await setBaseUrl(_baseUrl);
      }
    }
  }

  // Send a message to the chatbot
  Future<ChatMessage?> sendMessage(String message, {String? sessionId}) async {
    try {
      isLoading.value = true;

      // Use provided sessionId or current session's id
      final String currentSessionId =
          sessionId ?? currentSession.value?.id ?? uuid.v4();

      // If no current session, create one
      if (currentSession.value == null) {
        currentSession.value = ChatSession(
          id: currentSessionId,
          name: 'AI Assistant',
          lastMessageTime: DateTime.now(),
          lastMessageText: message,
        );

        sessions.add(currentSession.value!);
        _saveSessions();
      }

      // Create user message
      final userMessage = ChatMessage(
        id: uuid.v4(),
        text: message,
        timestamp: DateTime.now(),
        isUserMessage: true,
        sessionId: currentSessionId,
      );

      // Add user message to list
      messages.add(userMessage);

      // Save messages after adding user message
      await _saveMessages(currentSessionId);

      // Prepare request payload
      final payload = jsonEncode({
        'sessionId': currentSessionId,
        'message': message,
      });

      debugPrint('Sending request to: $_baseUrl/api/ai/chatbot');
      debugPrint('Payload: $payload');

      // Call API with longer timeout
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/ai/chatbot'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.body.isNotEmpty) {
        try {
          final responseData = jsonDecode(response.body);
          debugPrint('Parsed response data: $responseData');

          // Extract the bot's response text
          String? botResponseText;

          // Check for 'reply' field in response
          if (responseData.containsKey('reply')) {
            botResponseText = responseData['reply'] as String?;
            debugPrint('Found reply in response: $botResponseText');

            // Check for database info
            if (responseData.containsKey('databaseInfo')) {}
          }
          // Fallback to 'response' field (original format)
          else if (responseData.containsKey('response')) {
            botResponseText = responseData['response'] as String?;
            debugPrint('Found response in response: $botResponseText');
          }
          // Try to extract from messages array if available
          else if (responseData.containsKey('messages') &&
              responseData['messages'] is List) {
            final msgList = responseData['messages'] as List;
            for (final msg in msgList) {
              if (msg is Map &&
                  msg.containsKey('role') &&
                  msg['role'] == 'assistant' &&
                  msg.containsKey('content')) {
                botResponseText = msg['content'] as String?;
                debugPrint('Found assistant message: $botResponseText');
                break;
              }
            }
          }

          if (botResponseText == null || botResponseText.isEmpty) {
            throw Exception(
              'Could not find a valid response in the API result: $responseData',
            );
          }

          // Create and add bot message
          final botMessage = ChatMessage(
            id: uuid.v4(),
            text: botResponseText,
            timestamp: DateTime.now(),
            isUserMessage: false,
            sessionId: currentSessionId,
            // Adding databaseInfo only if it's actually available
            databaseInfo:
                responseData.containsKey('databaseInfo')
                    ? responseData['databaseInfo'] as Map<String, dynamic>?
                    : null,
          );

          // Add bot message to list
          messages.add(botMessage);

          // Save messages after adding bot response
          await _saveMessages(currentSessionId);

          // Update session with latest message
          _updateSessionWithLatestMessage(
            currentSessionId,
            botMessage.text,
            botMessage.timestamp,
          );

          return botMessage;
        } catch (e) {
          debugPrint('Error parsing response: $e');
          rethrow;
        }
      } else {
        // Handle error response
        throw HttpException('API returned status ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ChatService.sendMessage',
        stackTrace: stackTrace,
      );

      // Determine appropriate error message based on exception type
      String errorMessage;
      if (e is SocketException || e is http.ClientException) {
        errorMessage =
            'Network connection error. Please check your internet connection and try again.';
      } else if (e is TimeoutException) {
        errorMessage =
            'Request timed out. The server might be busy, please try again later.';
      } else if (e is FormatException) {
        errorMessage =
            'Couldn\'t process the response from the server. Please try again.';
      } else {
        errorMessage =
            'Sorry, there was an error processing your request. Please try again.';
      }

      // Add error message to chat
      final errorChatMessage = ChatMessage(
        id: uuid.v4(),
        text: errorMessage,
        timestamp: DateTime.now(),
        isUserMessage: false,
        sessionId: sessionId ?? currentSession.value?.id ?? '',
      );

      messages.add(errorChatMessage);
      if (sessionId != null || currentSession.value != null) {
        await _saveMessages(sessionId ?? currentSession.value!.id);
      }

      return errorChatMessage;
    } finally {
      isLoading.value = false;
    }
  }

  // Select a specific chat session
  Future<void> selectSession(String sessionId) async {
    try {
      // Find the session in our list
      ChatSession? session;
      try {
        session = sessions.firstWhere((s) => s.id == sessionId);
      } catch (e) {
        debugPrint('Session not found: $sessionId');
        return;
      }

      // Use Future.microtask to schedule the state update outside of the build phase
      Future.microtask(() {
        // Update current session
        currentSession.value = session;

        // Clear unread count
        final updatedSession = ChatSession(
          id: session!.id,
          name: session.name,
          avatarUrl: session.avatarUrl,
          lastMessageTime: session.lastMessageTime,
          lastMessageText: session.lastMessageText,
          unreadCount: 0,
        );

        final index = sessions.indexWhere((s) => s.id == sessionId);
        if (index != -1) {
          sessions[index] = updatedSession;
          _saveSessions();
        }
      });

      // Load messages for this session - this is async so won't interfere with build
      await _loadMessages(sessionId);
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ChatService.selectSession',
        stackTrace: stackTrace,
      );
    }
  }

  // Create a new chat session
  ChatSession createNewSession() {
    final newSession = ChatSession(
      id: uuid.v4(),
      name: 'AI Assistant',
      lastMessageTime: DateTime.now(),
      lastMessageText: 'How can I help you today?',
    );

    sessions.add(newSession);
    currentSession.value = newSession;
    _saveSessions();

    messages.clear();
    return newSession;
  }

  // Update session with latest message
  void _updateSessionWithLatestMessage(
    String sessionId,
    String message,
    DateTime timestamp,
  ) {
    final index = sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final oldSession = sessions[index];
      final unreadCount =
          oldSession.id == currentSession.value?.id
              ? 0
              : oldSession.unreadCount + 1;

      final updatedSession = ChatSession(
        id: oldSession.id,
        name: oldSession.name,
        avatarUrl: oldSession.avatarUrl,
        lastMessageTime: timestamp,
        lastMessageText: message,
        unreadCount: unreadCount,
      );

      sessions[index] = updatedSession;

      // If this is the current session, update it
      if (oldSession.id == currentSession.value?.id) {
        currentSession.value = updatedSession;
      }

      _saveSessions();
    }
  }

  // Load saved sessions from SharedPreferences
  Future<void> _loadSavedSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('chat_sessions');

      if (sessionsJson != null) {
        final List<dynamic> sessionsList = jsonDecode(sessionsJson);
        final loadedSessions =
            sessionsList.map((s) => ChatSession.fromMap(s)).toList();

        sessions.value = loadedSessions;

        // If there was a current session, try to restore it
        final currentSessionId = prefs.getString('current_session_id');
        if (currentSessionId != null) {
          final index = sessions.indexWhere((s) => s.id == currentSessionId);
          if (index != -1) {
            currentSession.value = sessions[index];
            _loadMessages(currentSessionId);
          }
        }
      }
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ChatService._loadSavedSessions',
        stackTrace: stackTrace,
      );
    }
  }

  // Save sessions to SharedPreferences
  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = jsonEncode(sessions.map((s) => s.toMap()).toList());
      await prefs.setString('chat_sessions', sessionsJson);

      // Save current session id if exists
      if (currentSession.value != null) {
        await prefs.setString('current_session_id', currentSession.value!.id);
      }
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ChatService._saveSessions',
        stackTrace: stackTrace,
      );
    }
  }

  // Load messages for a specific session
  Future<void> _loadMessages(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('messages_$sessionId');

      if (messagesJson != null) {
        final List<dynamic> messagesList = jsonDecode(messagesJson);
        final loadedMessages =
            messagesList.map((m) => ChatMessage.fromMap(m)).toList();

        messages.value = loadedMessages;
      } else {
        messages.clear();
      }
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ChatService._loadMessages',
        stackTrace: stackTrace,
      );
    }
  }

  // Save messages for a specific session
  Future<void> _saveMessages(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionMessages =
          messages.where((m) => m.sessionId == sessionId).toList();
      final messagesJson = jsonEncode(
        sessionMessages.map((m) => m.toMap()).toList(),
      );
      await prefs.setString('messages_$sessionId', messagesJson);
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ChatService._saveMessages',
        stackTrace: stackTrace,
      );
    }
  }

  // Set the base URL and save it
  Future<void> setBaseUrl(String url) async {
    try {
      _baseUrl = url;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_api_url', url);
      debugPrint('Chat API URL updated to: $url');
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ChatService.setBaseUrl',
        stackTrace: stackTrace,
      );
    }
  }

  // Load domain configuration
  Future<void> _loadDomainConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('chat_api_url');

      if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = savedUrl;
        debugPrint('Chat API URL loaded from storage: $_baseUrl');
      } else if (_baseUrl.contains('192.168.0.156')) {
        // Check if we should update to production URL (4wk.ae)
        final bool isProduction =
            true; // You may want to determine this based on build config
        if (isProduction) {
          _baseUrl = 'https://4wk.ae';
          await setBaseUrl(_baseUrl);
        }
      }
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ChatService._loadDomainConfig',
        stackTrace: stackTrace,
      );
    }
  }

  // Get current base URL
  String get baseUrl => _baseUrl;

  @override
  void onClose() {
    // Close HTTP client when service is disposed
    _client.close();
    super.onClose();
  }
}
