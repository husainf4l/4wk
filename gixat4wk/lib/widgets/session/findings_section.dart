import 'package:flutter/material.dart';
import './section_card.dart';

class FindingsSection extends StatelessWidget {
  final List<Map<String, dynamic>> findings;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final Function(int, Map<String, dynamic>) onEdit;

  const FindingsSection({
    super.key,
    required this.findings,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Inspection Findings',
      icon: Icons.plagiarism_outlined,
      trailing: IconButton(
        onPressed: onAdd,
        icon: const Icon(Icons.add_circle, color: Colors.blue),
        tooltip: 'Add Finding',
      ),
      child: Column(
        children: [
          if (findings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No findings added yet.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: findings.length,
              itemBuilder: (context, index) {
                final finding = findings[index];
                return _buildFindingItem(context, index, finding);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFindingItem(
      BuildContext context, int index, Map<String, dynamic> finding) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        title: Text(finding['title'] ?? 'Finding ${index + 1}'),
        subtitle: Text(finding['description'] ?? ''),
        trailing: IconButton(
          onPressed: () => onRemove(index),
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        onTap: () => onEdit(index, finding),
      ),
    );
  }
}
