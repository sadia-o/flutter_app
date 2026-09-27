# Screen Manifest

## Existing application references

The three images in `references/existing_app/` show the current dark Overview screen and its existing
refresh feedback. They are legacy references.

## New target screens

1. Splash screen
2. Welcome/onboarding screen
3. Login screen
4. Request system access screen
5. Request submitted successfully screen
6. User dashboard
7. Admin dashboard
8. Stations screen
9. Alerts — All
10. Alerts — Rodent
11. Alerts — Low bait
12. Alerts — Tamper
13. Alerts — Offline
14. Reports screen
15. Settings/Profile screen
16. Edit Profile screen
17. Default View
18. Default Facility
19. Default Alert Filter
20. Change Password
21. Contact Administrator
22. Privacy Policy
23. Terms & Conditions
24. Pending Requests — implemented in Authentication Batch 5
25. System Management — reference retained; implementation deferred

## Screens that exist in code but do not yet have a direct target screenshot

- Station Detail
- Alert Detail, if still required as a separate route
- Admin approval/rejection interaction screens, to be derived later from the
  Pending Requests and System Management theme
- Admin role-management screens
- Add/edit user forms
- Any dialogs, sheets, empty states, validation states, loading states, and polished success states

For missing designs:

- Preserve the feature requirements.
- Rebuild them using the same light design language.
- Reuse the established components.
- Do not carry forward the old dark visual styling.
- Make conservative UX decisions.
- Document every design assumption before implementation.
- The Station Detail camera region remains static and non-functional.
