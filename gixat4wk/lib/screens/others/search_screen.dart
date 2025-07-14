// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});

//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   bool _isSearching = false;
//   final List<String> _dummySearchResults = [
//     'Car Inspection Tips',
//     'Engine Maintenance',
//     'Tire Pressure Guidelines',
//     'Battery Replacement Guide',
//     'Oil Change Schedule',
//     'Brake Pad Inspection',
//     'Air Filter Replacement',
//     'Spark Plug Troubleshooting',
//     'Car Wash Best Practices',
//     'Winter Car Preparation',
//   ];
//   List<String> _filteredResults = [];

//   @override
//   void initState() {
//     super.initState();
//     _filteredResults = List.from(_dummySearchResults);
//     _searchController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     setState(() {
//       if (_searchController.text.isEmpty) {
//         _filteredResults = List.from(_dummySearchResults);
//         _isSearching = false;
//       } else {
//         _isSearching = true;
//         _filteredResults =
//             _dummySearchResults
//                 .where(
//                   (result) => result.toLowerCase().contains(
//                     _searchController.text.toLowerCase(),
//                   ),
//                 )
//                 .toList();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Discover',
//               style: theme.textTheme.headlineMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             // Search Box
//             Container(
//               decoration: BoxDecoration(
//                 color: theme.colorScheme.surface,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withAlpha(26),
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   hintText: 'Search topics, guides, and more...',
//                   prefixIcon: const Icon(Icons.search),
//                   suffixIcon:
//                       _isSearching
//                           ? IconButton(
//                             icon: const Icon(Icons.clear),
//                             onPressed: () {
//                               _searchController.clear();
//                             },
//                           )
//                           : null,
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             Expanded(child: _buildSearchResults(theme)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchResults(ThemeData theme) {
//     if (_isSearching && _filteredResults.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'No results found',
//               style: TextStyle(color: Colors.grey[600], fontSize: 18),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Try searching with different keywords',
//               style: TextStyle(color: Colors.grey[500]),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       itemCount: _filteredResults.length,
//       itemBuilder: (context, index) {
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: ListTile(
//             contentPadding: const EdgeInsets.all(16),
//             title: Text(
//               _filteredResults[index],
//               style: theme.textTheme.titleMedium,
//             ),
//             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//             onTap: () {
//               Get.snackbar(
//                 'Selected Item',
//                 'You selected: ${_filteredResults[index]}',
//                 snackPosition: SnackPosition.BOTTOM,
//               );
//             },
//             // Add some visual interest with a leading icon
//             leading: CircleAvatar(
//               backgroundColor: theme.colorScheme.primary.withAlpha(51),
//               child: Icon(
//                 index % 2 == 0 ? Icons.auto_stories : Icons.car_repair,
//                 color: theme.colorScheme.primary,
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
