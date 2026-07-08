import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VisitHistoryCard extends StatelessWidget {
  final int totalVisits;
  final int visitsThisYear;
  final int visitsThisMonth;
  final DateTime? lastVisitDate;

  const VisitHistoryCard({
    super.key,
    required this.totalVisits,
    required this.visitsThisYear,
    required this.visitsThisMonth,
    this.lastVisitDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Visit History',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statColumn('Total', '$totalVisits', Colors.blue),
              _divider(),
              _statColumn('This Year', '$visitsThisYear', Colors.green),
              _divider(),
              _statColumn('This Month', '$visitsThisMonth', Colors.orange),
            ],
          ),
          if (lastVisitDate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last: ${DateFormat('MMM d, yyyy').format(lastVisitDate!.toLocal())}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade300,
    );
  }
}
