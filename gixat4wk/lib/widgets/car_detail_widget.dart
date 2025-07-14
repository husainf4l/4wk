// import 'package:flutter/material.dart';

// class CarDetailWidget extends StatelessWidget {
//   final String carDetails;
//   final Map<String, dynamic>? carData;
//   final bool showFullDetails;

//   const CarDetailWidget({
//     super.key,
//     required this.carDetails,
//     this.carData,
//     this.showFullDetails = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       padding: const EdgeInsets.all(12.0),
//       decoration: BoxDecoration(
//         color: Colors.black12,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: theme.primaryColor.withAlpha(51)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Basic car details always shown
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: theme.primaryColor.withAlpha(26),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.directions_car,
//                   color: theme.primaryColor,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   carDetails,
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // Additional car details if requested and data is available
//           if (showFullDetails && carData != null) ...[
//             const SizedBox(height: 16),
//             const Divider(height: 1),
//             const SizedBox(height: 12),

//             _buildDetailRow(
//               context,
//               'VIN',
//               carData!['vin'] ?? 'N/A',
//               Icons.pin,
//             ),

//             const SizedBox(height: 8),
//             _buildDetailRow(
//               context,
//               'Mileage',
//               '${carData!['mileage'] ?? 'N/A'} km',
//               Icons.speed,
//             ),

//             if (carData!.containsKey('lastService') &&
//                 carData!['lastService'] != null) ...[
//               const SizedBox(height: 8),
//               _buildDetailRow(
//                 context,
//                 'Last Service',
//                 carData!['lastService'],
//                 Icons.build,
//               ),
//             ],

//             if (carData!.containsKey('color') && carData!['color'] != null) ...[
//               const SizedBox(height: 8),
//               _buildDetailRow(
//                 context,
//                 'Color',
//                 carData!['color'],
//                 Icons.color_lens,
//               ),
//             ],
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(
//     BuildContext context,
//     String label,
//     String value,
//     IconData icon,
//   ) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: Colors.grey[600]),
//         const SizedBox(width: 8),
//         Text(
//           '$label:',
//           style: TextStyle(
//             fontSize: 13,
//             color: Colors.grey[600],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
//       ],
//     );
//   }
// }
