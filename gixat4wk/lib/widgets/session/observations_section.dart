import 'package:flutter/material.dart';
import './section_card.dart';

class ObservationsSection extends StatelessWidget {
  final List<Map<String, dynamic>> observations;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final Function(int, Map<String, dynamic>) onEdit;

  const ObservationsSection({
    super.key,
    required this.observations,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Test Drive Observations',
      icon: Icons.visibility_outlined,
      trailing: IconButton(
        onPressed: onAdd,
        icon: const Icon(Icons.add_circle, color: Colors.blue),
        tooltip: 'Add Observation',
      ),
      child: Column(
        children: [
          if (observations.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No observations added yet.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: observations.length,
              itemBuilder: (context, index) {
                final observation = observations[index];
                return _buildObservationItem(context, index, observation);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildObservationItem(
      BuildContext context, int index, Map<String, dynamic> observation) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        title: Text(observation['title'] ?? 'Observation ${index + 1}'),
        subtitle: Text(observation['description'] ?? ''),
        trailing: IconButton(
          onPressed: () => onRemove(index),
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        onTap: () => onEdit(index, observation),
      ),
    );
  }
}
