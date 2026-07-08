import 'package:flutter/material.dart';

const List<String> _bloodTypes = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

class BloodTypeSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const BloodTypeSelector({
    super.key,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Blood Type',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: _bloodTypes
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
