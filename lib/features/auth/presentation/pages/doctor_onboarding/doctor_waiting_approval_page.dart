import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';
import 'package:medical_booking_app/features/auth/presentation/widgets/misc/info_banner.dart';
import '../../../../roles/presentation/page/role_selection.dart';

class DoctorWaitingApprovalPage extends StatelessWidget {
  const DoctorWaitingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xff8FBAC7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.hourglass,
                  size: 60,
                  color: Color(0xff8FBAC7),
                ),
              ),
              const Gap(30),
              const CustomText(
                text: 'Application Submitted!',
                size: 24,
                color: Colors.black87,
                
                weight: FontWeight.w700,
              ),
              const Gap(12),
              const CustomText(
                text: 'Your documents have been submitted successfully.',
                size: 15,
                color: Colors.grey,
                
              ),
              const Gap(8),
              const CustomText(
                text:
                    'The admin will review your application and approve your account.',
                size: 14,
                color: Colors.grey,
                
              ),
              const Gap(8),
              const CustomText(
                text: '⏳ This usually takes 24-48 hours.',
                size: 14,
                color: Colors.grey,
                
              ),
              const Gap(40),
              const InfoBanner(
                message:
                    'You will be notified via email once approved.',
              ),
              const Gap(40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoleSelection(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const CustomText(
                    text: 'Back to Login',
                    size: 16,
                    color: Colors.grey,
                    
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
