import 'package:flutter/material.dart';
import './section_card.dart';

class SessionContextSection extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const SessionContextSection({super.key, required this.sessionData});

  @override
  Widget build(BuildContext context) {
    final client = sessionData['client'] ?? {};
    final car = sessionData['car'] ?? {};

    return SectionCard(
      title: 'Session Context',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.person_outline,
            'Client',
            client['name'] ?? 'Unknown',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.directions_car_outlined,
            'Vehicle',
            '${car['make'] ?? ''} ${car['model'] ?? ''} (${car['plateNumber'] ?? ''})',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.flag_outlined,
            'Status',
            sessionData['status'] ?? 'Unknown',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
