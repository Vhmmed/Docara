import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/medical_record_entity.dart';

class MedicalRecordDetailSheet extends StatelessWidget {
  final MedicalRecordEntity record;

  const MedicalRecordDetailSheet({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            record.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMMM d, yyyy \u2022 h:mm a')
                .format(record.createdAt.toLocal()),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (record.chiefComplaints != null) ...[
            _sectionLabel('Chief Complaints'),
            const SizedBox(height: 4),
            Text(
              record.chiefComplaints!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          if (record.diagnosis != null) ...[
            _sectionLabel('Diagnosis'),
            const SizedBox(height: 4),
            Text(
              record.diagnosis!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          if (record.prescription != null) ...[
            _sectionLabel('Prescription'),
            const SizedBox(height: 4),
            Text(
              record.prescription!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          if (record.followUpDate != null) ...[
            _sectionLabel('Follow-up'),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMMM d, yyyy').format(record.followUpDate!),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
          ],
          if (record.additionalInstructions != null) ...[
            _sectionLabel('Additional Instructions'),
            const SizedBox(height: 4),
            Text(
              record.additionalInstructions!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          if (record.fileUrl != null) ...[
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('View Document'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    );
  }
}
