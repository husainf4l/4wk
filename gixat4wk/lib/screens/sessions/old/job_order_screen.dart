// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import '../../../widgets/detail_screen_header.dart'; // Import DetailScreenHeader widget

// class JobOrderScreen extends StatefulWidget {
//   final String reportId;

//   const JobOrderScreen({super.key, required this.reportId});

//   @override
//   State<JobOrderScreen> createState() => _JobOrderScreenState();
// }

// class _JobOrderScreenState extends State<JobOrderScreen> {
//   bool isLoading = true;
//   bool isSaving = false;
//   bool isEditing = false; // Start in view mode by default
//   Map<String, dynamic> reportData = {};
//   String? errorMessage;
//   bool hasExistingJobOrder = false;

//   // Add state for job order items - starting with a fresh empty list
//   List<Map<String, dynamic>> jobOrderItems = [];
//   TextEditingController newItemController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     fetchReportData();
//   }

//   Future<void> fetchReportData() async {
//     try {
//       // Get report data
//       final reportDoc =
//           await FirebaseFirestore.instance
//               .collection('reports')
//               .doc(widget.reportId)
//               .get();

//       if (!reportDoc.exists) {
//         setState(() {
//           errorMessage = "Report not found";
//           isLoading = false;
//         });
//         return;
//       }

//       reportData = reportDoc.data() as Map<String, dynamic>;

//       // Check if there's an existing job order document
//       final jobOrderDoc =
//           await FirebaseFirestore.instance
//               .collection('jobOrders')
//               .doc(widget.reportId)
//               .get();

//       if (jobOrderDoc.exists) {
//         // If job order exists, load its items
//         final jobOrderData = jobOrderDoc.data() as Map<String, dynamic>;
//         hasExistingJobOrder = true;
//         isEditing = false; // Start in view mode for existing job orders

//         if (jobOrderData['order'] != null &&
//             jobOrderData['order']['requests'] != null) {
//           final requests = jobOrderData['order']['requests'] as List<dynamic>;
//           jobOrderItems =
//               requests.map((item) {
//                 return {
//                   'id':
//                       item['id'] ??
//                       DateTime.now().millisecondsSinceEpoch.toString(),
//                   'title': item['title'] ?? '',
//                   'notes': item['notes'] ?? '',
//                   'source': item['source'] ?? 'custom',
//                 };
//               }).toList();
//         }
//       } else {
//         // If no job order exists, start in edit mode for a new job order
//         isEditing = true;
//         hasExistingJobOrder = false;
//         jobOrderItems = [];

//         // Add client requests
//         if (reportData['clientRequests'] != null) {
//           for (var request in reportData['clientRequests']) {
//             jobOrderItems.add({
//               'id': '${DateTime.now().millisecondsSinceEpoch}_client',
//               'title': request['request'] ?? 'Unknown request',
//               'notes': '',
//               'source': 'client_request',
//             });
//           }
//         }

//         // Add inspection findings
//         if (reportData['inspectionFindings'] != null) {
//           for (var finding in reportData['inspectionFindings']) {
//             jobOrderItems.add({
//               'id': '${DateTime.now().millisecondsSinceEpoch}_inspection',
//               'title': finding['finding'] ?? 'Unknown finding',
//               'notes': '',
//               'source': 'inspection_finding',
//             });
//           }
//         }

//         // Add test drive observations
//         if (reportData['testDriveObservations'] != null) {
//           for (var observation in reportData['testDriveObservations']) {
//             jobOrderItems.add({
//               'id': '${DateTime.now().millisecondsSinceEpoch}_test_drive',
//               'title': observation['observation'] ?? 'Unknown observation',
//               'notes': '',
//               'source': 'test_drive_observation',
//             });
//           }
//         }
//       }

//       setState(() {
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         errorMessage = "Error loading data: ${e.toString()}";
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     newItemController.dispose();
//     super.dispose();
//   }

//   // Method to remove an item from the list
//   void _removeItem(int index) {
//     setState(() {
//       jobOrderItems.removeAt(index);
//     });
//   }

//   // Method to add a new item to the list
//   void _addItem(String text) {
//     if (text.trim().isEmpty) return;

//     setState(() {
//       jobOrderItems.add({
//         'title': text,
//         'id': DateTime.now().millisecondsSinceEpoch.toString(),
//         'notes': '', // Add an empty notes field for each request
//         'source': 'custom', // Add source field for new items
//       });
//       newItemController.clear();
//     });
//     FocusScope.of(context).unfocus();
//   }

//   // Method to update notes for an item
//   void _updateNotes(int index, String notes) {
//     setState(() {
//       jobOrderItems[index]['notes'] = notes;
//     });
//   }

//   // Method to show notes editor dialog
//   void _showNotesDialog(int index) {
//     final TextEditingController notesController = TextEditingController();
//     notesController.text = jobOrderItems[index]['notes'] ?? '';

//     Get.dialog(
//       AlertDialog(
//         title: const Text('Request Notes'),
//         content: TextField(
//           controller: notesController,
//           decoration: const InputDecoration(
//             hintText: 'Add notes for this request...',
//             border: OutlineInputBorder(),
//           ),
//           maxLines: 5,
//         ),
//         actions: [
//           TextButton(child: const Text('Cancel'), onPressed: () => Get.back()),
//           TextButton(
//             child: const Text('Save'),
//             onPressed: () {
//               _updateNotes(index, notesController.text);
//               Get.back();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _saveJobOrder() async {
//     // Save job order to Firestore with the required structure
//     setState(() {
//       isSaving = true;
//     });

//     try {
//       final String jobOrderId = widget.reportId;
//       // Properly retrieve sessionId from report data - it could be directly in reportData or nested
//       final String sessionId =
//           reportData['sessionId'] ?? reportData['session']?['id'] ?? '';

//       if (sessionId.isEmpty) {
//         debugPrint('Warning: Could not find sessionId in report data');
//       }

//       // Create the order document with the required structure
//       final orderData = {
//         'clientName': reportData['clientData']['name'] ?? '',
//         'clientId': reportData['clientData']['id'] ?? '',
//         'carData': {
//           'id': reportData['carData']['id'] ?? '',
//           'model': reportData['carData']['model'] ?? '',
//           'make': reportData['carData']['make'] ?? '',
//           'year': reportData['carData']['year'] ?? '',
//           'mileage': reportData['mileage'] ?? '',
//           'plate': reportData['carData']['plateNumber'] ?? '',
//           'vin': reportData['carData']['vin'] ?? '',
//         },
//         'order': {
//           'id': jobOrderId,
//           'requests':
//               jobOrderItems, // Save the entire item objects with all details
//           'status': 'open',
//           'notes': {
//             'id': DateTime.now().millisecondsSinceEpoch.toString(),
//             'note': '',
//             'userName':
//                 '', // Add userName when you have authentication implemented
//           },
//           'createdAt': DateTime.now().millisecondsSinceEpoch,
//         },
//       };

//       // Save job order to Firestore
//       await FirebaseFirestore.instance
//           .collection('jobOrders')
//           .doc(jobOrderId)
//           .set(orderData);

//       // Update the session document with the job order ID
//       if (sessionId.isNotEmpty) {
//         await FirebaseFirestore.instance
//             .collection('sessions')
//             .doc(sessionId)
//             .update({
//               'jobOrderId': jobOrderId,
//               'status': 'JOB_ORDER', // Update session status
//               'lastUpdated': DateTime.now().millisecondsSinceEpoch,
//             });
//       }

//       // Show success message
//       Get.snackbar(
//         'Success',
//         'Job order saved successfully',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         margin: const EdgeInsets.all(16),
//       );

//       // Instead of navigating back, update the state to stay on this screen
//       setState(() {
//         hasExistingJobOrder = true; // Now there's an existing job order
//         isEditing = false; // Switch back to view mode
//         isSaving = false;
//       });
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Failed to save job order: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         margin: const EdgeInsets.all(16),
//       );

//       setState(() {
//         isSaving = false;
//       });
//     }
//   }

//   Widget _buildJobOrderList() {
//     if (jobOrderItems.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 16),
//             Text(
//               'No job order items yet',
//               style: TextStyle(
//                 fontSize: 18,
//                 color: Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Add items using the field below',
//               style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//             ),
//           ],
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 16.0),
//           child: Row(
//             children: [
//               Text(
//                 'Job Order Items',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               const Spacer(),
//               Text(
//                 '${jobOrderItems.length} items',
//                 style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//               ),
//             ],
//           ),
//         ),

//         // List of job items - Trello-like cards with notes
//         ...List.generate(
//           jobOrderItems.length,
//           (index) => Card(
//             margin: const EdgeInsets.only(bottom: 12),
//             elevation: 2,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Card header with title and actions
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Theme.of(
//                       context,
//                     ).primaryColor.withValues(alpha: 0.1),
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(12),
//                       topRight: Radius.circular(12),
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Source tag if available
//                       if (jobOrderItems[index]['source'] != null &&
//                           jobOrderItems[index]['source'] != 'custom')
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 4),
//                           child: Text(
//                             _getSourceLabel(jobOrderItems[index]['source']),
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.grey[600],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       // Title and actions
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               jobOrderItems[index]['title'],
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                           // Only show edit/delete buttons in editing mode
//                           if (isEditing) ...[
//                             IconButton(
//                               icon: const Icon(Icons.edit_note, size: 20),
//                               color: Theme.of(context).primaryColor,
//                               onPressed: () => _showNotesDialog(index),
//                               padding: EdgeInsets.zero,
//                               constraints: const BoxConstraints(),
//                               splashRadius: 20,
//                               tooltip: 'Edit notes',
//                             ),
//                             const SizedBox(width: 8),
//                             IconButton(
//                               icon: const Icon(Icons.delete_outline, size: 20),
//                               color: Colors.red[400],
//                               onPressed: () => _removeItem(index),
//                               padding: EdgeInsets.zero,
//                               constraints: const BoxConstraints(),
//                               splashRadius: 20,
//                               tooltip: 'Remove item',
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Card notes section
//                 if (jobOrderItems[index]['notes'] != null &&
//                     jobOrderItems[index]['notes'].isNotEmpty)
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Notes:',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           jobOrderItems[index]['notes'],
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   )
//                 else if (isEditing)
//                   // Empty notes indicator - only in edit mode
//                   InkWell(
//                     onTap: () => _showNotesDialog(index),
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(16),
//                       child: Text(
//                         '+ Add notes',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),

//         // Add new item input field - only show when in edit mode
//         if (isEditing)
//           Padding(
//             padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).cardColor,
//                       borderRadius: BorderRadius.circular(24),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withAlpha(10),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                       border: Border.all(
//                         color: Theme.of(
//                           context,
//                         ).dividerColor.withValues(alpha: 0.1),
//                       ),
//                     ),
//                     child: TextField(
//                       controller: newItemController,
//                       decoration: const InputDecoration(
//                         hintText: 'Add new job item...',
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 14,
//                         ),
//                       ),
//                       textInputAction: TextInputAction.send,
//                       onSubmitted: (_) => _addItem(newItemController.text),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 CircleAvatar(
//                   backgroundColor: Theme.of(context).primaryColor,
//                   child: IconButton(
//                     icon: const Icon(Icons.send, color: Colors.white),
//                     onPressed: () => _addItem(newItemController.text),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }

//   String _getSourceLabel(String source) {
//     switch (source) {
//       case 'client_request':
//         return 'Client Request';
//       case 'inspection_finding':
//         return 'Inspection Finding';
//       case 'test_drive_observation':
//         return 'Test Drive Observation';
//       default:
//         return 'Custom';
//     }
//   }

//   void _toggleEditMode() {
//     setState(() {
//       isEditing = !isEditing;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       body: SafeArea(
//         child:
//             isLoading
//                 ? Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           theme.primaryColor,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Loading job order...',
//                         style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                       ),
//                     ],
//                   ),
//                 )
//                 : errorMessage != null
//                 ? Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.error_outline,
//                         size: 48,
//                         color: Colors.red[400],
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Error',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.red[400],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         errorMessage!,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 24),
//                       ElevatedButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         child: const Text('Go Back'),
//                       ),
//                     ],
//                   ),
//                 )
//                 : Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Using DetailScreenHeader component for consistent app styling
//                     DetailScreenHeader(
//                       title: 'Job Order',
//                       subtitle:
//                           reportData['clientData']?['name'] ??
//                           'Vehicle Job Order',
//                       isEditing:
//                           isEditing, // Use the state variable to toggle edit mode
//                       isSaving: isSaving,
//                       onSavePressed: _saveJobOrder,
//                       onEditPressed:
//                           hasExistingJobOrder
//                               ? _toggleEditMode
//                               : null, // Only show edit button for existing job orders
//                       shareAction: null,
//                     ),
//                     Expanded(
//                       child: SingleChildScrollView(
//                         padding: const EdgeInsets.all(16.0),
//                         physics: const BouncingScrollPhysics(),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Client and Vehicle Card
//                             Card(
//                               elevation: 3,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     // Client section
//                                     Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           'Client',
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color: Colors.grey[600],
//                                           ),
//                                         ),
//                                         Text(
//                                           reportData['clientData']['name'] ??
//                                               'Unknown Client',
//                                           style: const TextStyle(
//                                             fontSize: 18,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const Padding(
//                                       padding: EdgeInsets.symmetric(
//                                         vertical: 12.0,
//                                       ),
//                                       child: Divider(),
//                                     ),
//                                     // Vehicle section header
//                                     const Text(
//                                       'Vehicle Information',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 12),
//                                     // Vehicle details in grid layout
//                                     Wrap(
//                                       spacing: 16,
//                                       runSpacing: 8,
//                                       children: [
//                                         _buildVehicleInfoItem(
//                                           'Make',
//                                           reportData['carData']['make'] ??
//                                               'N/A',
//                                         ),
//                                         _buildVehicleInfoItem(
//                                           'Model',
//                                           reportData['carData']['model'] ??
//                                               'N/A',
//                                         ),
//                                         _buildVehicleInfoItem(
//                                           'Year',
//                                           reportData['carData']['year']
//                                                   ?.toString() ??
//                                               'N/A',
//                                         ),
//                                         _buildVehicleInfoItem(
//                                           'Plate',
//                                           reportData['carData']['plateNumber'] ??
//                                               'N/A',
//                                         ),
//                                         if (reportData['mileage'] != null)
//                                           _buildVehicleInfoItem(
//                                             'Mileage',
//                                             reportData['mileage'].toString(),
//                                           ),
//                                         if (reportData['carData']['vin'] !=
//                                             null)
//                                           _buildVehicleInfoItem(
//                                             'VIN',
//                                             reportData['carData']['vin'],
//                                           ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             _buildJobOrderList(),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }

//   Widget _buildVehicleInfoItem(String label, String value) {
//     return SizedBox(
//       width: MediaQuery.of(context).size.width * 0.38,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//           const SizedBox(height: 2),
//           Text(
//             value,
//             style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
//           ),
//         ],
//       ),
//     );
//   }
// }
