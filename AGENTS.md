# Medical-Booking-Application

Flutter medical booking app — Clean Architecture scaffold, mostly unimplemented stubs.

## Commands

```sh
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # codegen — never successfully run
flutter analyze              # lint (flutter_lints)
flutter run
flutter test                 # fails — no test/ directory exists
```

## Architecture Reality

- **10 features** under `lib/features/`. 4 have meaningful code:
  - `auth/` — domain entities/repos/usecases exist but DI is **commented out**; `role_model.dart` defines role data
  - `appointments/` — only feature with a **working Cubit** (`appointment_cubit.dart`)
  - `chat/` — fully functional real-time patient-doctor messaging via Supabase Realtime
  - `roles/` — UI screens (patient/doctor/admin), **breaks pattern** with inline `data/role_data/` accessed directly from UI
  - Remaining features are empty stubs (entities maybe, nothing wired)
- `lib/core/di/injection_container.dart` — `initDependencies()` registers all 10 feature DI modules
- GoRouter defined at `lib/core/router/app_router.dart` (only 2 routes: `/login`, `/appointments`) but **not wired into the app** — `main.dart` uses raw `MaterialApp` + `Navigator.pushReplacement`
- Onboarding at `lib/onboarding/` (top-level, not in features/)
- App flow: `SplashScreen` → `OnboardingScreen` → `RoleSelection` → `LoginPage`

## What's Wired

- **GlassNavShell** — glassmorphism navbar with per-screen `EdgeInsets.only(bottom: 108)` in PageView children; BackdropFilter blurs real page content
- **Doctor home stats** — `DoctorStatsService` fetches all appointments, aggregates in Dart (distinct patients, this-month count, completed month revenue); wired into `doctor_screen.dart` with loading/error/display states
- **Doctor Patients tab** — `DoctorPatientsTab` queries distinct patients from appointment history, shows name/count/last-visit; replaced `ComingSoonPlaceholder`
- **Document viewing** — `doctor_detail_sheet.dart`: real documents open signed URLs via `url_launcher`, mocked documents show snackbar
- **Chat/messaging** — `ChatService` at `lib/features/chat/data/` handles Supabase conversations + messages; realtime RealtimeChannel subscriptions update both MessagesPage and ChatDetailPage
- **Network/Storage** — `SupabaseStorageService` in `lib/core/network/` handles file upload/download; `UserService` used for login
- **DI wiring** — All 10 feature DI modules registered in `injection_container.dart` under `initDependencies()` (though only `appointments` module has actual registrations); `getIt.reset()` in `main.dart` before init
- **BookAppointmentSheet** (`lib/features/appointments/presentation/widgets/book_appointment_sheet.dart:11`) — self-contained; loads doctor list internally via `AppointmentService` (no longer depends on parent cubit). Accepts optional `BookCallback onBook` positional callback
- **AppointmentService** (`lib/features/appointments/data/appointment_service.dart`) — static methods (`bookAppointment`, `cancelAppointment`, `fetchDoctors`, `fetchAppointments`); no longer instantiated, accessed directly as `AppointmentService.method()`
- **Removed 7 unused deps**: `injectable`, `retrofit`, `hive_flutter`, `shared_preferences`, `agora_rtc_engine`, `freezed_annotation`, `json_annotation` (all zero usage post-cleanup)

## Key Gotchas

- **No `.g.dart` files**: codegen never run, annotations present but no generated output
- **Duplicate deps**: `flutter_svg` and `supabase_flutter` in both `dependencies` and `dev_dependencies`
- **No `.env` file**: API base URL hardcoded to `https://api.medicalbooking.com/v1` in `api_constants.dart`
- **No tests**: `flutter_test`, `mockito`, `bloc_test` in dev deps but no `test/` directory
- **GoRouter not wired**: defined but `main.dart` uses raw `MaterialApp` + `Navigator.pushReplacement`
- **DI init naming inconsistent**: `initAuth`, `initAppointments` (camelCase) vs `initmedical_records`, `initadmin` (snake_case)
- **Custom fonts**: IBM Plex Sans + IBM Plex Sans Arabic (migrated from Cairo/PlusJakartaSans) — configured in `pubspec.yaml`
- **Runtime pitfalls**:
  - `CustomScrollView.slivers` with conditional `if/else` swapping sliver types needs `ValueKey` on each branch or `!semantics.parentDataDirty` assertion fires
  - `Row` containing children with inner `Expanded`/flex widgets must wrap each child in `Expanded` (or constrain width) — otherwise `RenderFlex` unbounded-width error
