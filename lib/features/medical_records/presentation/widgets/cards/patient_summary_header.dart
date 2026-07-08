import 'package:flutter/material.dart';

class PatientSummaryHeader extends StatelessWidget {
  final String fullName;
  final String? avatarUrl;
  final int? age;
  final String? gender;
  final String patientId;

  const PatientSummaryHeader({
    super.key,
    required this.fullName,
    this.avatarUrl,
    this.age,
    this.gender,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.blue.shade100,
          backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              if (age != null || gender != null)
                Text(
                  [
                    if (age != null) '$age years',
                    if (gender != null) gender,
                  ].join(' \u2022 '),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                'Patient ID: #${patientId.length >= 8 ? patientId.substring(0, 8).toUpperCase() : patientId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
