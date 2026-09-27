# Current Codebase Audit Baseline

This baseline was produced from the supplied code-audit ZIP before any Antigravity changes.

## Current files

```text
lib/
├── firebase_options.dart
├── main.dart
├── theme.dart
└── screens/
    ├── admin_screen.dart
    ├── alert_detail_screen.dart
    ├── alerts_screen.dart
    ├── home_screen.dart
    ├── reports_screen.dart
    ├── settings_screen.dart
    ├── station_detail_screen.dart
    └── stations_screen.dart
```

## Important findings

- `theme.dart` is empty.
- Theme values are currently defined directly in `main.dart` and screen widgets.
- No Provider dependency is present.
- No MVVM structure is present.
- No repository layer is present.
- No dedicated models folder is present.
- No centralized mock-data source is present.
- Navigation is a local `StatefulWidget` with an integer index.
- Firebase Core is initialized at app startup.
- The implementation is heavily widget-local and uses `setState`.
- Several screens are very large and monolithic.
- UI state, dummy data, visual code, and actions are mixed together.
- Default SnackBars, dialogs, and modal sheets are used extensively.
- There are hundreds of hardcoded color references and many inline text styles.
- The package name and README still use the starter name `my_first_app`.
- The current widget test only checks that bottom-navigation labels load.

## Approximate size of current screen files

- Admin screen: about 1,196 lines
- Home screen: about 1,115 lines
- Alerts screen: about 803 lines
- Settings screen: about 604 lines
- Stations screen: about 588 lines
- Reports screen: about 511 lines
- Station Detail: about 502 lines
- Alert Detail: about 214 lines

## Required audit behavior

Antigravity must independently verify these findings from the actual repository.

It must not blindly delete or rewrite files before identifying:

- Existing routes
- Existing interactions
- Mock data that should be preserved
- Chart/custom painter behavior
- Current navigation links
- Dialog and modal flows
- Which code can be safely extracted into reusable components
- Whether Firebase initialization currently blocks local frontend testing
