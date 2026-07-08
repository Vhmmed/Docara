import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';
import 'package:medical_booking_app/shared/widgets/custom_text_field.dart';
import '../../../../notifications/presentation/cubits/notification_unread_count_cubit.dart';
import '../../../../notifications/presentation/pages/notification_page.dart';

class PatientHeader extends StatelessWidget {
  final String? userName;
  final String roleId;
  final TextEditingController searchController;
  const PatientHeader({
    super.key,
    this.userName,
    required this.roleId,
    required this.searchController,
  });

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
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        gradient: LinearGradient(
          colors: [
            const Color(0xff8FA5AF).withOpacity(0.64),
            const Color(0xff8FBAC7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(70),
            Row(
              children: [
                CustomText(
                  text: userName != null ? 'Hello, $userName' : 'Hello there',
                  size: 25,
                  
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
                const Spacer(),
                BlocBuilder<NotificationUnreadCountCubit, int>(
                  bloc: sl<NotificationUnreadCountCubit>(),
                  builder: (_, count) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                    },
                    child: _bellIconWithBadge(
                      icon: CupertinoIcons.bell,
                      count: count,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),
            const CustomText(
              text: 'How are you feeling today?',
              size: 16,
              color: Colors.white,
              
            ),
            const Gap(15),
            CustomTextFormField(
              hint: 'Search doctors , specialist..',
              isPassword: false,
              controller: searchController,
              prefixIcon: const Icon(
                CupertinoIcons.search,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
