import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/core/utils/doctor_display_name.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';
import '../../../../notifications/presentation/cubits/notification_unread_count_cubit.dart';
import '../../../../notifications/presentation/pages/notification_page.dart';

class DoctorHeader extends StatelessWidget {
  final String? userName;
  const DoctorHeader({super.key, this.userName});

  Widget _bellIconWithBadge({
    required IconData icon,
    required int count,
    required Color color,
    required double size,
  }) {
    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: color, size: size),
          if (count > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 12),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(
              text: 'Welcome back,',
              size: 14,
              color: Colors.grey,
              
            ),
            CustomText(
              text: doctorDisplayName(userName),
              size: 22,
              color: Colors.black,
              
              weight: FontWeight.w700,
            ),
          ],
        ),
        const Spacer(),
        BlocBuilder<NotificationUnreadCountCubit, int>(
          bloc: sl<NotificationUnreadCountCubit>(),
          builder: (_, count) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 0),
              child: _bellIconWithBadge(
                icon: CupertinoIcons.bell,
                count: count,
                color: const Color(0xff8FBAC7),
                size: 29,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
