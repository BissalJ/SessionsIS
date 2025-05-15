# Fingerprint Auth App

A secure, modern attendance management system for educational institutions, leveraging biometric authentication, QR code-based session management, and Firebase integration. Designed for faculty (professors) to create, manage, and export attendance records efficiently and securely.

## Project Description

**Fingerprint Auth App** is a Flutter-based application that enables professors to:

- **Register and log in** securely (restricted to faculty emails containing "prof").
- **Create attendance sessions** for classes, specifying class ID, subject, and session duration.
- **Generate secure QR codes** for each session, which students scan to mark their attendance.
- **Leverage cryptographic security**: Each session uses RSA key pairs and digital signatures to ensure authenticity and prevent spoofing.
- **View and export attendance**: Professors can view real-time attendance lists and export them as CSV files for record-keeping or sharing.
- **Firebase integration**: All authentication, session, and attendance data are securely stored and managed using Firebase services.

### Key Features

- **Faculty-only access**: Only users with emails containing "prof" and the correct admin role can register and log in.
- **Session creation**: Professors can create new attendance sessions with custom details.
- **QR code attendance**: Each session generates a unique, signed QR code for students to scan.
- **Cryptographic security**: Uses RSA key pairs and digital signatures for session validation.
- **Attendance export**: Download attendance records as CSV files directly from the app.
- **Modern UI**: Clean, responsive, and user-friendly interface.

---

## Setup Instructions

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.2.3 <4.0.0)
- [Firebase account](https://firebase.google.com/)
- Platform-specific requirements for [Android](https://docs.flutter.dev/get-started/install), [iOS](https://docs.flutter.dev/get-started/install/macos), [Web](https://docs.flutter.dev/platform-integration/web), etc.

### 1. Clone the Repository

```bash
git clone https://github.com/BissalJ/SessionsIS
cd SessionsIS
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

1. **Create a Firebase project** in the [Firebase Console](https://console.firebase.google.com/).
2. **Register your app** (Android, iOS, Web, etc.) in the Firebase project settings.
3. **Download the configuration files**:
   - For Android: `google-services.json` → place in `android/app/`
   - For iOS: `GoogleService-Info.plist` → place in `ios/Runner/`
   - For Web: Update `lib/firebase_options.dart` using the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
4. **Enable Firebase services**:
   - Authentication (Email/Password)
   - Firestore Database
   - (Optional) Realtime Database, Storage, Functions as needed

### 4. Run the App

```bash
flutter run
```

### 5. Usage

- **Register as a professor**: Use the "Register as Professor" option. Only emails containing "prof" are allowed.
- **Log in**: Use your registered professor credentials.
- **Create a session**: Enter class details and duration, then generate a QR code.
- **Students scan the QR code** (student app/feature not included in this repo).
- **View attendance**: See real-time attendance and export as CSV.

---

## Project Structure

```
lib/
  main.dart                  # App entry point
  login_screen.dart          # Professor login UI and logic
  register_page.dart         # Professor registration UI and logic
  create_session_screen.dart # Session creation and QR code generation
  attendance_list_screen.dart# Attendance viewing and export
  secure_identification.dart # RSA key generation, signing, and verification
  auth_service.dart          # Authentication service abstraction
  firebase_options.dart      # Firebase config (auto-generated)
```

---

## Dependencies

Key packages used:

- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_database`, `firebase_storage`, `cloud_functions`
- `local_auth` (biometric/fingerprint support)
- `pointycastle`, `crypto`, `encrypt` (cryptography)
- `qr_flutter` (QR code generation)
- `csv`, `share_plus`, `path_provider` (export and sharing)
- `flutter_secure_storage`, `shared_preferences` (secure local storage)

See `pubspec.yaml` for the full list.

---

## Notes

- This app is intended for faculty use only. Student-side attendance marking (QR scan, etc.) is not included in this repository.
- Ensure your Firebase rules are set up securely for production.
- For production, consider additional security, error handling, and UI polish.
