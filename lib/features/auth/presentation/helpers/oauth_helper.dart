import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:medical_booking_app/shared/widgets/custom_snackbar_helper.dart';
import 'auth_navigation.dart';
import '../pages/doctor_onboarding/doctor_specialty_screen.dart';

Future<void> signInWithOAuthProvider(
  BuildContext context,
  OAuthProvider provider,
) async {
  try {
    final datasource = sl<AuthRemoteDatasource>();
    final res = await datasource.getOAuthSignInUrl(
      provider: provider,
      redirectTo:
          kIsWeb ? null : 'com.medicalbooking.app://login-callback',
      queryParams: provider == OAuthProvider.google
          ? {'prompt': 'select_account'}
          : null,
    );

    final uri = Uri.parse(res.url);

    if (kIsWeb) {
      await launchUrl(uri, mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_self');
    } else {
      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: uri.toString(),
        callbackUrlScheme: 'com.medicalbooking.app',
        options: const FlutterWebAuth2Options(preferEphemeral: false),
      );
      final callbackUri = Uri.parse(callbackUrl);
      await datasource.getSessionFromUrl(callbackUri);
    }
  } on AuthException catch (e) {
    if (!context.mounted) return;
    final message = e.message.contains('not enabled')
        ? '${provider.name} sign-in is not enabled. Enable it in Supabase Dashboard → Authentication → Providers.'
        : e.message;
    CustomSnackBarHelper.show(
      context,
      message: message,
      isSuccess: false,
    );
  } catch (e) {
    debugPrint('signInWithOAuth error: $e');
    if (!context.mounted) return;
    CustomSnackBarHelper.show(
      context,
      message: 'Failed to sign in: ${e.toString()}',
      isSuccess: false,
    );
  }
}

Future<void> handlePostOAuthSignIn(
  BuildContext context, {
  required String roleId,
}) async {
  debugPrint('>>> [OAUTH_HELPER] handlePostOAuthSignIn called with roleId=$roleId');
  final datasource = sl<AuthRemoteDatasource>();
  final session = datasource.currentSession;
  if (session == null) {
    debugPrint('>>> [OAUTH_HELPER] session is null, returning');
    return;
  }

  try {
    final profileResp = await datasource.getProfileRole(session.user.id);

    debugPrint('>>> [OAUTH_HELPER] profiles query result (for reference): $profileResp');

    // Always upsert the user-selected roleId to overwrite any
    // trigger-created profiles row (which defaults to 'patient').
    final metadata = session.user.userMetadata;
    final fullName = metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        'User';

    await datasource.upsertProfile({
      'id': session.user.id,
      'role': roleId,
      'full_name': fullName,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    });

    if (!context.mounted) return;

    if (roleId == 'doctor') {
      final doctorResp = await datasource.getDoctorStatus(session.user.id);
      if (doctorResp != null) {
        final status = doctorResp['status'] as String? ?? 'pending';
        debugPrint('>>> [OAUTH_HELPER] existing doctor → navigateToRoleScreen(status=$status)');
        await navigateToRoleScreen(
          context: context,
          role: 'doctor',
          status: status,
          userId: session.user.id,
          patientRoleId: 'patient',
        );
      } else {
        debugPrint('>>> [OAUTH_HELPER] new doctor → DoctorSpecialtyScreen');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const DoctorSpecialtyScreen(),
          ),
          (route) => false,
        );
      }
    } else {
      debugPrint('>>> [OAUTH_HELPER] navigating to: navigateToRoleScreen(role=$roleId, status=approved)');
      await navigateToRoleScreen(
        context: context,
        role: roleId,
        status: 'approved',
        userId: session.user.id,
        patientRoleId: 'patient',
      );
    }
  } catch (e) {
    debugPrint('postOAuth error: $e');
    if (!context.mounted) return;
    CustomSnackBarHelper.show(
      context,
      message: 'Unable to complete sign-in. Please try again.',
      isSuccess: false,
    );
  }
}
