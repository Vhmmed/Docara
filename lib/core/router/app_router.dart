import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/auth/login_page.dart';
import '../../features/appointments/presentation/pages/appointments_page.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String appointments = '/appointments';
  static const String doctorDetail = '/doctor/:id';
  static const String booking = '/booking/:doctorId';
  static const String chat = '/chat/:appointmentId';
  static const String adminDashboard = '/admin';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(path: login, builder: (_, __) => const LoginPage(roleId: 'id',)),
      GoRoute(path: appointments, builder: (_, __) => const AppointmentsPage()),
      // Add other routes here
    ],
  );
}
