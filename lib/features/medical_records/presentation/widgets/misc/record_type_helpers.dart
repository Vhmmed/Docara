import 'package:flutter/material.dart';

import '../../../domain/entities/medical_record_entity.dart';

IconData recordTypeIcon(RecordType type) => switch (type) {
  RecordType.labResult => Icons.science,
  RecordType.prescription => Icons.medication,
  RecordType.imaging => Icons.monitor_heart,
  RecordType.report => Icons.description,
};

Color recordTypeColor(RecordType type) => switch (type) {
  RecordType.labResult => Colors.purple,
  RecordType.prescription => Colors.green,
  RecordType.imaging => Colors.blue,
  RecordType.report => Colors.orange,
};

String recordTypeLabel(RecordType type) => switch (type) {
  RecordType.labResult => 'Lab Result',
  RecordType.prescription => 'Prescription',
  RecordType.imaging => 'Imaging',
  RecordType.report => 'Report',
};
