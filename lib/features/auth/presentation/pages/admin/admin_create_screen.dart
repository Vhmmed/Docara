import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medical_booking_app/core/constants/app_color.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';
import 'package:medical_booking_app/shared/widgets/custom_text_field.dart';
import 'package:medical_booking_app/shared/widgets/custom_button.dart';
import 'package:medical_booking_app/shared/widgets/custom_snackbar_helper.dart';
import 'package:medical_booking_app/features/auth/presentation/widgets/misc/info_banner.dart';

class AdminCreateScreen extends StatefulWidget {
  const AdminCreateScreen({super.key});

  @override
  State<AdminCreateScreen> createState() => _AdminCreateScreenState();
}

class _AdminCreateScreenState extends State<AdminCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter email';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter full name';
    return null;
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.rpc(
        'create_admin_account',
        params: {
          'admin_email': _emailController.text.trim(),
          'admin_password': _passwordController.text,
          'admin_full_name': _nameController.text.trim(),
        },
      );

      if (!mounted) return;

      CustomSnackBarHelper.show(
        context,
        message: 'Admin account created successfully!',
        isSuccess: true,
      );

      Navigator.pop(context);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: e.message.contains('duplicate')
            ? 'An account with this email already exists'
            : e.message,
        isSuccess: false,
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: 'Failed to create admin: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const CustomText(
          text: 'Create Admin',
          size: 20,
          
          weight: FontWeight.w600,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(
                text: 'New Admin Details',
                size: 16,
                
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              const Gap(20),

              // Full Name
              const CustomText(
                text: 'Full Name',
                size: 14,
                
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              const Gap(8),
              CustomTextFormField(
                controller: _nameController,
                hint: 'Enter full name',
                isPassword: false,
                color: Colors.grey.shade100,
                textColor: Colors.grey[400],
                borderColor: Colors.grey.shade200,
                borderRadius: 14,
                validator: _validateName,
              ),

              const Gap(16),

              // Email
              const CustomText(
                text: 'Email Address',
                size: 14,
                
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              const Gap(8),
              CustomTextFormField(
                controller: _emailController,
                hint: 'Enter email address',
                isPassword: false,
                keyboardType: TextInputType.emailAddress,
                color: Colors.grey.shade100,
                textColor: Colors.grey[400],
                borderColor: Colors.grey.shade200,
                borderRadius: 14,
                validator: _validateEmail,
              ),

              const Gap(16),

              // Password
              const CustomText(
                text: 'Password',
                size: 14,
                
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              const Gap(8),
              CustomTextFormField(
                controller: _passwordController,
                hint: 'Enter password',
                isPassword: true,
                color: Colors.grey.shade100,
                textColor: Colors.grey[400],
                borderColor: Colors.grey.shade200,
                borderRadius: 14,
                validator: _validatePassword,
              ),

              const Gap(20),

              // Create Button
              CustomButton(
                text: 'Create Admin',
                isLoading: _isLoading,
                onTap: _createAdmin,
              ),

              const InfoBanner(
                message: 'The new admin can log in immediately with the credentials above.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
