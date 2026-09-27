# BaitGuard Firebase Realtime Database (RTDB) Telemetry & Events Integration

This document defines the architecture, data models, schema mappings, security rules, verification checklist, and deployment procedures for the Firebase Realtime Database integration in the BaitGuard Flutter mobile application.

---

## 1. Executive Summary & Pilot Scope

The BaitGuard mobile application consumes live telemetry and detection events from pilot hardware deployed at facilities:

- **Pilot Station ID**: `station_01`
- **Pilot Facility / Site ID**: `site_1`
- **Default RTDB Instance URL**: `https://bait-guard-6f470-default-rtdb.firebaseio.com/`
- **Hardware Device UID (ESP32)**: `zj0CNiqRBwdTwXzKrD5yP5Puds83`

### Strict Boundaries & Constraints
- **Hardware-Managed Telemetry**: All telemetry writes, refills, battery percentages, and raw detections are published directly by the field hardware (ESP32). The mobile client operates as a **read-only observer**. Mutating operations on station telemetry or alerts (such as recording refills, station registration, snooze, dismiss, or alert resolution) throw `UnsupportedError` on the client and their corresponding UI actions are explicitly disabled (`supportsMutations = false`).
- **Report Export**: Report PDF/CSV generation is not supported in this pilot phase (`supportsExport = false`). False success mock generators have been removed.
- **Static Camera Placeholder**: The hardware pilot payload does not provide camera image frames, URLs, or video streams. The UI displays a static camera placeholder card (`'CAMERA (PREVIEW)'` / `'Static Preview Only'`) without implying real snapshots are available.
- **No Cloud Functions / Billing**: The architecture does not rely on Cloud Functions or billed Firebase services.
- **Scoped Facility Access & Session Isolation**: The client strictly isolates facility data. Telemetry and events for `station_01` are only exposed when the active user possesses an active account, valid read grants, and the selected facility context is `site_1`. On logout, facility switch, or account disablement, subscriptions are cancelled and local caches are wiped.

---

## 2. Realtime Database Schema

### 2.1 `/stationLive/{stationId}` (Live Telemetry)
Published periodically or on-heartbeat by the station hardware.

```json
{
  "device_id": "station_01",
  "facility_id": "site_1",
  "battery_percentage": 86,
  "bait_percentage": 100,
  "online": true,
  "last_seen_at": 1756972800000
}
```

#### Field Specifications:
| Field | Type | Description | App Mapping |
| :--- | :--- | :--- | :--- |
| `device_id` | `String` | Station hardware identifier (must equal path stationId) | `Station.id` |
| `facility_id` | `String` | Facility identifier (`site_1`) | `Station.siteId` |
| `battery_percentage` | `number` | Remaining battery (0-100) | `Station.batteryPercentage` |
| `bait_percentage` | `number` | Remaining bait level (0-100) | `Station.baitPercentage` |
| `online` | `boolean` | Online connectivity flag | Status evaluation |
| `last_seen_at` | `number` | Epoch milliseconds UTC | `Station.lastSeen` |

#### Station Status Derivation:
1. **Offline**: If `online == false` OR `(DateTime.now() - last_seen_at) > 30 minutes` (centralized staleness threshold `kHeartbeatStalenessTimeout`). An injectable clock timer periodically calls `checkFreshness()` to transition stations to offline even when Firebase sends no further update.
2. **Low Bait**: If online, not stale, and `bait_percentage <= 25.0` (`kLowBaitThreshold`).
3. **Online**: If online, not stale, and `bait_percentage > 25.0`.

*Note on Tamper Data*: The pilot hardware does not report tamper switch sensor readings. Tamper status is omitted/unavailable (`hasTamperData: false`), preventing false claims of confirmed "not tampered".

---

### 2.2 `/stationEvents/{stationId}/{eventId}` (Event Records)
Logged by hardware upon rodent detection or low-bait trigger.

```json
{
  "stationEvents": {
    "station_01": {
      "evt_001": {
        "device_id": "station_01",
        "facility_id": "site_1",
        "event_type": "rat_detected",
        "timestamp": 1756972800000
      },
      "evt_002": {
        "device_id": "station_01",
        "facility_id": "site_1",
        "event_type": "low_bait_alert",
        "bait_percentage": 15,
        "current_pixels": 420,
        "status": "Refill Required",
        "timestamp": 1756972900000
      }
    }
  }
}
```

#### Event Mapping Rules:
- **`rat_detected`**:
  - Requires: `device_id`, `facility_id`, `event_type`, `timestamp`.
  - Must NOT contain low-bait fields (`bait_percentage`, `current_pixels`, `status`).
  - Generates a rodent `DetectionEvent` (`species: DetectedSpecies.rat`).
  - Generates an `Alert` (`type: AlertType.rodent`, `severity: AlertSeverity.critical`).
- **`low_bait_alert`**:
  - Requires: `device_id`, `facility_id`, `event_type`, `timestamp`, `bait_percentage` (0-100), `current_pixels` (number >= 0), `status` (one of `'Normal'`, `'Low'`, `'Refill Required'`).
  - Generates an `Alert` (`type: AlertType.lowBait`, `severity: AlertSeverity.warning`).
  - **Does NOT generate a rodent `DetectionEvent`** (ensures rat counts are strictly isolated from bait warnings).
  - Dynamically resolved if a subsequent live telemetry reading shows `bait_percentage > 25.0`.

---

### 2.3 `/mobileReaders/{uid}` (Security & Access Control Grants)
Maintained in RTDB to validate that an authenticated Firebase user is entitled to read facility telemetry:

```json
{
  "mobileReaders": {
    "<firebase_auth_uid>": {
      "active": true,
      "facilityIds": {
        "site_1": true
      }
    }
  }
}
```

---

## 3. Database Security Rules (`database.rules.json`)

The rules enforce pilot isolation, hardware write scoping, human reader authorization, create-only event protection, and query indexing:

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "stationLive": {
      "station_01": {
        ".read": "auth != null && (root.child('mobileReaders').child(auth.uid).child('active').val() === true && root.child('mobileReaders').child(auth.uid).child('facilityIds').child('site_1').val() === true)",
        ".write": "auth != null && auth.uid === 'zj0CNiqRBwdTwXzKrD5yP5Puds83' && newData.exists()",
        ".validate": "newData.hasChildren(['device_id', 'facility_id', 'battery_percentage', 'bait_percentage', 'online', 'last_seen_at'])",
        "device_id": { ".validate": "newData.isString() && newData.val() === 'station_01'" },
        "facility_id": { ".validate": "newData.isString() && newData.val() === 'site_1'" },
        "battery_percentage": { ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() <= 100" },
        "bait_percentage": { ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() <= 100" },
        "online": { ".validate": "newData.isBoolean()" },
        "last_seen_at": { ".validate": "newData.isNumber() && newData.val() > 0" },
        "$other": { ".validate": false }
      }
    },
    "stationEvents": {
      "station_01": {
        ".read": "auth != null && (root.child('mobileReaders').child(auth.uid).child('active').val() === true && root.child('mobileReaders').child(auth.uid).child('facilityIds').child('site_1').val() === true)",
        ".indexOn": ["timestamp"],
        "$eventId": {
          ".write": "auth != null && auth.uid === 'zj0CNiqRBwdTwXzKrD5yP5Puds83' && !data.exists() && newData.exists()",
          ".validate": "newData.hasChildren(['device_id', 'facility_id', 'event_type', 'timestamp'])",
          "device_id": { ".validate": "newData.isString() && newData.val() === 'station_01'" },
          "facility_id": { ".validate": "newData.isString() && newData.val() === 'site_1'" },
          "timestamp": { ".validate": "newData.isNumber() && newData.val() > 0" },
          "event_type": {
            ".validate": "newData.isString() && (
              (newData.val() === 'rat_detected' && !newData.parent().child('bait_percentage').exists() && !newData.parent().child('current_pixels').exists() && !newData.parent().child('status').exists()) ||
              (newData.val() === 'low_bait_alert' && newData.parent().hasChildren(['bait_percentage', 'current_pixels', 'status']))
            )"
          },
          "bait_percentage": { ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() <= 100" },
          "current_pixels": { ".validate": "newData.isNumber() && newData.val() >= 0" },
          "status": { ".validate": "newData.isString() && (newData.val() === 'Normal' || newData.val() === 'Low' || newData.val() === 'Refill Required')" },
          "$other": { ".validate": false }
        }
      }
    },
    "mobileReaders": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": false
      }
    }
  }
}
```

---

## 4. Architecture & Reactive Implementation

### 4.1 Reactive Path: RTDB → DataSource → Repository → ViewModel → Screens
1. **`RealtimeStationDataSource`** (`lib/data/repositories/firebase/realtime_station_data_source.dart`):
   - Listens reactively to `/stationLive/station_01` and `/stationEvents/station_01` using Firebase Database stream listeners.
   - Dispatches changes over broadcast stream controllers: `stationStream`, `eventsStream`, `alertsStream`.
   - Binds to user lifecycle via `bindSessionAndFacility(userId, facilityId, isPermitted: ..., isAccountActive: ...)`.
   - Runs a 60-second periodic timer checking 30-minute staleness (`checkFreshness()`), converting online stations to offline when heartbeats cease.
2. **Repositories**:
   - `RealtimeStationRepository`: Exposes `watchStations()` and `watchStation(id)`.
   - `RealtimeAlertRepository`: Exposes `watchAlerts()` and `watchAlert(id)`.
   - `RealtimeDashboardRepository`: Exposes `watchUserDashboard()` and `watchAdminDashboard()`.
   - `RealtimeReportRepository`: Exposes `watchReportSummary()`.
3. **ViewModels**:
   - `UserDashboardViewModel` & `AdminDashboardViewModel`: Listen to dashboard streams; auto-update counters, activity charts, and station indicators.
   - `StationsViewModel` & `StationDetailViewModel`: Listen to station streams; reflect online/offline/battery/bait changes live.
   - `AlertsViewModel` & `AlertDetailViewModel`: Listen to alert streams; update list and detail views immediately.
   - `ReportsViewModel`: Listens to report summary stream; recomputes calendar period breakdowns (inclusive start, exclusive end) upon new event arrivals.

---

## 5. Verification Checklist & Quality Gates

| Verification Step | Result | Notes |
| :--- | :--- | :--- |
| `dart analyze lib test` | **0 issues** | Full static analysis clean |
| `flutter test --reporter expanded` | **All Passed** | Full project suite passes (377+ tests) |
| `realtime_reactivity_regression_test.dart` | **14 / 14 Passed** | Deterministic coverage of reactivity, caching, session switch, permission loss, heartbeat offline timeout, and reporting boundaries |
| `rtdb_rules_test.js` (Emulator) | **15 / 15 Passed** | Local Firebase Auth & RTDB emulators test: ESP allowed writes/creates, ESP denied overwrites/deletions, denied unknown fields, denied mismatched identities, viewer allowed reads, stranger denied reads, human denied writes |

---

## 6. Production Provisioning & Verification Status

> [!NOTE]
> Production Firebase setup and live physical device verification were completed by the project owner:
> - **Production RTDB Rules**: Published to `bait-guard-6f470` using `database.rules.json`.
> - **Mobile Reader Grants**: Configured under `/mobileReaders/{uid}` for authorized accounts.
> - **Phone Testing**: Verified on Infinix X6836; Admin, Technician, and Viewer accounts were manually tested with live telemetry, alerts, and detection events displaying accurately.

### Production Provisioning Reference

1. **Deploy RTDB Security Rules**:
   ```bash
   firebase deploy --only database --project bait-guard-6f470
   ```
2. **Provision Mobile Reader Grants**:
   For each authorized pilot human user UID, add an entry under `/mobileReaders/{uid}` in RTDB:
   ```json
   {
     "active": true,
     "facilityIds": {
       "site_1": true
     }
   }
   ```
3. **Verify ESP32 Hardware Authentication**:
   Confirm that the ESP32 firmware authenticates with Firebase Auth using the provisioned UID `zj0CNiqRBwdTwXzKrD5yP5Puds83` before writing to `/stationLive/station_01` and `/stationEvents/station_01`.
