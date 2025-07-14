// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import '../controllers/auth_controller.dart';

// class InspectionService {
//   final CollectionReference _jobCardCollection = FirebaseFirestore.instance
//       .collection('jobCard');
//   final CollectionReference _activityCollection = FirebaseFirestore.instance
//       .collection('activity');

//   // Try to get the AuthController if it's available
//   final AuthController? _authController =
//       Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

//   Future<String?> saveInspection({
//     required String sessionId,
//     required String carId,
//     required String clientId,
//     required String notes,
//     required List<Map<String, dynamic>> findings,
//     required List<String> images,
//   }) async {
//     try {
//       // Filter out any invalid image URLs (ensure they're all valid URLs)
//       final List<String> validImages =
//           images
//               .where((url) => url.isNotEmpty && url.startsWith('http'))
//               .toList();

//       // Create Firestore document
//       final inspectionData = {
//         'sessionId': sessionId,
//         'carId': carId,
//         'clientId': clientId,
//         'notes': notes,
//         'findings': findings,
//         'images': validImages,
//         'type': 'inspection',
//         'timestamp': FieldValue.serverTimestamp(),
//       };

//       // Add document to Firestore
//       final DocumentReference docRef = await _jobCardCollection.add(
//         inspectionData,
//       );

//       // Update session with the new inspection ID
//       await FirebaseFirestore.instance
//           .collection('sessions')
//           .doc(sessionId)
//           .update({'status': 'INSPECTED'});

//       await _createActivityRecord(
//         sessionId: sessionId,
//         title: 'Inspection completed',
//         type: 'inspection',
//       );

//       return docRef.id;
//     } catch (e) {
//       if (e is FirebaseException) {
//         // Specific handling for Firebase errors
//         return null;
//       }
//       return null;
//     }
//   }

//   // Get inspection for a specific session
//   Future<Map<String, dynamic>?> getInspectionForSession(
//     String sessionId,
//   ) async {
//     try {
//       final snapshot =
//           await _jobCardCollection
//               .where('sessionId', isEqualTo: sessionId)
//               .where('type', isEqualTo: 'inspection')
//               .get();

//       if (snapshot.docs.isNotEmpty) {
//         final doc = snapshot.docs.first;
//         final data = doc.data() as Map<String, dynamic>;
//         return {'id': doc.id, ...data};
//       }
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }

//   // Update an existing inspection
//   Future<bool> updateInspection({
//     required String inspectionId,
//     required String notes,
//     required List<Map<String, dynamic>> findings,
//     List<String>? images,
//   }) async {
//     try {
//       final updateData = {
//         'notes': notes,
//         'findings': findings,
//         'updatedAt': FieldValue.serverTimestamp(),
//       };

//       if (images != null && images.isNotEmpty) {
//         // Create a fresh copy of the images list with only valid URLs
//         final List<String> validImages = [];
//         for (String url in images) {
//           if (url.trim().isNotEmpty) {
//             validImages.add(url);
//           }
//         }

//         if (validImages.isNotEmpty) {
//           updateData['images'] = validImages;
//         }
//       }

//       await _jobCardCollection.doc(inspectionId).update(updateData);

//       // Get the session ID for activity logging
//       final inspectionDoc = await _jobCardCollection.doc(inspectionId).get();
//       if (inspectionDoc.exists) {
//         final inspectionData = inspectionDoc.data() as Map<String, dynamic>;
//         final sessionId = inspectionData['sessionId'] as String?;

//         if (sessionId != null) {
//           // Create activity record for the inspection update
//           await _activityCollection.add({
//             'sessionId': sessionId,
//             'inspectionId': inspectionId,
//             'timestamp': FieldValue.serverTimestamp(),
//             'type': 'inspection_update',
//             'title': 'Inspection Updated',
//             'description':
//                 notes.isNotEmpty
//                     ? 'Notes: $notes'
//                     : 'Inspection findings were updated',
//             'userId': _authController?.firebaseUser?.uid,
//             'userName': _authController?.currentUser?.displayName,
//           });
//         }
//       }

//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   // Create an activity record for tracking user actions
//   Future<void> _createActivityRecord({
//     required String sessionId,
//     required String title,
//     required String type,
//     String? description,
//   }) async {
//     try {
//       await _activityCollection.add({
//         'sessionId': sessionId,
//         'timestamp': FieldValue.serverTimestamp(),
//         'type': type,
//         'title': title,
//         'description': description ?? '',
//         'userId': _authController?.firebaseUser?.uid,
//         'userName': _authController?.currentUser?.displayName,
//       });
//     } catch (e) {
//       // Silently handle errors in activity logging
//     }
//   }
// }
