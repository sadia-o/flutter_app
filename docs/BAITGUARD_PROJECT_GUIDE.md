# Bait Guard Project Guide

## 1. Document purpose

This is the detailed technical and product handover for the current Bait Guard
Flutter application. It is intended for supervisors, developers, interns,
testers, and future maintainers.

The current codebase is the source of truth. This guide describes implemented
behavior, identifies mock/real boundaries, and avoids presenting deferred
backend work as complete.

## 2. Product overview

Bait Guard is a smart rodent bait-station monitoring application for
warehouses, hospitals, hotels, commercial buildings, cold storage,
manufacturing sites, and similar facilities.

The intended end-to-end product flow is:

1. A motion or infrared sensor detects activity.
2. A camera captures evidence.
3. An on-device YOLOv8-nano/TFLite model classifies the evidence as rodent or
   non-rodent.
4. The device sends an event and associated evidence to the backend.
5. Bait Guard presents facility-scoped station health, alerts, evidence,
   trends, reports, and operational actions.

Only the Flutter application and its current Firebase identity/access layer are
implemented. ESP32 communication, RTDB/telemetry ingestion, production event
transport, model execution, and image persistence are deferred pending a
supervisor-confirmed contract.

There is no live video. Existing evidence and operational events are
static/mock.

## 3. Current project status

### Completed

- Android/iOS FlutterFire configuration and one-time Firebase initialization
- Firebase email/password login and logout
- Safe authenticated-session restoration
- Role-aware routing for Admin, Technician, and Viewer
- Forgot Password through Firebase Authentication
- Remember Me storing only the normalized email in SharedPreferences
- Request Access submission to Firestore
- Admin pending-request list and real dashboard pending counts
- Real request approval and rejection
- Approved applicant account activation with email verification
- Forced Firebase ID-token refresh before activation lookup
- Admin-created approved invitations
- Firestore-backed user profiles and Edit Profile
- Firebase reauthentication and Change Password
- System Management overview
- Full Firestore-backed User Management list
- Read-only User Details
- Managed Technician/Viewer role, facility, and application-status changes
- Admin/User dashboards
- Stations, Alerts, Reports, and complete Settings frontend
- Android display name and launcher icon

### Real Firebase-backed areas

- Firebase Core bootstrap
- Authentication identity and session
- Password reset and password change
- Email verification
- `users` profile reads and permitted self/admin updates
- `accessRequests` creation, admin reads, approval/rejection, invitations, and
  activation
- Pending-request dashboard counts

### Mock-backed areas

- Dashboard operational metrics, charts, station health, maps, and detections
- Station records, registration, details, and mutations
- Alerts, evidence, charts, hotspots, and role actions
- Reports, generated exports, trends, and station ledger
- Facility/site records and friendly labels
- Settings preferences and administrator contact/send simulation
- Site Management summary

The project deliberately combines real authenticated identity/facility
permissions with mock operational records. Mock operational repositories use
the real signed-in `AppUser` or its `facilityIds`; they must not require the
Firebase UID to exist among seeded mock users.

## 4. Technology and dependencies

Core dependencies from `pubspec.yaml`:

- Flutter
- Dart SDK `^3.8.1`
- `provider`
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `shared_preferences`
- `fl_chart`
- `intl`
- `google_fonts`

Development tooling includes Flutter tests/lints, native splash configuration,
and Android launcher-icon generation.

The package name is `baitguard`, version `1.0.0+1`.

## 5. Architecture

### 5.1 Provider + MVVM

The application uses Provider for dependency exposure and `ChangeNotifier`
ViewModels for presentation state.

Typical flow:

```text
Screen
  → feature ViewModel
    → domain repository interface
      → Firebase, preferences, or mock implementation
        → external/local data source
```

Screens:

- Render state.
- Collect user input.
- Trigger ViewModel methods.
- Handle navigation and one-time presentation feedback.
- Do not call Firebase directly.

ViewModels:

- Own screen-specific state, validation, loading, and safe error messages.
- Depend on repository interfaces and session controllers through constructor
  injection.
- Must not expose Firebase SDK objects.

Repositories:

- Define domain-safe boundaries under `lib/domain/repositories`.
- Translate Firebase SDK errors/types inside `lib/data/repositories/firebase`.
- Provide mock implementations under `lib/data/repositories/mock`.
- Provide local remembered-email persistence under
  `lib/data/repositories/preferences`.

### 5.2 Feature-first organization

Important directories:

```text
lib/
  app/
    navigation/
    state/
    theme/
  core/
    widgets/
  domain/
    models/
    repositories/
  data/
    repositories/
      firebase/
      mock/
      preferences/
  features/
    admin/
    alerts/
    authentication/
    dashboard/
    navigation/
    onboarding/
    reports/
    settings/
    splash/
    stations/
```

Features generally contain `views`, `view_models`, `widgets`, and feature-local
models/navigation where required.

### 5.3 Dependency injection

`AppProviders.providers` creates the global dependency graph with
`MultiProvider`.

Global providers include:

- Shared seeded `MockBaitGuardDataSource`
- `FirebaseAuthRepository`
- `FirestoreUserRepository`
- `FirestoreAccessRequestRepository`
- `FirestoreAccountActivationRepository`
- `SharedPreferencesLoginRepository`
- Mock operational repositories
- `AppSessionController`
- Eager `AuthSessionCoordinator`

Route-owned ViewModels are created with `ChangeNotifierProvider(create: ...)`.
Existing shared `ChangeNotifier` instances are re-exposed with
`ChangeNotifierProvider.value` when ownership remains elsewhere.

No service locator is used.

## 6. Session, roles, and facility access

### 6.1 Session

`AppSessionController` is the single reactive source for the signed-in
application user. It contains a domain `AppUser`, not a Firebase `User`.

`AuthSessionCoordinator`:

- Checks Firebase's persisted identity at startup.
- Loads `users/{firebaseUid}`.
- Validates UID and active status.
- Establishes `AppSessionController` only after complete validation.
- Signs out and clears the application session for missing, malformed, or
  disabled profiles.

Profile changes update `AppSessionController`, so Settings and dashboards
react immediately.

### 6.2 Roles

Recognized roles:

- `admin`
- `technician`
- `viewer`

Unknown roles are rejected; there is no role inference from email and no
default Admin fallback.

#### Admin

- Uses the Admin shell.
- Reviews pending access requests.
- Approves/rejects requests.
- Creates approved invitations.
- Lists users.
- Reads user details.
- Changes Technician/Viewer role, facility assignments, and application status.
- Cannot manage Admin profiles or self through Manage User.
- Has operational/admin report permissions.

#### Technician

- Uses the shared User shell.
- Has permitted operational actions and report generation.
- Cannot generate Compliance Audit.
- Cannot access admin user/request management.

#### Viewer

- Uses the shared User shell.
- Has read-only operational permissions.
- Can edit personal profile and preferences.
- Cannot access admin user/request management.

### 6.3 Facility permissions

`AppUser.siteAccessIds` maps to Firestore `facilityIds`.

`ActiveFacilityController`:

- Is created once per authenticated shell.
- Contains permitted IDs and current operational selection.
- Must not be duplicated inside tabs or Settings.
- Is passed into the root Settings flow using Provider `.value`.

All operational features must filter by permitted facilities. Empty access
remains empty; the app must not grant every facility automatically.

Facility records are currently mock-backed. Current seeded IDs include
`site_1` through `site_5`, with friendly labels such as Warehouse A,
Warehouse B, Distribution Center, Cold Storage, and Manufacturing Plant.
Do not treat these IDs as a finalized production facility schema.

## 7. Navigation

### 7.1 Root navigation

The application uses a custom `AppRouter.onGenerateRoute` and named
`RouteNames`.

Primary unauthenticated flow:

```text
Splash
  ├─ restored active session → role shell
  └─ no valid session → Welcome → Login
                              ├─ Forgot Password
                              ├─ Request Access → Request Submitted
                              └─ Activate Account
```

### 7.2 Authenticated shells

Admin and User shells own an `IndexedStack` with persistent bottom navigation:

1. Dashboard
2. Stations
3. Alerts
4. Reports

Stations, Alerts, and Reports have nested flows. The Admin Dashboard owns an
additional nested Navigator for:

- Pending Requests
- Approve Request
- System Management
- Add User
- User Management
- User Details
- Manage User

These routes keep `AdminAppShell`, its bottom navigation, dashboard state, and
selected tab mounted.

Settings is a shared root overlay for every authenticated role. It preserves
the originating shell below it and receives the existing shell-owned
`ActiveFacilityController`.

## 8. Firebase setup

Current configuration:

| Setting | Value |
|---|---|
| Firebase project | `bait-guard-6f470` |
| Android application ID | `com.example.my_first_app` |
| iOS bundle ID in FlutterFire options | `com.example.myFirstApp` |
| Configured platforms | Android and iOS |
| Active development/testing | Android |
| Android minimum SDK | 23 |
| Android display name | `Bait Guard` |

Relevant files:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- Android Google Services Gradle configuration
- `lib/main.dart`

Firebase is initialized exactly once before `runApp`:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
runApp(const BaitGuardApp());
```

Web, Windows, Linux, and macOS are not configured in
`DefaultFirebaseOptions.currentPlatform`.

## 9. Authentication flows

### 9.1 Login

1. Normalize and locally validate email.
2. Sign in through `AuthRepository`.
3. Load `users/{uid}` through `UserRepository`.
4. Validate UID, role, status, and facility IDs.
5. Reject disabled/malformed/missing profiles and sign out the Firebase
   identity.
6. Establish `AppSessionController`.
7. Route Admin to Admin shell; Technician/Viewer to User shell.

Firebase exceptions are translated to domain-safe messages. Firestore/profile
failures are not reported as invalid credentials.

### 9.2 Remember Me

Remember Me stores:

- A boolean preference.
- The normalized email when enabled.

It never stores:

- Password
- Firebase ID/refresh token
- Authentication cookies
- Raw credentials

Firebase Auth independently persists its native authenticated session.

### 9.3 Forgot and change password

- Forgot Password uses Firebase's default password-reset email flow and a
  privacy-safe generic success message.
- Change Password reauthenticates using the current password and then updates
  the Firebase password.
- Passwords remain form-only and are never written to Firestore or mock data.

### 9.4 Edit Profile

Self-editable fields:

- `firstName`
- `lastName`
- generated `displayName`
- `jobTitle`
- `department`
- `phone`
- `bio`
- server-owned `updatedAt`

Protected fields include UID, email, role, status, facility IDs, company,
creation/activation metadata.

Optional profile fields are persisted as trimmed strings, including `""`, to
remain compatible with Firestore rules.

## 10. Access request and activation lifecycle

### 10.1 Public Request Access

The unauthenticated Request Access form collects:

- Full name
- Company email
- Company/organisation
- Phone
- Optional department
- Optional message

It creates `accessRequests/{autoId}` directly through Firestore with strict
create-only rules. Applicants cannot read/list/update/delete requests.

Because the project must remain on Spark and has no trusted backend,
unauthenticated duplicate checking is intentionally deferred. Multiple pending
requests for the same normalized email can exist.

### 10.2 Admin approval and rejection

Active Admins can read pending requests.

Approval:

- Assigns Technician or Viewer.
- Assigns one or more facility IDs.
- Stores reviewer metadata and `approvalSource: "request"`.
- Does not create an Auth account or user profile.

Rejection:

- Stores `status: "rejected"`.
- Stores reviewer metadata and optional reason.
- Does not delete the request.

Transactions require the request to remain pending, protecting against stale
or concurrent review.

### 10.3 Add User invitation

Add User creates an already-approved invitation with
`approvalSource: "admin"`.

The Admin selects:

- Applicant identity/contact fields
- Technician or Viewer role
- Facilities

No Firebase Auth account or `users` profile is created at this stage.

The client checks for existing users, pending requests, and unused approved
invitations. Without a trusted backend, this client-side duplicate check can
race and is not a global uniqueness guarantee.

### 10.4 Account activation

1. Applicant opens Activate Account with the approved email.
2. The client creates a Firebase email/password account, or signs into an
   existing matching account.
3. Firebase sends an email-verification message.
4. After verification, the app reloads the Firebase user.
5. The app force-refreshes the Firebase ID token so Firestore Rules see
   `email_verified == true`.
6. It queries an unused approved invitation matching the authenticated,
   normalized Firebase email.
7. A transaction creates `users/{firebaseUid}` and marks the invitation
   activated.
8. The created profile establishes the application session.

Activation accepts `approvalSource` values `request` and `admin`. It never
accepts Admin as an assigned role.

The activation query requires the composite index documented in Section 13.

## 11. Multiple Admins and manual Admin creation

The application supports multiple active Admin profiles. Each active Admin can
read users/access requests and perform the allowed admin operations.

The client deliberately cannot:

- Promote a Technician/Viewer to Admin.
- Create an Admin invitation.
- Edit or demote an Admin profile.
- Create/delete Firebase Auth users on behalf of others.

To bootstrap another Admin, an authorized Firebase project operator must
manually:

1. Create the email/password user in Firebase Authentication.
2. Copy the Firebase UID.
3. Create `users/{uid}` in Firestore with at least:

```text
uid: same Firebase UID and document ID
displayName: non-empty string
email: normalized email
role: "admin"
status: "active"
facilityIds: list of permitted facility IDs
```

Optional profile fields may be added using the current `users` schema. This is
a privileged console operation; the mobile app and its security rules do not
provide Admin creation.

Carefully verify the UID/document-ID match. Never place Admin SDK credentials
or service-account JSON in the Flutter application.

## 12. User Management

### 12.1 Full list

Active Admins can open one shared User Management route from:

- Dashboard → Users
- System Management → View all users

It loads real `users` profiles through `UserRepository.getUsers()`.

Features:

- Active-first deterministic sorting
- Name/email search
- Role filter
- Status filter
- Full-dataset role/status counts
- Pull-to-refresh
- Loading, empty, no-result, permission, and network states
- Local filtering with no per-keystroke Firestore query

### 12.2 Read-only details

User Details reloads by UID through `getUserById`; the list object is not the
sole source of truth.

It shows:

- Name, initials, email
- Role and application status
- Available optional profile fields
- Creation/update dates
- Friendly assigned-facility labels

It does not display passwords, tokens, request internals, or image paths.

### 12.3 Manage User

An active Admin can manage only a different Technician or Viewer.

Allowed fields:

- Technician ↔ Viewer
- 1–20 facility IDs
- `active` ↔ `disabled`
- server-owned `updatedAt`

The repository uses a Firestore transaction to validate both reviewer and
target and writes only those four fields. Admin profiles, self-management,
Admin promotion, profile-field edits, email/UID changes, deletion, and Auth
administration are denied.

Disabling a user changes application-profile access only. It does not disable
the Firebase Auth account or revoke refresh tokens.

## 13. Firestore model and indexes

### 13.1 `users/{uid}`

Important fields:

| Field | Meaning |
|---|---|
| `uid` | Must equal Firebase UID and document ID |
| `displayName` | Current display identity |
| `firstName`, `lastName` | Editable name components |
| `email` | Normalized authenticated email |
| `role` | `admin`, `technician`, or `viewer` |
| `status` | `active` or `disabled` |
| `facilityIds` | Permitted internal facility IDs |
| `company` | Administrator/activation-managed company |
| `department`, `phone`, `jobTitle`, `bio` | Optional profile strings |
| `activationRequestId` | Invitation used for activation, where applicable |
| `createdAt`, `updatedAt` | Firestore timestamps |

### 13.2 `accessRequests/{requestId}`

Important fields:

| Field | Meaning |
|---|---|
| `fullName`, `email`, `normalizedEmail` | Applicant identity |
| `company`, `phone`, `department`, `message` | Applicant details |
| `status` | `pending`, `approved`, or `rejected` |
| `submittedAt` | Server timestamp |
| `reviewedBy`, `reviewedAt` | Admin review metadata |
| `rejectionReason` | Rejection text or null |
| `assignedRole` | `technician` or `viewer` after approval |
| `assignedFacilityIds` | Assigned internal IDs |
| `approvalSource` | `request` or `admin` |
| `activatedUid`, `activatedAt` | Activation metadata |

### 13.3 Composite indexes

Pending requests:

```text
Collection: accessRequests
status: Ascending
submittedAt: Descending
```

Account activation:

```text
Collection: accessRequests
normalizedEmail: Ascending
status: Ascending
activatedUid: Ascending
```

Local user search/filtering and direct user updates require no additional
index.

## 14. Firestore security approach

The complete local source is `firestore.rules`. It must be reviewed and
deployed manually.

`firebase.json` points Firestore Rules at this file. The repository does not
currently contain a `firestore.indexes.json`, so composite-index state must be
verified in Firebase Console and cannot be reconstructed solely from source
control.

Security principles:

- Public applicants can create only a strictly validated pending request.
- Public applicants cannot read/list/update/delete requests.
- Active Admins can read/list requests.
- Admin review updates have an explicit affected-field allowlist.
- Verified applicants can read only their matching approved unused invitation.
- Activation creates only the matching authenticated user's profile.
- Users can read their own profile.
- Active Admins can read/list user profiles.
- Self-profile updates can change only approved personal fields.
- Managed-user updates can change only role/facility/status/updatedAt for
  non-Admin targets.
- Deletes are denied.
- No broad `allow read, write: if true` rule exists.

The client also validates operations, but Firestore Rules remain the
authorization boundary.

## 15. Implemented screens and modules

### Onboarding and authentication

- Splash
- Welcome
- Login
- Forgot Password
- Request System Access
- Request Submitted
- Activate Account/email-verification state

### Dashboards and navigation

- Admin Dashboard
- User Dashboard
- Admin/User persistent shells
- Nested Stations, Alerts, Reports, and Admin dashboard flows

### Stations

- Station list and filters
- Station detail
- Add/register station
- Cross-module station navigation

### Alerts

- Alert list and filters
- Alert detail
- Evidence states
- Role actions
- Activity chart/hotspots
- Dashboard/station links

### Reports

- Period controls
- KPI cards
- Report generation
- Report Ready modal
- Trend chart
- Station ledger
- Recent Exports and See All

### Settings

- Main Settings
- Edit Profile
- Default View
- Default Facility
- Default Alert Filter
- Change Password
- Contact Administrator
- Privacy Policy
- Terms & Conditions
- Notification preferences
- Logout

### Admin access and user management

- Pending Requests
- Approve Request
- Reject Request dialog
- System Management
- Add User invitation
- Full User Management
- User Details
- Manage User

Site Management is display-only/mock. Add Site is deferred.

## 16. Design system

Bait Guard is light-mode only.

Central tokens:

- `AppColors`
- `AppTypography`
- `AppSpacing`
- `AppRadii`
- `AppSizes`

Important values:

- Page background: `#F4F5F7`
- Surface: `#FFFFFF`
- Splash background: `#0B1220`
- Primary blue: `#0F6FFF`
- Primary text: `#111317`
- Secondary text: `#6B7280`
- Success: `#16A34A`
- Warning: `#F59E0B`
- Critical: `#EF4444`
- Standard horizontal page padding: 16
- Standard button height: 48
- Bottom navigation height: 64
- Card radii: 12 or 16

Typography:

- Manrope is the primary UI family.
- JetBrains Mono helpers are available for technical/telemetry values.
- Inter helpers also exist centrally; avoid introducing per-screen font
  definitions.

Reusable components include:

- `AppBackButton`
- `AppTextField`
- `PrimaryButton`
- `AppTopToast`
- Loading/error states
- Shared legal/settings layouts
- Shared bottom navigation
- Feature cards, badges, chips, and selectors

Use `AppTopToast` for transient feedback. Do not introduce `SnackBar`.

## 17. Running and building

### Prerequisites

- Compatible Flutter SDK
- Android Studio/SDK or configured VS Code Flutter environment
- Android emulator or physical device
- Firebase configuration files already present
- Access to Firebase project for real backend testing

### Install packages

```bash
flutter pub get
```

### Run

```bash
flutter run
```

### Analyze

```bash
flutter analyze
```

### Test

Full suite:

```bash
flutter test
```

During focused development, prefer targeted feature tests first:

```bash
flutter test test/features/admin
flutter test test/features/authentication
flutter test test/features/settings
```

### Build release APK

```bash
flutter build apk --release
```

Expected output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Before external distribution, confirm release signing, production application
ID, Firebase app registration, versioning, privacy/legal content, and
environment ownership.

## 18. Manual testing guide

### Authentication and restoration

1. Sign in with valid Admin, Technician, and Viewer profiles.
2. Confirm each role reaches the correct shell.
3. Restart with an active Firebase session and verify restoration has no Login
   flicker.
4. Disable a profile in Firestore and verify new login/restoration is rejected.
5. Verify logout clears the application session and authenticated routes.

### Forgot/change password and Remember Me

1. Request a reset email and complete Firebase's default reset flow.
2. Change password from Settings using correct and incorrect current passwords.
3. Enable Remember Me, log in, log out, and confirm only email is prefilled.
4. Confirm password is always empty.

### Request Access

1. Submit valid required fields with optional fields empty.
2. Confirm one pending `accessRequests` document with normalized email and
   server timestamp.
3. Confirm no Auth account or `users` document is created.
4. Confirm Request Submitted returns safely to Login.

### Admin review

1. Confirm the pending count on Admin Dashboard matches Firestore.
2. Open Pending Requests and test refresh/empty/error states.
3. Approve a request with Technician/Viewer and facilities.
4. Reject another request with and without a reason.
5. Confirm reviewed requests disappear and counts update.

### Activation

1. Use the approved normalized email.
2. Create/sign into the Firebase Auth account through Activate Account.
3. Verify the email.
4. Tap the verification check.
5. Confirm `users/{uid}` is created and the invitation receives activation
   metadata.
6. Confirm assigned role/facilities determine the destination.

### Add User

1. Create an approved Technician/Viewer invitation.
2. Confirm no Auth/profile is created before activation.
3. Confirm duplicate existing user/pending/unused invitation checks.
4. Activate the invitation through the same activation flow.

### User Management

1. Open from Dashboard → Users and System Management.
2. Test search, role/status filters, counts, and refresh.
3. Open details and verify friendly facility names.
4. Confirm Manage User is absent for Admin/self profiles.
5. Change Technician/Viewer role and facilities.
6. Disable/re-enable a user.
7. Confirm details/list refresh and Admin session preservation.

### Operational frontend

1. Switch facilities and verify scoped dashboard/station/alert/report data.
2. Exercise station list/detail/add flows.
3. Exercise alert filters/detail/actions/evidence states.
4. Generate mock reports and verify Recent Exports.
5. Verify all Settings sub-screens, persistence, Back, and logout.
6. Test narrow screens and long user/facility names for overflow.

## 19. Spark-plan and backend limitations

The Firebase project must remain on Spark:

- No Cloud Functions
- No Admin SDK in the app
- No billing-dependent backend
- No trusted server-side Auth user administration
- No refresh-token revocation or remote sign-out
- No automatic invitation email delivery

Consequences:

- Public duplicate Request Access prevention is deferred.
- Admin invitation duplicate checks are client-side and can race.
- Disabling a profile prevents future login/restoration, but cannot forcibly
  terminate every already-open remote Firebase session.
- Admin accounts require privileged manual Firebase Console provisioning.

## 20. Images, Storage, and privacy

Firebase Storage is not included.

The project does not upload or persist:

- Rodent evidence images
- Profile photos
- Camera bytes
- Storage URLs or paths

Avatars are generated from initials.

Do not add Firebase Storage or rodent-image handling until supervisors confirm:

- Device/event schema
- Storage location and access model
- Privacy/legal requirements
- Retention/deletion policy
- Facility isolation
- Evidence review permissions
- Cost and plan implications

## 21. Known limitations and unclear contracts

- Production facility/site schema is not finalized.
- ESP32 provisioning and device identity are not finalized.
- Realtime telemetry/event transport is not implemented.
- YOLO/TFLite inference integration is not implemented in this Flutter
  codebase.
- Rodent evidence storage/retention is not defined.
- Site Management writes are deferred.
- Firebase Auth user administration requires a trusted backend unavailable on
  Spark.
- Production Android application ID still uses `com.example.my_first_app`.
- Production Android signing/release configuration is not documented as
  finalized.
- iOS is configured in FlutterFire, but current development and manual
  verification are Android-focused.
- The repository records the intended local Firestore Rules, but it cannot
  prove which rule revision is currently deployed without Firebase Console/CLI
  access.
- Firestore composite indexes are documented but are not captured in a
  `firestore.indexes.json` file.
- The project has both current architecture and a legacy route; new work should
  not expand the legacy navigation.

## 22. Recommended next phases

1. Supervisor approval of facility, station, device, and event schemas.
2. Decide Firestore versus RTDB responsibilities for configuration and live
   telemetry.
3. Define ESP32 identity/provisioning and secure device authentication.
4. Define on-device ML output/event payload contract.
5. Define evidence privacy, retention, and storage policy before adding images.
6. Replace mock facilities/stations incrementally behind existing repositories.
7. Replace alerts and reports only after event schema stabilizes.
8. Add app-resume profile recheck if near-immediate disabled-session
   enforcement becomes a requirement.
9. Finalize production application IDs, signing, environments, and CI/CD.
10. Perform full role/facility/rules/responsive regression and security review.

## 23. Development rules

- Preserve Provider + MVVM and feature-first organization.
- Use constructor injection and domain repository interfaces.
- Never call Firebase directly from screens or ViewModels.
- Keep Firebase SDK classes inside Firebase data implementations.
- Keep `AppSessionController` authoritative for the current user.
- Never duplicate or child-dispose shell-owned `ActiveFacilityController`.
- Filter every operational feature by permitted facilities.
- Never infer Admin from email or fall back to a mock Admin identity.
- Never log passwords, tokens, credentials, complete profiles, or request PII.
- Never store passwords in SharedPreferences, Firestore, or mock data.
- Use `AppTopToast`, not `SnackBar`.
- Use centralized theme tokens; do not invent isolated screen styles.
- Preserve light mode and persistent shell navigation.
- Do not deploy Firebase rules/indexes automatically from ordinary feature
  work.
- Use targeted analyze/tests during focused changes; run the complete suite at
  release checkpoints.
- Avoid destructive Git/filesystem commands and preserve unrelated worktree
  changes.

For controlled AI-assisted tasks, follow the command policy in the active task
brief. Commonly restricted commands include `flutter run`, builds, broad test
suites, Firebase deploy/CLI, emulator commands, Gradle commands, and dependency
upgrades unless explicitly authorized.

## 24. Concise status checklist

- [x] Flutter architecture established
- [x] Central design system and responsive shared UI
- [x] Firebase Core/Auth/Firestore configured
- [x] Real role-aware login/session restoration/logout
- [x] Request Access and request review
- [x] Verified approved-account activation
- [x] Admin-created invitations
- [x] Real user profiles and self-editing
- [x] Real Admin user list/details/access management
- [x] Disabled-profile login/restoration rejection
- [x] Stations/Alerts/Reports/Settings frontend
- [x] Facility-scoped mock operational behavior
- [x] Android name/icon branding
- [ ] Real operational facility/station backend
- [ ] ESP32/RTDB/telemetry integration
- [ ] YOLO/TFLite app/device integration
- [ ] Approved evidence image/storage policy
- [ ] Production IDs/signing/release pipeline
- [ ] Trusted backend features requiring a paid-capable architecture
