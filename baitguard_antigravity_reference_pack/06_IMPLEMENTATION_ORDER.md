# Recommended Professional Implementation Order

## Phase 0 — Read-only discovery

No code changes.

- Inspect the complete project.
- Run dependency and analyzer checks.
- Map all screens, routes, states, mock data, actions, and reusable candidates.
- Produce a migration plan.

## Phase 1 — Safety and foundation

- Create a local Git checkpoint.
- Correct project/app naming where safe.
- Introduce Provider.
- Establish the new folder structure.
- Create domain models and repository interfaces.
- Move mock data into mock repositories.
- Establish application routing and role/session state.
- Create centralized light theme and design tokens.
- Configure fonts and assets.
- Create shared UI components.

Do not visually rebuild every screen in this phase.

## Phase 2 — Entry and authentication UI

1. Splash
2. Welcome
3. Login
4. Request Access
5. Request Submitted

Use mock authentication and form submission only.

## Phase 3 — Main application shell

- Role-aware entry
- User/Admin dashboard routing
- Responsive bottom navigation
- Notification badge
- Shared page scaffold
- Custom feedback/toast system

## Phase 4 — Core screens

1. User Dashboard
2. Admin Dashboard
3. Stations
4. Station Detail
5. Alerts and all filter states
6. Alert Detail where needed
7. Reports
8. Settings
9. Edit Profile
10. Admin users and roles

## Phase 5 — Frontend hardening

- Empty/loading/error states
- Form validation
- Consistent animations
- Accessibility and semantics
- Responsive testing
- Widget tests
- Golden tests where practical
- Removal of legacy dark UI code after replacement is verified

## Phase 6 — Backend integration later

Only after the redesigned frontend is approved:

- Firebase Auth
- Firestore
- Storage
- FCM
- Cloud Functions/report generation
- Offline cache
- Real map/geolocation

## Authentication backend batches

- Authentication Batch 5: Pending Requests is implemented from
  `24_pending_requests.png`, including active-admin Firestore reads and the
  real Admin Dashboard pending count.
- System Management remains deferred to a later batch; its visual reference is
  retained as `25_system_management.png`.
- Approve and Reject interaction flows remain deferred and will use the same
  established admin theme.
