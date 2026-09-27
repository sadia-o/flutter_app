# First Prompt for Antigravity — Read-Only Project Understanding and Audit

You are working inside an existing Flutter repository for a product named **BaitGaurd**.

Before doing anything else, read every Markdown file inside the root-level
`baitguard_reference/` directory in numeric order. Then inspect all documents and images inside
that directory.

The repository contains the current implementation. The reference folder contains:

- Product and architecture documentation
- Frontend scope and non-negotiable rules
- New Figma target screenshots
- Legacy screenshots of the current app
- A design-system and typography specification
- A screen manifest
- A preliminary codebase-audit baseline

## Your task in this step

Perform a thorough **read-only audit and understanding pass**.

Do not create, modify, rename, move, format, or delete any project file.
Do not run automated code fixes.
Do not add packages.
Do not begin implementing the new UI.

## Understand the product

Confirm your understanding of:

- What BaitGaurd does
- Its intended users and environments
- The station data represented in the mobile application
- The edge-cloud-client production architecture
- The current frontend-only phase
- The later Firebase integration phase
- The roles and role-specific screens
- The static camera/night-vision placeholder rule
- The temporary mock-map rule
- The frontend-only report action rule

## Audit the current Flutter repository

Inspect at minimum:

1. `pubspec.yaml` and dependency versions
2. Application entry point and Firebase initialization
3. Existing screen inventory
4. Existing routes and navigation flow
5. Existing dialogs, sheets, and interaction flows
6. Current state-management approach
7. Current model/data organization
8. Existing mock data and where it is stored
9. Existing theme and styling strategy
10. Hardcoded colors, typography, spacing, radii, and shadows
11. Repeated widgets and extraction opportunities
12. Chart implementations and custom painters
13. Current tests
14. Analyzer issues
15. Risks of a direct rewrite
16. Features present in code but missing from target screenshots
17. Target screens that do not exist in code
18. Any conflicts between existing behavior, the SRS, and the new target design

## Required architecture direction

Your future plan must use:

- MVVM
- `provider` as the only state-management library
- Feature-first modular organization
- `ChangeNotifier` ViewModels
- Repository interfaces
- Mock repositories during the frontend phase
- Centralized design tokens and ThemeData
- Reusable components
- Responsive mobile layouts
- Light mode only, except the intentionally dark splash screen
- Clean boundaries that allow later Firebase repository implementations

Do not implement this architecture yet. Audit first.

## Required output

Return a structured report containing:

### A. Product understanding
A concise but complete description of the product, current phase, future backend phase, roles,
screens, and non-negotiable restrictions.

### B. Current codebase map
Show the current folder/file structure relevant to the app and explain each major file's
responsibility.

### C. Current screen and navigation inventory
List every screen, route, dialog, bottom sheet, filter state, and important action you find.

### D. Current architecture assessment
Explain how state, dummy data, UI, and navigation are currently implemented. Explicitly state
whether MVVM and Provider are currently present.

### E. Design-system assessment
Identify all current theme files, inline styling patterns, repeated values, and places that conflict
with the new design system.

### F. Dependency assessment
Explain which packages are currently used, which are unused, and which packages may be needed
later. Do not change `pubspec.yaml` in this step.

### G. Migration risks
Identify anything that could break during refactoring, including tightly coupled screens,
navigation, custom painters, dialogs, tests, and Firebase startup.

### H. Proposed staged migration plan
Provide a safe sequence of future changes. Separate architecture foundation from screen-by-screen
visual implementation.

### I. Clarifications
Ask only questions that cannot be resolved from the code or `baitguard_reference/`. Do not ask
questions already answered there.

At the end, explicitly confirm:

- No files were changed.
- No packages were added.
- No implementation was started.
