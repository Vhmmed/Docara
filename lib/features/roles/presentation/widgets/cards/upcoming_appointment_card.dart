import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_button.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class UpcomingAppointmentCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final String date;
  final bool showTodayBadge;
  final String? doctorAvatarUrl;
  const UpcomingAppointmentCard({
    super.key,
    this.doctorName = 'Dr. Emily Chen',
    this.specialty = 'General Physician',
    this.date = 'March 14, 2026 \u2022 10:00 AM',
    this.showTodayBadge = false,
    this.doctorAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: const Color(0xff8FBAC7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomText(
                text: 'Upcoming Appointment',
                size: 15,
                weight: FontWeight.w700,
                color: Colors.black,
              ),
              const Spacer(),
              if (showTodayBadge)
                Container(
                  padding: const EdgeInsets.only(right: 12, left: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xff8FBAC7),
                    border: Border.all(
                      color: Color(0xff8FBAC7),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const CustomText(
                    text: 'Today',
                    size: 15,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const Gap(30),
          Row(
            children: [
              doctorAvatarUrl != null && doctorAvatarUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 22.5,
                      backgroundImage: NetworkImage(doctorAvatarUrl!),
                      backgroundColor: Color(0xff8FBAC7).withValues(alpha: 0.15),
                    )
                  : SvgPicture.asset(
                      'assets/images/user.svg',
                      width: 45,
                      height: 45,
                    ),
              const Gap(12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: const TextStyle(
                      fontSize: 15,

                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    specialty,
                    style: TextStyle(
                      fontSize: 13,

                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SvgPicture.asset(
                  'assets/images/calendar-04.svg',
                  width: 35,
                  height: 35,
                ),
              ),
              const Gap(5),
              Center(
                child: CustomText(
                  text: date,
                  size: 13,

                ),
              ),
            ],
          ),
          const Gap(15),
          Center(
            child: CustomButton(
              text: 'Join video call',
              width: 198,
              height: 40,
            ),
          ),
        ],
      ),
    );
  }
}
