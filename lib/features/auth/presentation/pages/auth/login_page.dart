import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/core/services/fcm_service.dart';
import 'package:medical_booking_app/features/auth/presentation/pages/auth/forgot_password.dart';
import 'package:medical_booking_app/features/auth/presentation/pages/auth/signup_page.dart';
import 'package:medical_booking_app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:medical_booking_app/features/auth/domain/entities/user_entity.dart';

import 'package:medical_booking_app/features/auth/presentation/cubits/auth_state.dart' as auth;
import '../../../../../shared/widgets/custom_snackbar_helper.dart';
import '../../../../../shared/widgets/custom_text.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../widgets/loading/loading_widgets.dart';
import '../../../data/models/role_model.dart';
import '../../helpers/auth_navigation.dart';
import '../../helpers/oauth_helper.dart';
import '../../widgets/cards/admin_security_notice.dart';
import '../../widgets/headers/login_header.dart';
import '../../widgets/buttons/social_login_section.dart';

class LoginPage extends StatefulWidget {
  final String roleId;
  const LoginPage({super.key, required this.roleId});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late RoleModel currentRole;
  bool isPasswordVisible = false;
  bool _awaitingOAuth = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    currentRole = RoleModel.getRoleById(widget.roleId);
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint(
          '>>> [LOGIN_PAGE] AUTH EVENT: ${data.event}, widget.roleId: ${widget.roleId}, _awaitingOAuth: $_awaitingOAuth, session: ${data.session?.user.id}');
      if (data.event == AuthChangeEvent.signedIn &&
          _awaitingOAuth &&
          data.session != null &&
          _isOAuthSignIn(data.session!)) {
        _awaitingOAuth = false;
        handlePostOAuthSignIn(context, roleId: widget.roleId);
      }
    });
  }

  bool _isOAuthSignIn(Session session) {
    final identities = session.user.identities ?? [];
    return identities
        .any((id) => id.provider == 'google' || id.provider == 'apple');
  }

  @override
  void dispose() {
    _authSub?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _signIn(BuildContext blocContext) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    blocContext.read<AuthCubit>().login(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
  }

  Future<void> _onAuthAuthenticated(UserEntity user) async {
    final userId = user.id;
    final role = user.role.name;

    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    final metadataRole = metadata?['role'] as String?;
    final profileResp = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    String resolvedRole;
    if (metadataRole != null && profileResp?['role'] != metadataRole) {
      resolvedRole = metadataRole;
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'role': resolvedRole,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      });
    } else if (profileResp != null) {
      resolvedRole = profileResp['role'] as String;
    } else {
      resolvedRole = metadataRole ?? role;
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'role': resolvedRole,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    if (!mounted) return;

    String status = 'approved';
    if (resolvedRole == 'doctor') {
      final doctorResp = await Supabase.instance.client
          .from('doctors')
          .select('status')
          .eq('id', userId)
          .maybeSingle();
      status = doctorResp?['status'] as String? ?? 'pending';
    }

    await FcmService.saveCurrentUserToken();

    if (!mounted) return;

    await navigateToRoleScreen(
      context: context,
      role: resolvedRole,
      status: status,
      userId: userId,
      patientRoleId: widget.roleId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocConsumer<AuthCubit, auth.AuthState>(
        listener: (context, state) {
          if (state is auth.AuthAuthenticated) {
            _onAuthAuthenticated(state.user);
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
                title: Text(
                  currentRole.id.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(40),
                      LoginHeader(role: currentRole),
                      const Gap(32),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter your email',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Gap(8),
                            CustomTextFormField(
                              controller: emailController,
                              hint: '${currentRole.id}@docara.com',
                              isPassword: false,
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
                            const Gap(20),
                            const CustomText(
                              text: 'Enter your password',
                              size: 15,
                              weight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            const Gap(8),
                            CustomTextFormField(
                              controller: passwordController,
                              hint: '••••••••',
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
                            const Gap(8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ForgotPassword(
                                        roleId: widget.roleId,
                                      ),
                                    ),
                                  );
                                },
                                child: CustomText(
                                  text: 'Forgot Password?',
                                  color: currentRole.color,
                                  weight: FontWeight.w600,
                                  size: 14,
                                  align: TextAlign.end,
                                ),
                              ),
                            ),
                            const Gap(20),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : () => _signIn(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentRole.color,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? const AppPulseDot(
                                        size: 20, color: Colors.white)
                                    : const CustomText(
                                        text: 'Sign In',
                                        size: 17,
                                        weight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(24),
                      if (currentRole.id == 'doctor' ||
                          currentRole.id == 'patient') ...[
                        SocialLoginSection(
                          onGoogleTap: () {
                            _awaitingOAuth = true;
                            signInWithOAuthProvider(
                              context,
                              OAuthProvider.google,
                            );
                            Future.delayed(const Duration(seconds: 15), () {
                              if (mounted) _awaitingOAuth = false;
                            });
                          },
                          onAppleTap: () {
                            _awaitingOAuth = true;
                            signInWithOAuthProvider(
                              context,
                              OAuthProvider.apple,
                            );
                            Future.delayed(const Duration(seconds: 15), () {
                              if (mounted) _awaitingOAuth = false;
                            });
                          },
                        ),
                        const Gap(24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              text: "Don't have an account?",
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SignupPage(
                                        roleId: widget.roleId,
                                      ),
                                    ),
                                  );
                                },
                                child: CustomText(
                                  text: 'Sign Up',
                                  color: currentRole.color,
                                  weight: FontWeight.w600,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Gap(16),
                      if (currentRole.id == 'admin') const AdminSecurityNotice(),
                      const Gap(10),
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
