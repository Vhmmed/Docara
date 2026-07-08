import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback? onBookAppointment;
  final VoidCallback? onChat;
  final VoidCallback? onMedicalRecords;
  const QuickActionsRow({
    super.key,
    this.onBookAppointment,
    this.onChat,
    this.onMedicalRecords,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 115,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(child: _ActionTile(
            icon: CupertinoIcons.calendar,
            label1: 'Book',
            label2: 'Appointments',
            onTap: onBookAppointment,
          )),
          const SizedBox(width: 10),
          Expanded(child: _ActionTile(
            icon: CupertinoIcons.doc_text,
            label1: 'Medical',
            label2: 'Records',
            onTap: onMedicalRecords,
          )),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label1;
  final String? label2;
  final VoidCallback? onTap;
  const _ActionTile({
    required this.icon,
    required this.label1,
    this.label2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(
            color: const Color(0xff8FBAC7),
            width: 1,
          ),
        ),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 30,
            color: const Color(0xff8FBAC7),
          ),
          const Gap(10),
          Center(
            child: CustomText(
              text: label1,
              size: 12,
              color: Colors.black,
              
            ),
          ),
          if (label2 != null)
            Center(
              child: CustomText(
                text: label2!,
                size: 12,
                color: Colors.black,
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}
