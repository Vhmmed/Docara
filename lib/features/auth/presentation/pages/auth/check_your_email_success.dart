import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medical_booking_app/shared/widgets/custom_snackbar_helper.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';
import 'package:medical_booking_app/features/auth/presentation/widgets/buttons/gradient_button.dart';
import 'login_page.dart';

class CheckYourEmailSuccess extends StatefulWidget {
  final String roleId;
  final String email;
  const CheckYourEmailSuccess({super.key, required this.roleId, required this.email});

  @override
  State<CheckYourEmailSuccess> createState() => _CheckYourEmailSuccessState();
}

class _CheckYourEmailSuccessState extends State<CheckYourEmailSuccess> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 33),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Gap(100),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xff8FBAC7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.check_mark_circled,
                  size: 80,
                  color: Color(0xff8FBAC7),
                ),
              ),
              const Gap(24),
              const CustomText(
                text: 'Check Your Email',
                size: 24,
                
                weight: FontWeight.w700,
                color: Colors.black87,
              ),
              const Gap(8),
              const Text(
                'We have sent a password recovery link to your email address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  
                  color: Colors.grey,
                ),
              ),
              const Gap(40),
              GradientButton(
                label: 'Back to Login',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LoginPage(
                              roleId: widget.roleId,
                            )),
                    (route) => false,
                  );
                },
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CustomText(
                    text: "Didn't receive the email?",
                    size: 14,
                    
                    color: Colors.grey,
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await Supabase.instance.client.auth
                            .resetPasswordForEmail(widget.email);
                        if (!context.mounted) return;
                        CustomSnackBarHelper.show(
                          context,
                          message: 'Email sent successfully',
                          isSuccess: true,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        CustomSnackBarHelper.show(
                          context,
                          message: 'Failed to resend email. Please try again.',
                          isSuccess: false,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: const CustomText(
                      text: 'Resend',
                      color: Color(0xff8FBAC7),
                      weight: FontWeight.w600,
                      size: 14,
                      
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
