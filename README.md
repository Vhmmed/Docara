# Docara — Medical Booking Application

A cross-platform Flutter application connecting patients with doctors through real-time chat, appointment booking, and medical record management.

## Features

### For Patients
- **Find & book doctors** — Browse available doctors by specialty, view profiles, and book appointments
- **Real-time chat** — Messaging with doctors via Supabase Realtime with typing indicators and online presence
- **Medical records access** — View consultation notes, prescriptions, and visit history
- **Appointment management** — View upcoming appointments, cancel or reschedule
- **In-app notifications** — Receive real-time alerts for new messages and appointment updates

### For Doctors
- **Dashboard** — Aggregated stats: total patients, monthly appointments, revenue breakdown
- **Patient management** — View patient history, names, visit counts, last visit dates
- **Appointment calendar** — Manage schedule, accept or decline bookings
- **Document sharing** — Upload and share documents with signed URL access
- **Consultation notes** — Create and manage patient medical records with follow-up tracking

### For Admins
- **Doctor verification** — Review and approve doctor applications
- **User management** — Oversee platform activity and appointments
- **Dashboard analytics** — Platform-wide statistics

### General
- **Role-based UI** — Tailored experience for patients, doctors, and admins
- **Glassmorphism design** — Modern frosted-glass aesthetic with backdrop blur
- **Secure auth** — Email/password login with Supabase authentication
- **Onboarding flow** — Guided introduction for first-time users
- **Push notifications** — Firebase Cloud Messaging integration

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart) |
| **State Management** | flutter_bloc (Cubits) + equatable |
| **Dependency Injection** | get_it |
| **Backend** | Supabase (PostgreSQL, Realtime, Auth, Storage) |
| **Networking** | Dio HTTP client |
| **Navigation** | GoRouter |
| **Push Notifications** | Firebase Cloud Messaging |
| **Error Handling** | dartz (Either type) |
| **Fonts** | IBM Plex Sans / IBM Plex Sans Arabic |

## Architecture

Clean Architecture with feature-based modular structure:

```
lib/
├── core/              # Shared infrastructure
│   ├── constants/
│   ├── di/            # GetIt injection container
│   ├── errors/        # Failure & Exception classes
│   ├── network/       # Dio client, interceptors
│   ├── router/        # GoRouter configuration
│   ├── services/      # Presence, notifications, FCM
│   ├── theme/         # Light & dark themes
│   └── utils/         # Helpers, UseCase base class
├── features/          # 10 feature modules
│   ├── auth/          # Authentication, profiles, onboarding
│   ├── appointments/  # Booking, cancellation, listing
│   ├── chat/          # Real-time messaging, conversations
│   ├── roles/         # Patient/doctor/admin screens
│   ├── medical_records/ # Consultation notes, records
│   ├── notifications/ # In-app notification management
│   ├── schedule/      # Availability and slot management
│   └── ...            # ai_features, payments, reviews
├── onboarding/        # First-time user onboarding
├── shared/            # Reusable widgets (loading, states, buttons)
└── main.dart          # App entry point
```

Each feature follows a consistent pattern:

```
feature/
├── data/
│   ├── datasources/    # Remote data sources (Supabase)
│   ├── models/         # Data transfer objects
│   └── repositories/   # Repository implementations
├── domain/
│   ├── entities/       # Business objects
│   ├── repositories/   # Abstract interfaces
│   └── usecases/       # Single-responsibility use cases
├── presentation/
│   ├── cubits/         # State management
│   ├── pages/          # Full screens
│   └── widgets/        # Feature-specific UI components
└── di/                 # Module dependency injection
```

## Screenshots

<!-- TODO: Add application screenshots -->
<!-- | Home | Chat | Appointments | Profile |
|------|------|-------------|---------|
| img  | img  | img         | img     | -->

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- iOS 12+ or Android 5.0+
- Supabase project (configured with schema from `supabase_schema.sql`)
- Firebase project (for push notifications)

### Setup

```bash
# Clone the repository
git clone https://github.com/Vhmmed/Docara.git
cd Docara

# Install dependencies
flutter pub get

# Configure environment
# Copy .env.example to .env and fill in your Supabase credentials
# Configure Firebase (if using push notifications)

# Run the app
flutter run
```

### Code Generation

Some features use code generation. Run this command if you add annotations:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Project Status

**In development** — Core features are functional and demo-ready. Some features are still being built out.

### What's Working
- [x] Real-time chat with Supabase Realtime
- [x] Online presence tracking
- [x] In-app notification banners
- [x] Doctor dashboard with stats aggregation
- [x] Patient appointment booking flow
- [x] Glassmorphism UI shell
- [x] Role-based navigation (patient/doctor/admin)
- [x] Doctor verification workflow
- [x] Medical record creation and viewing

### In Progress
- [ ] Push notification setup (FCM configured, backend pending)
- [ ] Payment integration
- [ ] AI symptom checker
- [ ] End-to-end testing

## License

<!-- TODO: Add license information -->
