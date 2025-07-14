import 'package:flutter/material.dart';
import './section_card.dart';

class ReportDataSection extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onSummaryChanged;

  const ReportDataSection({
    super.key,
    required this.reportData,
    required this.onTitleChanged,
    required this.onSummaryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Report Configuration',
      icon: Icons.settings_outlined,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Report Title',
              border: OutlineInputBorder(),
            ),
            initialValue: reportData['title']?.toString() ?? '',
            onChanged: onTitleChanged,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Summary',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            initialValue: reportData['summary']?.toString() ?? '',
            onChanged: onSummaryChanged,
          ),
        ],
      ),
    );
  }
}
