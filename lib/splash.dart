import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'core/di/injection_container.dart';
import 'core/services/fcm_service.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/presentation/helpers/auth_navigation.dart';
import 'onboarding/screens/onboarding_screen.dart';
import 'widgets/loading/loading_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _checkSessionAndNavigate();
      }
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    debugPrint('>>> [SPLASH] _checkSessionAndNavigate called');
    final datasource = sl<AuthRemoteDatasource>();
    final session = datasource.currentSession;
    if (session != null) {
      try {
        final metadata = datasource.currentUserMetadata;
        final metadataRole = metadata?['role'] as String?;

        final profileResp = await datasource.getProfileRole(session.user.id);

        if (!mounted) return;

        String role;
        if (profileResp != null) {
          role = profileResp['role'] as String;
        } else if (metadataRole != null) {
          role = metadataRole;
          await datasource.upsertProfile({
            'id': session.user.id,
            'role': role,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          });
        } else {
          if (!mounted) return;
          await datasource.signOut();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            ),
          );
          return;
        }

        String status = 'approved';
        if (role == 'doctor') {
          final doctorResp = await datasource.getDoctorStatus(session.user.id);
          status = doctorResp?['status'] as String? ?? 'pending';
        }

        await FcmService.saveCurrentUserToken();

        await navigateToRoleScreen(
          context: context,
          role: role,
          status: status,
          userId: session.user.id,
          patientRoleId: 'patient',
        );
        return;
      } catch (e) {
        final metadata = datasource.currentUserMetadata;
        final fallbackRole = metadata?['role'] as String?;
        if (fallbackRole != null && mounted) {
          await FcmService.saveCurrentUserToken();

          await navigateToRoleScreen(
            context: context,
            role: fallbackRole,
            status: 'approved',
            userId: session.user.id,
            patientRoleId: 'patient',
          );
          return;
        }
        await datasource.signOut();
      }
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/LogoApp/last2.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey,
                              child: const Icon(
                                CupertinoIcons.photo,
                                size: 80,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const AppRingSpinner(),
          ],
        ),
      ),
    );
  }
}
