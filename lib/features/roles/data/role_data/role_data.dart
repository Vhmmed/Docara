import '../../presentation/page/admin_screen.dart';
import '../../presentation/page/doctor_screen.dart';
import '../../presentation/page/patient_screen.dart';


final roles = [
  {
    "id": "patient",
    "title": "Patient",
    "desc": "Book appointments, chat with doctors, view medical records",
    "icon": "assets/images/user.svg",
    "screen": const PatientScreen(
      roleId: 'patient',
    ),
  },
  {
    "id": "doctor",
    "title": "Doctor",
    "desc": "Manage consultations, view patients, write prescriptions",
    "icon": "assets/images/stethoscope.svg",
    "screen": DoctorScreen(),
  },
  {
    "id": "admin",
    "title": "Admin",
    "desc": "Manage users, doctors, and platform operations",
    "icon": "assets/images/security-safe-svgrepo-com.svg",
    "screen": const AdminScreen(),
  },
];