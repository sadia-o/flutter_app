# BaitGaurd — Antigravity Reference Pack

Place this entire folder at the root of the Flutter project, next to `lib/` and `pubspec.yaml`.

Recommended project layout:

```text
your_flutter_project/
├── lib/
├── test/
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── README.md
└── baitguard_reference/
    ├── 00_READ_ME_FIRST.md
    ├── 01_PROJECT_CONTEXT.md
    ├── 02_FRONTEND_SCOPE_AND_RULES.md
    ├── 03_DESIGN_SOURCE_PRIORITY.md
    ├── 04_SCREEN_MANIFEST.md
    ├── 05_CODEBASE_AUDIT_BASELINE.md
    ├── 06_IMPLEMENTATION_ORDER.md
    ├── 07_ANTIGRAVITY_FIRST_PROMPT.md
    ├── documents/
    └── references/
```

Rename this extracted folder to `baitguard_reference` after placing it in the project.

Do not ask Antigravity to modify code immediately. First give it the prompt in
`07_ANTIGRAVITY_FIRST_PROMPT.md`. That prompt is deliberately read-only.

The current phase is frontend-only. Firebase integration will be handled only after
the complete redesigned frontend is stable.
