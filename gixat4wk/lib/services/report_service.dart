import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch client notes data
  Future<Map<String, dynamic>?> getClientNotes(String clientNotesId) async {
    if (clientNotesId.isEmpty) return null;

    try {
      final doc =
          await _firestore.collection('jobCard').doc(clientNotesId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching client notes: $e');
    }

    return null;
  }

  // Fetch inspection data
  Future<Map<String, dynamic>?> getInspection(String inspectionId) async {
    if (inspectionId.isEmpty) return null;

    try {
      final doc =
          await _firestore.collection('jobCard').doc(inspectionId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching inspection: $e');
    }

    return null;
  }

  // Fetch test drive data
  Future<Map<String, dynamic>?> getTestDrive(String testDriveId) async {
    if (testDriveId.isEmpty) return null;

    try {
      final doc = await _firestore.collection('jobCard').doc(testDriveId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching test drive: $e');
    }

    return null;
  }

  // Fetch existing report
  Future<Map<String, dynamic>?> getReport(String reportId) async {
    if (reportId.isEmpty) return null;

    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching report: $e');
    }

    return null;
  }

  // Save a new report
  Future<String> saveReport({
    required String sessionId,
    required String carId,
    required String clientId,
    required Map<String, dynamic> clientData,
    required Map<String, dynamic> carData,
    required Map<String, dynamic> reportData,
  }) async {
    try {
      final now = DateTime.now();

      // Create the report document with all data
      final Map<String, dynamic> fullReport = {
        'sessionId': sessionId,
        'carId': carId,
        'clientId': clientId,
        'clientData': clientData,
        'carData': carData,
        ...reportData,
        'createdAt': now,
        'updatedAt': now,
      };

      // Add document to Firestore
      final docRef = await _firestore.collection('reports').add(fullReport);

      // Add activity record
      await _firestore.collection('activity').add({
        'sessionId': sessionId,
        'title': 'Report created',
        'timestamp': now,
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error saving report: $e');
      throw Exception('Failed to save report: $e');
    }
  }

  // Update an existing report
  Future<void> updateReport({
    required String reportId,
    required String sessionId,
    required Map<String, dynamic> clientData,
    required Map<String, dynamic> carData,
    required Map<String, dynamic> reportData,
  }) async {
    try {
      final now = DateTime.now();

      // Update the report document
      final Map<String, dynamic> updateData = {
        'clientData': clientData,
        'carData': carData,
        ...reportData,
        'updatedAt': now,
      };

      await _firestore.collection('reports').doc(reportId).update(updateData);

      // Add activity record
      await _firestore.collection('activity').add({
        'sessionId': sessionId,
        'title': 'Report updated',
        'timestamp': now,
      });
    } catch (e) {
      debugPrint('Error updating report: $e');
      throw Exception('Failed to update report: $e');
    }
  }

  // Generate AI content for report summary and recommendations
  Future<Map<String, dynamic>> generateAIContent(
    String reportId, {
    bool updateFirebase = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://4wk.ae/api/ai/generate'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'reportId': reportId,
          'updateFirebase': updateFirebase,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Log the result
        debugPrint(
          'AI content generated successfully: ${result.toString().substring(0, min(100, result.toString().length))}...',
        );

        return result;
      } else {
        throw Exception('Failed to generate AI content: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error generating AI content: $e');
      throw Exception('Failed to generate AI content: $e');
    }
  }
}

// Helper for string truncation
int min(int a, int b) {
  return a < b ? a : b;
}
