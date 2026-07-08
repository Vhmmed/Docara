# Medical Booking App — Clean Architecture

## Structure
```
lib/
├── main.dart
├── core/
│   ├── constants/    # API endpoints, app constants
│   ├── di/           # GetIt dependency injection
│   ├── errors/       # Failure & Exception classes
│   ├── network/      # Dio client + interceptors
│   ├── router/       # GoRouter configuration
│   ├── theme/        # Light & dark themes
│   └── utils/        # UseCase base class, helpers
├── features/
│   ├── auth/
│   ├── doctor_discovery/
│   ├── appointments/
│   ├── ai_features/
│   ├── payments/
│   ├── chat/
│   ├── medical_records/
│   ├── doctor_profile/
│   ├── admin/
│   ├── notifications/
│   └── reviews/
└── shared/
    ├── widgets/      # Reusable UI components
    ├── models/       # Shared data models
    ├── mixins/
    └── extensions/
```

## Each Feature Pattern
```
feature/
├── data/
│   ├── datasources/   # Remote & Local data sources
│   ├── models/        # DTOs (extend entities)
│   └── repositories/  # Repository implementations
├── domain/
│   ├── entities/      # Pure Dart business objects
│   ├── repositories/  # Abstract interfaces
│   └── usecases/      # One class per use case
├── presentation/
│   ├── cubits/        # State management
│   ├── pages/         # Full screens
│   └── widgets/       # Feature-specific widgets
└── di/
    └── *_injection.dart
```

## Key Packages
- State: `flutter_bloc` + `equatable`
- DI: `get_it`
- Network: `dio` + `retrofit`
- Navigation: `go_router`
- Errors: `dartz` (Either<Failure, T>)
- Local: `hive_flutter` + `flutter_secure_storage`

## Getting Started
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```
