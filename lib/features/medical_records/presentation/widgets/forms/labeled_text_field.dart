import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final int maxLines;
  final String? Function(String?)? validator;

  const LabeledTextField({
    super.key,
    required this.icon,
    required this.label,
    this.hintText,
    required this.controller,
    this.maxLines = 3,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }
}
