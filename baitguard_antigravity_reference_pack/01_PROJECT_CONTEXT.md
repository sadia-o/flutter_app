# BaitGaurd Project Context

## Product

BaitGaurd is a Flutter mobile application for an IoT smart rodent bait-station system
used in facilities such as warehouses, hospitals, hotels, factories, laboratories,
commercial buildings, and food-processing environments.

Physical stations include sensors and a camera. A rodent event can include:

- Station ID and location
- Rat, mouse, or no-detection classification
- Confidence score
- Captured evidence image
- Bait percentage
- Battery percentage
- Temperature and humidity where available
- Tamper state
- Connectivity and last-seen state
- Timestamp

## Full system architecture

The intended production system follows an edge-cloud-client architecture:

1. Edge station: ESP32-S3, PIR/IR sensing, IR camera, load cell, tamper switch,
   and on-device TFLite inference.
2. Connectivity: Wi-Fi primarily, with possible fallback options.
3. Cloud: Firebase Authentication, Firestore, Cloud Storage, Cloud Functions,
   and Firebase Cloud Messaging.
4. Clients: Flutter mobile application and React web dashboard using shared data.

## Current implementation state

The existing Flutter application is primarily a frontend prototype using hardcoded/mock data.

The current code includes:

- Overview/Home
- Stations
- Station Detail
- Alerts
- Alert Detail
- Reports
- Settings
- Admin screen

Firebase Core is initialized in the current code, but this redesign phase must not add or build
real backend behavior.

## Target architecture for the Flutter application

- Flutter and Dart
- Strict MVVM
- Provider as the only state-management solution
- Feature-first modular folder structure
- Repository interfaces
- Mock repository implementations during the frontend phase
- Centralized design tokens and ThemeData
- Reusable components
- Responsive layouts for a practical range of mobile screen sizes
- Light-mode application UI, except the intentionally dark splash screen and any dark visual
  sections explicitly shown in the target design

## Roles

The application should support the roles and role-specific experiences shown in the new target
screens. Use mock role/session state during the frontend phase.

The target screen set includes separate user and admin dashboard experiences. Role-based routing
must be designed cleanly so it can later connect to Firebase Authentication and backend roles.

## Later backend phase

After frontend completion, the mock repositories and mock authentication/session state will be
replaced with Firebase-backed implementations. The frontend architecture must make that future
replacement possible without rewriting the screens.
