import 'package:flutter/material.dart';
import './section_card.dart';

class MileageSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const MileageSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Vehicle Mileage',
      icon: Icons.speed,
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Current Mileage',
          hintText: 'Enter vehicle mileage (e.g., 50,000)',
          suffixText: 'km',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      ),
    );
  }
}
