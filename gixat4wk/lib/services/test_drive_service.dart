// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import '../controllers/auth_controller.dart';

// class TestDriveService {
//   final CollectionReference _jobCardCollection = FirebaseFirestore.instance
//       .collection('jobCard');
//   final CollectionReference _activityCollection = FirebaseFirestore.instance
//       .collection('activity');

//   // Try to get the AuthController if it's available
//   final AuthController? _authController =
//       Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

//   Future<String?> saveTestDrive({
//     required String sessionId,
//     required String carId,
//     required String clientId,
//     required String notes,
//     required List<Map<String, dynamic>> observations,
//     required List<String> images,
//   }) async {
//     try {
//       // Filter out any invalid image URLs (ensure they're all valid URLs)
//       final List<String> validImages =
//           images
//               .where((url) => url.isNotEmpty && url.startsWith('http'))
//               .toList();

//       // Create Firestore document
//       final testDriveData = {
//         'sessionId': sessionId,
//         'carId': carId,
//         'clientId': clientId,
//         'notes': notes,
//         'observations': observations,
//         'images': validImages,
//         'type': 'testDrive',
//         'timestamp': FieldValue.serverTimestamp(),
//       };

//       // Add document to Firestore
//       final DocumentReference docRef = await _jobCardCollection.add(
//         testDriveData,
//       );

//       await FirebaseFirestore.instance
//           .collection('sessions')
//           .doc(sessionId)
//           .update({'status': 'TESTED'});

//       // Create activity record for tracking
//       await _createActivityRecord(
//         sessionId: sessionId,
//         title: 'Test drive completed',
//         type: 'test_drive',
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

//   // Get test drive for a specific session
//   Future<Map<String, dynamic>?> getTestDriveForSession(String sessionId) async {
//     try {
//       final snapshot =
//           await _jobCardCollection
//               .where('sessionId', isEqualTo: sessionId)
//               .where('type', isEqualTo: 'testDrive')
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

//   // Update an existing test drive
//   Future<bool> updateTestDrive({
//     required String testDriveId,
//     required String notes,
//     required List<Map<String, dynamic>> observations,
//     List<String>? images,
//   }) async {
//     try {
//       final updateData = {
//         'notes': notes,
//         'observations': observations,
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

//       await _jobCardCollection.doc(testDriveId).update(updateData);

//       // Get the session ID for activity logging
//       final testDriveDoc = await _jobCardCollection.doc(testDriveId).get();
//       if (testDriveDoc.exists) {
//         final testDriveData = testDriveDoc.data() as Map<String, dynamic>;
//         final sessionId = testDriveData['sessionId'] as String?;

//         if (sessionId != null) {
//           // Create activity record for the test drive update
//           await _activityCollection.add({
//             'sessionId': sessionId,
//             'testDriveId': testDriveId,
//             'timestamp': FieldValue.serverTimestamp(),
//             'type': 'test_drive_update',
//             'title': 'Test Drive Updated',
//             'description':
//                 notes.isNotEmpty
//                     ? 'Notes: $notes'
//                     : 'Test drive observations were updated',
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
