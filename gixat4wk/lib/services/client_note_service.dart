// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import '../models/client_note.dart';
// import 'error_service.dart';

// class ClientNoteService {
//   final CollectionReference _jobCardCollection = FirebaseFirestore.instance
//       .collection('jobCard');

//   // Get error service from GetX
//   final ErrorService _errorService = Get.find<ErrorService>();

//   // Create a new client note
//   Future<String?> createClientNote({
//     required String clientId,
//     required String carId,
//     required String garageId,
//     required String sessionId,
//     required String notes,
//     required List<Map<String, dynamic>> clientRequests,
//   }) async {
//     try {
//       final clientNote = ClientNote(
//         id: '',
//         clientId: clientId,
//         carId: carId,
//         garageId: garageId,
//         sessionId: sessionId,
//         notes: notes,
//         clientRequests: clientRequests,
//         createdAt: DateTime.now(),
//       );

//       // Add type field to identify this as a client note
//       final Map<String, dynamic> noteData = clientNote.toMap();
//       noteData['type'] = 'clientNotes';

//       final docRef = await _jobCardCollection.add(noteData);
//       return docRef.id;
//     } catch (e) {
//       _errorService.logError(e, context: 'ClientNoteService.createClientNote');
//       return null;
//     }
//   }
// }
