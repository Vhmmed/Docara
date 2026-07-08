import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';
import 'package:medical_booking_app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:medical_booking_app/features/auth/domain/entities/user_entity.dart';
import '../../../../../shared/widgets/custom_snackbar_helper.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/headers/signup_header.dart';
import '../../widgets/inputs/specialty_dropdown.dart';
import '../../widgets/inputs/terms_checkbox.dart';
import 'login_page.dart';
import '../doctor_onboarding/complete_doctor_profile_page.dart';

import 'package:medical_booking_app/features/auth/presentation/cubits/auth_state.dart' as auth;

class SignupPage extends StatefulWidget {
  final String roleId;
  const SignupPage({super.key, required this.roleId});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();

  bool notcheck = false;
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? selectedSpecialtyId;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    dateOfBirthController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your full name';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your phone number';
    final phoneRegex = RegExp(r'^\+?\d{10,15}$');
    if (!phoneRegex.hasMatch(value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff8FBAC7),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        dateOfBirthController.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _signUp(BuildContext blocContext) {
    if (!_formKey.currentState!.validate()) return;

    if (!notcheck) {
      CustomSnackBarHelper.show(
        context,
        message: 'Please accept the terms and conditions',
        isSuccess: false,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    blocContext.read<AuthCubit>().register(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      phone: phoneController.text.trim(),
      role: widget.roleId == 'doctor' ? UserRole.doctor : UserRole.patient,
      dateOfBirth: _selectedDate,
      specialtyId: selectedSpecialtyId,
    );
  }

  Future<void> _onAuthSignupSuccess(UserEntity user) async {
    if (!mounted) return;

    if (user.role == UserRole.doctor) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteDoctorProfilePage(
            userId: user.id,
            specialtyId: selectedSpecialtyId,
          ),
        ),
      );
    } else {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: 'Account created! Please sign in.',
        isSuccess: true,
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(roleId: widget.roleId),
        ),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDoctor = widget.roleId == 'doctor';

    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocConsumer<AuthCubit, auth.AuthState>(
        listener: (context, state) {
          if (state is auth.AuthAuthenticated) {
            _onAuthSignupSuccess(state.user);
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
          return Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SignupHeader(isDoctor: isDoctor),
                  const Gap(20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomText(
                            text: 'Full Name',
                            size: 15,
                            
                            weight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          const Gap(8),
                          CustomTextFormField(
                            controller: nameController,
                            keyboardType: TextInputType.name,
                            hint: 'Enter your full name',
                            isPassword: false,
                            color: Colors.grey.shade100,
                            textColor: Colors.grey[400],
                            borderColor: Colors.grey.shade200,
                            borderRadius: 14,
                            validator: _validateName,
                          ),
                          const Gap(16),
                          const CustomText(
                            text: 'Email Address',
                            size: 15,
                            
                            weight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          const Gap(8),
                          CustomTextFormField(
                            controller: emailController,
                            hint: 'Enter your email',
                            isPassword: false,
                            keyboardType: TextInputType.emailAddress,
                            color: Colors.grey.shade100,
                            textColor: Colors.grey[400],
                            borderColor: Colors.grey.shade200,
                            borderRadius: 14,
                            prefixIcon: Icon(
                              CupertinoIcons.mail,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              
                              fontSize: 14,
                            ),
                            validator: _validateEmail,
                          ),
                          const Gap(16),
                          const CustomText(
                            text: 'Phone Number',
                            size: 15,
                            
                            weight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          const Gap(8),
                          CustomTextFormField(
                            controller: phoneController,
                            hint: '+1 (555) 000-0000',
                            isPassword: false,
                            keyboardType: TextInputType.phone,
                            color: Colors.grey.shade100,
                            textColor: Colors.grey[400],
                            borderColor: Colors.grey.shade200,
                            borderRadius: 14,
                            prefixIcon: Icon(
                              CupertinoIcons.phone,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              
                              fontSize: 14,
                            ),
                            validator: _validatePhone,
                          ),
                          const Gap(16),
                          const CustomText(
                            text: 'Date of Birth',
                            size: 15,
                            
                            weight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          const Gap(8),
                          CustomTextFormField(
                            controller: dateOfBirthController,
                            hint: 'DD/MM/YYYY',
                            isPassword: false,
                            color: Colors.grey.shade100,
                            textColor: Colors.grey[400],
                            borderColor: Colors.grey.shade200,
                            borderRadius: 14,
                            readOnly: true,
                            prefixIcon: Icon(
                              CupertinoIcons.calendar,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => _selectDate(context),
                              icon: Icon(
                                CupertinoIcons.chevron_down,
                                color: Colors.grey[500],
                                size: 20,
                              ),
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              
                              fontSize: 14,
                            ),
                            onTap: () => _selectDate(context),
                          ),
                          const Gap(16),
                          const CustomText(
                            text: 'Password',
                            size: 15,
                            
                            weight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          const Gap(8),
                          CustomTextFormField(
                            controller: passwordController,
                            hint: 'Create a password',
                            isPassword: true,
                            color: Colors.grey.shade100,
                            textColor: Colors.grey[400],
                            borderColor: Colors.grey.shade200,
                            borderRadius: 14,
                            prefixIcon: Icon(
                              CupertinoIcons.padlock,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              
                              fontSize: 14,
                            ),
                            validator: _validatePassword,
                          ),
                          const Gap(16),
                          const CustomText(
                            text: 'Confirm Password',
                            size: 15,
                            
                            weight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          const Gap(8),
                          CustomTextFormField(
                            controller: confirmPasswordController,
                            hint: 'Re-enter your password',
                            isPassword: true,
                            color: Colors.grey.shade100,
                            textColor: Colors.grey[400],
                            borderColor: Colors.grey.shade200,
                            borderRadius: 14,
                            prefixIcon: Icon(
                              CupertinoIcons.padlock,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              
                              fontSize: 14,
                            ),
                            validator: _validateConfirmPassword,
                          ),
                          const Gap(16),
                          if (isDoctor) ...[
                            SpecialtyDropdown(
                              selectedSpecialtyId: selectedSpecialtyId,
                              onChanged: (value) {
                                setState(() => selectedSpecialtyId = value);
                              },
                            ),
                            const Gap(8),
                          ],
                          const Gap(15),
                          TermsCheckbox(
                            value: notcheck,
                            onChanged: (value) {
                              setState(() => notcheck = value ?? false);
                            },
                          ),
                          const Gap(30),
                          GradientButton(
                            label: 'Sign Up',
                            isLoading: isLoading,
                            onPressed: () => _signUp(context),
                          ),
                          const Gap(20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                text: "Already have an account?",
                                size: 14,
                                
                                color: Colors.grey[600],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoginPage(
                                        roleId: widget.roleId,
                                      ),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: const CustomText(
                                  text: 'Sign In',
                                  color: Color(0xff8FBAC7),
                                  weight: FontWeight.w600,
                                  size: 14,
                                  
                                  align: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          const Gap(20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
