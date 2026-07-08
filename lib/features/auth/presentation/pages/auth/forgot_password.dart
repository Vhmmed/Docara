import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/shared/widgets/custom_button.dart';
import 'package:medical_booking_app/shared/widgets/custom_snackbar_helper.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';
import 'package:medical_booking_app/shared/widgets/custom_text_field.dart';
import 'package:medical_booking_app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:medical_booking_app/features/auth/presentation/cubits/auth_state.dart' as auth;

import 'check_your_email_success.dart';

class ForgotPassword extends StatefulWidget {
  final String roleId;
  const ForgotPassword({super.key, required this.roleId});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Please enter a valid email address';
    return null;
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _onResetSent() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckYourEmailSuccess(
          roleId: widget.roleId,
          email: emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocConsumer<AuthCubit, auth.AuthState>(
        listener: (context, state) {
          if (state is auth.AuthPasswordResetSent) {
            _onResetSent();
          } else if (state is auth.AuthError) {
            if (!mounted) return;
            CustomSnackBarHelper.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is auth.AuthLoading;
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
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
                  padding: const EdgeInsets.symmetric(horizontal: 23),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/Rectangle 1.png',
                        fit: BoxFit.contain,
                      ),
                      const Gap(15),
                      const CustomText(
                        text: 'Forgot Password?',
                        size: 20,
                        weight: FontWeight.w600,
                      ),
                      const Gap(7),
                      const CustomText(
                        text: 'Enter your email to reset your password',
                        size: 14,
                      ),
                      const Gap(40),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                text: 'Email Address',
                                size: 17,
                                
                                weight: FontWeight.w700,
                              ),
                            ),
                            const Gap(15),
                            CustomTextFormField(
                              hint: 'Enter your email',
                              isPassword: false,
                              controller: emailController,
                              prefixIcon: const Icon(CupertinoIcons.mail),
                              keyboardType: TextInputType.emailAddress,
                              color: Colors.grey.shade100,
                              textColor: Colors.grey[400],
                              borderColor: Colors.grey.shade200,
                              borderRadius: 14,
                              validator: _validateEmail,
                            ),
                          ],
                        ),
                      ),
                      const Gap(24),
                      CustomButton(
                        text: 'Reset Password',
                        isLoading: isLoading,
                        onTap: () {
                          if (!_formKey.currentState!.validate()) return;
                          context.read<AuthCubit>().resetPassword(
                            emailController.text.trim(),
                          );
                        },
                      ),
                      const Gap(20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(
                            text: "Remember your password?",
                            size: 14,
                            
                            color: Colors.grey[600],
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const CustomText(
                              text: 'Sign In',
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
            ),
          );
        },
      ),
    );
  }
}
