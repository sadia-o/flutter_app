# Frontend Scope and Non-Negotiable Rules

## Scope of the current phase

This phase is exclusively for completing the redesigned frontend professionally.

Do:

- Implement all target screens.
- Rebuild existing screens to match the new Figma language.
- Create missing screens using the same design system.
- Use realistic, coherent mock data.
- Implement frontend-only interactions, filters, navigation, toggles, validation, modal states,
  loading states, empty states, and polished feedback.
- Keep code ready for later Firebase integration.

Do not:

- Add Firestore reads or writes.
- Add Firebase Authentication flows.
- Add Firebase Storage uploads.
- Add Firebase Cloud Messaging behavior.
- Add Cloud Functions.
- Build production PDF or CSV generation.
- Add real geolocation or Google Maps yet.
- Build a live camera feed or streaming system.

## Camera area

The station camera/night-vision area must remain a static visual placeholder.

Do not implement:

- Camera plugins
- RTSP
- WebRTC
- Video playback
- Live streaming
- Device camera access
- Remote camera sessions

Style the placeholder consistently with the new design system only.

## Map

The map is currently a mock schematic facility map.

- Keep it as a responsive custom UI visualization in this phase.
- Do not integrate real maps or geolocation yet.
- Structure the code so a real map widget can be introduced later.

## Report actions

PDF/CSV actions are frontend-only during this phase.

When tapped, use a polished in-app feedback pattern such as:

- A custom top toast
- An in-place success state
- A clean confirmation sheet

Do not use generic default Material SnackBars as the final design treatment.

## State management and architecture

- Use `provider`.
- Do not use Riverpod.
- Do not mix state-management libraries.
- Feature state belongs in ViewModels extending `ChangeNotifier`.
- Views render state and call ViewModel methods.
- Views must not directly own repositories or backend logic.
- Repositories expose interfaces.
- Use mock repository implementations now.
- Keep models separate from widgets and screen files.

## Design implementation

- Centralize colors, typography, spacing, sizes, radii, shadows, borders, and durations.
- Do not scatter raw hex colors or repeated styling constants through widgets.
- Reuse shared components.
- Do not copy entire screen layouts into one large file.
- Keep screen-specific widgets inside their feature.
- Use the target Figma images as the visual source of truth.
- Use the design document for specified tokens and typography.
- Make layouts responsive rather than matching only one fixed screenshot size.
- Do not draw or include the external iPhone device frame inside Flutter.
- Respect SafeArea and system insets.
- Support text scaling reasonably without major overflow.
- Use only light mode for the app UI.
- The splash screen may use the documented dark background.

## Quality gate

After each controlled implementation step:

```bash
dart format lib test
flutter analyze
flutter test
```

The agent must report:

- Files changed
- Components introduced
- Assumptions made
- Any visual differences that could not be resolved
- Analyzer/test status
