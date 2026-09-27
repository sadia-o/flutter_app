# BaitGuard — Smart Rodent Bait-Station Monitoring

Flutter mobile application for the Trinode Industrial Internship Project. BaitGuard connects facility staff to bait-station telemetry and detection history, with role-based access for administrators, technicians, and viewers.

## Current delivery status — 27 September 2026

The Android debug app has been built locally and verified on a physical phone (Infinix X6836) by the project owner. Production RTDB security rules and mobile reader grants have been configured in Firebase project `bait-guard-6f470`. The project owner personally tested Admin, Technician, and Viewer accounts, confirming that all relevant telemetry, alerts, detection events, and role-based data display correctly on the device. This delivery finalizes the Git branch publication to both the personal repository (`origin`) and the supervisor repository (`supervisor`).

This is a read-only operational pilot for `station_01` at `site_1`. Existing authentication and administrative workflows use Firebase Auth and Firestore. The source includes broader frontend features, but their presence does not mean the pilot hardware or backend supports every action.

| Area | Current state |
| --- | --- |
| Authentication | Firebase email/password login, reset, session restoration, email verification/activation, remembered email |
| Access requests | Firestore request submission, admin review, approval/rejection, invitations |
| Users and roles | Firestore users, roles, account status, and facility assignments |
| Navigation | Admin and user shells, persistent tabs, light theme, custom top toasts |
| Operational reads | RTDB telemetry/events, repository streams, subscribed ViewModels |
| Station pilot | Battery %, bait %, connectivity flag, last-seen timestamp, freshness checks |
| Detection history | Rat events and low-bait events; low-bait events do not count as rodent detections |
| Reports | Period aggregation and charts; calendar month/quarter/year and seven-day rolling period |
| Camera and map | Static camera placeholder; schematic facility layout |
| Operational writes | Unsupported in the RTDB pilot; repository guards and capability checks |
| Export | PDF generation, download, and sharing are unavailable in the RTDB pilot |
| Android build | Local debug APK built; dependency-cache workaround documented below |
| Production reader/rules setup | Configured and active in Firebase project `bait-guard-6f470` by project owner |
| Live acceptance | Verified on phone by project owner (Admin, Technician, Viewer accounts tested; relevant data displays correctly) |
| Git delivery | Final integration branch `codex/rtdb-telemetry-integration` prepared for push to both remotes |

## Architecture and development rules

- Flutter stable 3.44.x project; Dart constraint `^3.8.1` in `pubspec.yaml`. Use the checked-in lockfile.
- Provider and ChangeNotifier MVVM only.
- Pure domain models/repository interfaces without Firebase or Flutter dependencies.
- Firebase SDK access belongs in the data layer.
- Feature-first views, ViewModels, widgets, and navigation.
- Central theme tokens: AppColors, AppTypography, AppSpacing, AppRadii.
- AppTopToast for user feedback; light mode except the splash screen.
- No live video streaming, external map API, or Cloud Functions required by this pilot.

```text
lib/
  app/                    DI, routing, session/facility state, theme
  core/widgets/           Shared UI components
  domain/models/          Domain entities
  domain/repositories/    Repository contracts
  data/repositories/
    firebase/             Auth, Firestore, RTDB implementations
    mock/                 Seeded repositories and test support
    preferences/          Local preferences
  features/               Authentication, admin, dashboards, stations,
                          alerts, reports, settings, navigation
docs/                     Project and integration documentation
test/                     Dart tests and RTDB emulator rules test
```

Operational path:

```text
ESP32 → Firebase RTDB → RealtimeStationDataSource
      → Repository streams → ChangeNotifier ViewModels → Screens
```

`AppProviders` selects Firebase implementations when Firebase is initialized. Tests without an initialized Firebase app use mock implementations. A passing mock test is not proof of a working production Firebase connection. Some settings behavior remains mock-backed.

## Firebase services and pilot schema

| Setting | Value |
| --- | --- |
| Project | `bait-guard-6f470` |
| Project number | `609454017958` |
| Database URL | `https://bait-guard-6f470-default-rtdb.firebaseio.com/` |
| Authentication | Email/password |
| Profiles/access requests | Cloud Firestore |
| Operational data | Realtime Database |
| Firestore rules | `firestore.rules` |
| RTDB rules | `database.rules.json` |
| Deployment configuration | `firebase.json` |

Use existing Firebase configuration files for this project. Account passwords, service-account keys, and authentication tokens must not be committed.

### Live telemetry

Path: `/stationLive/station_01`

```json
{
  "device_id": "station_01",
  "facility_id": "site_1",
  "battery_percentage": 86,
  "bait_percentage": 100,
  "online": true,
  "last_seen_at": 1789022734000
}
```

This is a historical example. Hardware must send current epoch-millisecond timestamps.

The app marks the station offline if `online` is false or the heartbeat is more than 30 minutes old. The current implementation checks freshness every 30 seconds. When online, bait at or below 25% is low bait.

### Events

Path: `/stationEvents/station_01/{uniqueEventId}`

Rat detection:

```json
{
  "device_id": "station_01",
  "facility_id": "site_1",
  "event_type": "rat_detected",
  "timestamp": 1789022675000
}
```

Low-bait event:

```json
{
  "device_id": "station_01",
  "facility_id": "site_1",
  "event_type": "low_bait_alert",
  "timestamp": 1789022675000,
  "current_pixels": 120,
  "bait_percentage": 20,
  "status": "Low"
}
```

Low-bait status values are `Normal`, `Low`, and `Refill Required`. Rat events must not contain these low-bait-only fields. Hardware creates unique event IDs; it does not overwrite existing events.

The current schema does **not** provide voltage, temperature, humidity, tamper readings, confidence, images, refill records, historical uptime, or acknowledgment/resolution state. It supports rat detections, not a general mouse/none classification payload.

The reference export had one station, 139 rat events, and four low-bait events. These are historical counts, not fixed expected production totals. Its last heartbeat was 10 September 2026 at 11:45:34 Pakistan time.

## Firebase setup before testing the phone

### 1. Verify the human user

In Firebase Console, open Authentication → Users and copy the UID of the human account used to sign in to the app.

In Firestore → Data → `users/{uid}`, confirm the existing profile has:

- The correct role: `admin`, `technician`, or `viewer`.
- `status` set to `active`.
- A `facilityIds` array containing the string `site_1`.

Preserve all other existing profile fields and facility assignments. The ESP account is a device identity; do not use it as the mobile user or create a Firestore human profile for it.

### 2. Add a Realtime Database reader grant

In Realtime Database → Data, add the following tree alongside the existing `stationLive` and `stationEvents` nodes:

```text
mobileReaders
  HUMAN_FIREBASE_AUTH_UID
    active: true
    facilityIds
      site_1: true
```

The exact value at `/mobileReaders/HUMAN_FIREBASE_AUTH_UID` is:

```json
{
  "active": true,
  "facilityIds": {
    "site_1": true
  }
}
```

Both values must be booleans, not strings. Replace the placeholder with the real Authentication UID. Repeat for each authorized human account.

Use the root row's add-child control and nested child controls to build the grant. Do not put it under a station node. Do not import a grant-only JSON file at the database root: an import can replace the selected location's existing data.

RTDB reader grants and Firestore facility assignments are separate. Maintain both when authorizing, disabling, or reassigning users; the current implementation does not automatically synchronize the RTDB grants.

### 3. Publish RTDB rules

Open `database.rules.json` in this repository and copy its complete contents into Firebase Console → Realtime Database → Rules, then Publish. Keep this file as the deployment source of truth; do not substitute abbreviated snippets from older documents.

Alternatively, an authorized operator can deploy only the RTDB configuration:

```powershell
firebase deploy --only database --project bait-guard-6f470
```

Saving the local file, passing emulator tests, or pushing to GitHub does not publish Firebase rules. The rules preserve the configured ESP writer and permit human reads only through active, facility-scoped grants. Do not change root permissions to public access.

Reference: [Managing and deploying Firebase rules](https://firebase.google.com/docs/rules/manage-deploy).

### 4. Reopen the installed app

Sign out, close/reopen the app, and sign in with the provisioned human account. Select the facility corresponding to `site_1`.

Database permissions are server-side changes: they do not require an APK rebuild. Reopening the app establishes fresh subscriptions for the test.

## Build and run

### Prerequisites

- Flutter/Dart SDK compatible with `pubspec.yaml` and `pubspec.lock`.
- Android SDK/tools and a connected Android phone or emulator.
- JDK 21 for the current Gradle 8.12 wrapper.
- Windows Developer Mode where Flutter plugins require symlinks.
- Existing Firebase app configuration for the target platform.

iOS source/configuration is present, but this handoff does not establish a successful iOS build. Building iOS requires macOS and Xcode.

### Java configuration on the current Windows machine

Antigravity reported that Flutter selected Android Studio's Java 25.0.2 and failed before task execution. It configured an installed JDK 21:

```powershell
flutter config --jdk-dir "C:\Program Files\Eclipse Adoptium\jdk-21.0.12.8-hotspot"
flutter doctor -v
```

Use your own installed JDK 21 path on another machine. The Flutter setting is machine-local and is not transferred by Git. Gradle 8.12 supports running on Java 21; Java 25 requires Gradle 9.1 or newer. See the [Gradle compatibility matrix](https://docs.gradle.org/current/userguide/compatibility.html).

### Local Firebase dependency workaround — not portable yet

The current lockfile resolves `firebase_auth 6.5.6` and `firebase_core 4.15.0`.

To obtain the local Android build, Antigravity edited the cached dependency file:

```text
%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\firebase_auth-6.5.6\android\src\main\java\io\flutter\plugins\firebase\auth\FlutterFirebaseAuthPlugin.java
```

It changed the `customAuthDomain` lookup from `FlutterFirebaseCorePlugin.customAuthDomain` to `FlutterFirebasePlugin.customAuthDomain`.

This change is outside this repository. A Git push does not include it, and a clean dependency download may lose it. A fresh clone/CI build has not been verified. Before declaring the project reproducibly buildable, resolve this through a verified compatible dependency release or a version-controlled dependency patch/fork and validate from a clean cache. This README records the workaround; it does not implement that follow-up.

A cross-drive Kotlin cache error was also reported during earlier attempts. If that specific error recurs, investigate the project/cache locations. Dart supports setting `PUB_CACHE`, but changing it downloads fresh packages and will not preserve the local patch above. Do not treat cache relocation as an already verified universal fix.

### Commands

After the dependency portability issue is addressed, a fresh checkout uses:

```powershell
git clone https://github.com/TAHA-programmer/baitguard_mobile.git
Set-Location baitguard_mobile
flutter pub get
flutter doctor -v
dart analyze lib test
flutter test --reporter expanded
flutter devices
flutter run -d <device-id-from-flutter-devices>
```

For the current local checkout, run these from the existing project folder rather than cloning over it.

Build a debug APK:

```powershell
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`.

Use the device ID returned by `flutter devices`; a display name may not uniquely identify the connected device. A debug APK is for testing; release signing and store distribution are separate work.

## Verification and acceptance

| Check | Latest available evidence |
| --- | --- |
| Static analysis | Zero issues (dart analyze lib test clean) |
| Realtime regression tests | 14 passed (deterministic coverage of reactivity, caching, session, heartbeat timeout) |
| Full Flutter suite | 377 passed |
| Emulator rules tests | 15 passed (local Firebase Auth & RTDB emulators test in test/rtdb_rules_test.js) |
| Android debug build | Successful local APK build (build/app/outputs/flutter-apk/app-debug.apk) |
| Phone launch & live testing | Verified by project owner on Infinix X6836; Admin, Technician, and Viewer accounts tested with live data displaying correctly |
| Production reader/rules setup | Configured in Firebase project `bait-guard-6f470` by project owner |
| ESP-to-phone automatic update | Verified by project owner during live phone testing |
| Clean clone without cache edits | Not verified (requires local Pub cache workaround or upstream dependency patch) |

Repeat quality gates for subsequent code changes:

```powershell
dart analyze lib test
flutter test --reporter expanded
flutter build apk --debug
```

Local rules testing requires Firebase CLI, Node.js, and a compatible Java installation:

```powershell
firebase emulators:exec --only auth,database --project bait-guard-6f470 "node test/rtdb_rules_test.js"
```

The rules script uses localhost emulator ports 9099 and 9000. Its sample accounts are emulator fixtures, not production credentials.

### Phone acceptance sequence

1. Complete the human profile, RTDB grant, and rules setup.
2. Compare station battery, bait, and last seen against the current Firebase Console data.
3. Keep Station Detail open while hardware publishes a new reading. Confirm automatic changes without restarting or pulling to refresh.
4. Verify the same state across Stations and both relevant dashboards.
5. Publish a new hardware rat event. Confirm one new detection and consistent period totals.
6. Publish a hardware low-bait event. Confirm it does not increase rodent detection totals.
7. Select report periods containing the actual event timestamps. Empty today/week counts can be correct for old data.
8. Test authorized technician/viewer accounts after provisioning their own grants.
9. Check account switching, lost access, and heartbeat expiry against the known limitations below.
10. Record observed results before declaring production telemetry acceptance complete.

Do not rewrite old timestamps merely to make the station appear online. Use fresh hardware readings. Do not replace production event history with test fixtures.

### Troubleshooting

| Symptom | Check |
| --- | --- |
| Login works but telemetry fails | Published RTDB rules, exact human UID, boolean grant values, matching Firebase project |
| No pilot facility | Firestore `facilityIds` includes `site_1`; select that facility |
| Station offline despite `online: true` | Check age and millisecond units of `last_seen_at` |
| Zero recent detections | Compare event dates with the selected period and local timezone |
| Low-bait events not in rodent totals | Expected separation |
| Export/refill/resolve unavailable | Expected read-only pilot limitation |
| Updates fail while screen stays open | Capture Flutter/Firebase errors and check known stream/error-handling issues |
| Fresh clone fails but local APK builds | Check JDK selection and the uncommitted dependency-cache workaround |

## Deferred work and known limitations

The project owner has deferred further correction work while validating Firebase setup. These items remain open; documentation does not imply they are fixed:

- Active-user facility permission changes are not fully rebound through application session wiring.
- Station/alert detail views can retain old data on null updates; stream error handling needs improvement.
- Event history still uses open/unread states and inferred low-bait resolution without authoritative backend workflow state. Low-bait resolution does not compare reading/event timestamps.
- Malformed event timestamps can fail during sorting before validation.
- Stream initialization/cancellation, empty-data behavior, refresh behavior, and app-resume freshness need broader lifecycle verification.
- Some dashboard scores/change indicators are app-derived or defaulted rather than measured backend metrics; their presentation needs review.
- RTDB reader grants require manual administration alongside Firestore permissions.
- Reproducible builds require replacing the local dependency-cache edit.
- Multi-station discovery/registration, additional telemetry/species, durable alert actions, exports, images/video, and historical uptime/refills are outside the current pilot.
- Production acceptance is verified on phone by the project owner; Git delivery is completed to both repositories on branch `codex/rtdb-telemetry-integration`.

## GitHub delivery

Destinations:

- Personal repository: [TAHA-programmer/baitguard_mobile](https://github.com/TAHA-programmer/baitguard_mobile) (remote: `origin`)
- Supervisor repository: [sadia-o/flutter_app](https://github.com/sadia-o/flutter_app) (remote: `supervisor`)

Integration branch: `codex/rtdb-telemetry-integration`. Collaborator access has been granted for the supervisor repository.

Delivery push commands:

```powershell
git push -u origin codex/rtdb-telemetry-integration
git push supervisor codex/rtdb-telemetry-integration
```

Both remote branches receive the identical delivery commit. Pull requests can then be opened against each repository's default branch (`main`) for formal review and integration:
- Personal repo PR: [Compare & Open PR on baitguard_mobile](https://github.com/TAHA-programmer/baitguard_mobile/compare/main...codex/rtdb-telemetry-integration?expand=1)
- Supervisor repo PR: [Compare & Open PR on flutter_app](https://github.com/sadia-o/flutter_app/compare/main...codex/rtdb-telemetry-integration?expand=1)

Do not force-push or overwrite default branches.

Source delivery, Firebase deployment, and installing an APK are separate operations. A Git push also cannot transfer the machine-local JDK configuration or dependency-cache patch.

## Project references

- [Project guide](docs/BAITGUARD_PROJECT_GUIDE.md)
- [Project onboarding](docs/CHATGPT_PROJECT_ONBOARDING.md)
- [RTDB integration notes](docs/RTDB_INTEGRATION.md)
- [Web integration guide](docs/FIREBASE_WEB_INTEGRATION_GUIDE.md)
- [Reference pack](baitguard_antigravity_reference_pack/)
- [RTDB rules source](database.rules.json)

Earlier guides may contain historical mock behavior or stale examples. Use the executable rules file and current source as the authority, with the pending work above taken into account.

Project: Trinode Industrial Internship Project. Developer: [TAHA-programmer](https://github.com/TAHA-programmer).
