<div align="center">
  <img src="https://github.com/Vhmmed/Docara/blob/main/assets/LogoApp/logo.jpg?raw=true" alt="Docara Logo" width="200" height="200" style="border-radius: 100%;" />
  
  # 🏥 Docara — Medical Booking Application
  
  <p align="center">
    <strong>Connecting patients with doctors seamlessly</strong><br>
    <em>Real-time chat · Appointment booking · Medical records management</em>
  </p>
  
  <!-- Badges -->
  <p align="center">
    <img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
    <img src="https://img.shields.io/badge/Supabase-Realtime-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
    <img src="https://img.shields.io/badge/State_Management-BLoC-007BFF?style=for-the-badge&logo=flutter&logoColor=white" />
    <img src="https://img.shields.io/badge/Platform-Android_·_iOS-9cf?style=for-the-badge" />
    <img src="https://img.shields.io/badge/Status-In_Development-yellow?style=for-the-badge" />
    <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
  </p>
  
  <p align="center">
    <a href="#-features">Features</a> •
    <a href="#-tech-stack">Tech Stack</a> •
    <a href="#-architecture">Architecture</a> •
    <a href="#-getting-started">Getting Started</a> •
    <a href="#-screenshots">Screenshots</a> •
    <a href="#-project-status">Project Status</a>
  </p>
</div>

---

## 📱 About Docara

Docara is a **cross-platform Flutter application** that bridges the gap between patients and healthcare providers. It offers a seamless experience for booking appointments, real-time communication, and managing medical records — all in one place.

> 💡 **Built with Clean Architecture** and powered by **Supabase Realtime** for instant updates.

---

## ✨ Features

### 👤 For Patients

| Feature | Description |
|---------|-------------|
| 🔍 **Find & Book Doctors** | Browse by specialty, view detailed profiles, and book appointments instantly |
| 💬 **Real-time Chat** | Messaging with doctors via Supabase Realtime with typing indicators & online presence |
| 📋 **Medical Records** | Access consultation notes, prescriptions, and visit history |
| 📅 **Appointment Management** | View upcoming appointments, cancel or reschedule with ease |
| 🔔 **In-app Notifications** | Real-time alerts for new messages and appointment updates |

### 👨‍⚕️ For Doctors

| Feature | Description |
|---------|-------------|
| 📊 **Dashboard** | Aggregated stats: total patients, monthly appointments, revenue breakdown |
| 👥 **Patient Management** | View patient history, names, visit counts, and last visit dates |
| 📆 **Appointment Calendar** | Manage schedule, accept or decline bookings |
| 📄 **Document Sharing** | Upload and share documents with signed URL access |
| 📝 **Consultation Notes** | Create and manage patient medical records with follow-up tracking |

### 🔐 For Admins

| Feature | Description |
|---------|-------------|
| ✅ **Doctor Verification** | Review and approve doctor applications |
| 👤 **User Management** | Oversee platform activity and appointments |
| 📈 **Dashboard Analytics** | Platform-wide statistics and insights |

### 🎨 General

- 🎭 **Role-based UI** — Tailored experience for patients, doctors, and admins
- 💎 **Glassmorphism Design** — Modern frosted-glass aesthetic with backdrop blur
- 🔐 **Secure Auth** — Email/password login with Supabase authentication
- 🚀 **Onboarding Flow** — Guided introduction for first-time users
- 📲 **Push Notifications** — Firebase Cloud Messaging integration

---

## 🛠️ Tech Stack

| Layer | Technology | Badge |
|-------|-----------|-------|
| **Framework** | Flutter (Dart) | ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white) |
| **State Management** | flutter_bloc (Cubits) + equatable | ![BLoC](https://img.shields.io/badge/BLoC-007BFF?style=flat-square&logo=flutter&logoColor=white) |
| **DI** | get_it | ![GetIt](https://img.shields.io/badge/GetIt-5C2D91?style=flat-square&logo=dart&logoColor=white) |
| **Backend** | Supabase (PostgreSQL, Realtime, Auth, Storage) | ![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white) |
| **Networking** | Dio HTTP client | ![Dio](https://img.shields.io/badge/Dio-6C5B7B?style=flat-square&logo=dart&logoColor=white) |
| **Navigation** | GoRouter | ![GoRouter](https://img.shields.io/badge/GoRouter-00BCD4?style=flat-square&logo=flutter&logoColor=white) |
| **Push Notifications** | Firebase Cloud Messaging | ![FCM](https://img.shields.io/badge/FCM-FFCA28?style=flat-square&logo=firebase&logoColor=black) |
| **Error Handling** | dartz (Either type) | ![Dartz](https://img.shields.io/badge/Dartz-FF6B6B?style=flat-square&logo=dart&logoColor=white) |
| **Fonts** | IBM Plex Sans / IBM Plex Sans Arabic | ![Font](https://img.shields.io/badge/IBM_Plex-0078D4?style=flat-square&logo=ibm&logoColor=white) |

---

## 🧱 Architecture

### Clean Architecture with Feature-based Modular Structure

```text
lib/
├── core/                    # Shared infrastructure
│   ├── constants/           # App constants
│   ├── di/                  # GetIt injection container
│   ├── errors/              # Failure & Exception classes
│   ├── network/             # Dio client, interceptors
│   ├── router/              # GoRouter configuration
│   ├── services/            # Presence, notifications, FCM
│   ├── theme/               # Light & dark themes
│   └── utils/               # Helpers, UseCase base class
│
├── features/                # Feature modules (10+)
│   ├── auth/                # Authentication, profiles, onboarding
│   ├── appointments/        # Booking, cancellation, listing
│   ├── chat/                # Real-time messaging, conversations
│   ├── roles/               # Patient/doctor/admin screens
│   ├── medical_records/     # Consultation notes, records
│   ├── notifications/       # In-app notification management
│   ├── schedule/            # Availability and slot management
│   ├── ai_features/         # AI symptom checker
│   ├── payments/            # Payment integration
│   └── reviews/             # Doctor reviews & ratings
│
├── onboarding/              # First-time user onboarding
├── shared/                  # Reusable widgets (loading, states, buttons)
└── main.dart                # App entry point
```

### Feature Module Structure

Each feature follows a consistent pattern:

```text
feature/
├── data/
│   ├── datasources/     # Remote data sources (Supabase)
│   ├── models/          # Data transfer objects
│   └── repositories/    # Repository implementations
├── domain/
│   ├── entities/        # Business objects
│   ├── repositories/    # Abstract interfaces
│   └── usecases/        # Single-responsibility use cases
├── presentation/
│   ├── cubits/          # State management
│   ├── pages/           # Full screens
│   └── widgets/         # Feature-specific UI components
└── di/                  # Module dependency injection
```

---

## 📸 Screenshots

<p align="center">
  <em>🚧 Screenshots coming soon! 🚧</em>
</p>

<!-- Add your screenshots here -->
<!-- 
| Home | Chat | Appointments | Profile |
|------|------|-------------|---------|
| <img src="screenshots/home.png" width="200" /> | <img src="screenshots/chat.png" width="200" /> | <img src="screenshots/appointments.png" width="200" /> | <img src="screenshots/profile.png" width="200" /> |
-->

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- iOS 12+ or Android 5.0+
- Supabase project (configured with schema from `supabase_schema.sql`)
- Firebase project (for push notifications)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Vhmmed/Docara.git
cd Docara

# 2. Install dependencies
flutter pub get

# 3. Configure environment
# Copy .env.example to .env and fill in your Supabase credentials
cp .env.example .env

# 4. Configure Firebase (if using push notifications)
# Follow Firebase setup guide for Flutter

# 5. Run the app
flutter run
```

### Code Generation

Some features use code generation. Run this command if you add annotations:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📊 Project Status

🟡 **In Development** — Core features are functional and demo-ready. Some features are still being built out.

### ✅ What's Working

- Real-time chat with Supabase Realtime
- Online presence tracking (typing indicators, user status)
- In-app notification banners
- Doctor dashboard with stats aggregation
- Patient appointment booking flow
- Glassmorphism UI shell
- Role-based navigation (patient/doctor/admin)
- Doctor verification workflow
- Medical record creation and viewing
- Authentication (email/password with Supabase)
- Onboarding flow for first-time users

### ⏳ In Progress

- Push notification setup (FCM configured, backend pending)
- Payment integration (stripe/other)
- AI symptom checker
- End-to-end testing
- Doctor reviews & ratings
- Video consultation integration

### 🔮 Planned

- Multi-language support (Arabic/English)
- Dark/Light theme toggle
- Offline mode with local storage
- Patient health tracking
- Prescription scanning via OCR

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Supabase](https://supabase.com) — Open-source Firebase alternative
- [Flutter](https://flutter.dev) — UI toolkit for beautiful natively compiled apps
- [BLoC Pattern](https://bloclibrary.dev) — Predictable state management
- [IBM Plex Fonts](https://www.ibm.com/plex/) — Beautiful typography

---

## 📬 Contact

**Ahmed Adel**

- [💼 LinkedIn](https://www.linkedin.com/in/ahmedaaddel)
- [📧 Email](mailto:ahmedelazab.co@gmail.com)
- [🐙 GitHub](https://github.com/Vhmmed)

---

<div align="center">
  <p>
    <strong>⭐ If you like this project, give it a star! ⭐</strong>
  </p>
  <p>
    <sub>Built with ❤️ by Ahmed Adel</sub>
  </p>
</div>
