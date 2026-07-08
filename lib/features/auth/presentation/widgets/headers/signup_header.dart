import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

class SignupHeader extends StatelessWidget {
  final bool isDoctor;
  const SignupHeader({super.key, this.isDoctor = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xff8FA5AF).withOpacity(0.64),
            const Color(0xff8FBAC7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(70),
            IconButton(
              icon: const Icon(
                CupertinoIcons.back,
                size: 25,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
            const Gap(10),
            Row(
              children: [
                const CustomText(
                  text: 'Create Account',
                  size: 25,
                  
                  color: Colors.white,
                  weight: FontWeight.w700,
                ),
                const Gap(10),
                if (isDoctor)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const CustomText(
                      text: 'Doctor',
                      size: 12,
                      
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const Gap(10),
            const CustomText(
              text: 'Join Docara for better healthcare',
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
