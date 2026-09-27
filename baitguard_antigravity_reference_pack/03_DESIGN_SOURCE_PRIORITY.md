# Design Source Priority

When sources conflict, use this priority:

1. Explicit decisions in this reference pack
2. New Figma target screenshots in `references/figma_target/`
3. The detailed UI design-system document
4. Product requirements in the SRS
5. Existing app behavior and legacy screenshots
6. Antigravity's own assumptions

The old dark screenshots are historical references only. They help identify existing features and
interactions; they are not the visual target.

## Core documented design system

### Font usage

- Manrope: primary application typography
- JetBrains Mono: telemetry, percentages, numerical statistics, and data-heavy values
- Inter: charts, map legends, chart axes, and small analytical labels

### Important colors

- Main background: `#F4F5F7`
- Surface/card: `#FFFFFF`
- Splash/dark background: `#0B1220`
- Primary text: `#111317`
- Secondary text: `#6B7280`
- Tertiary text: `#A1A6AF`
- Primary blue: `#0F6FFF`
- Purple: `#7C3AED`
- Violet: `#8B5CF6`
- Success green: `#16A34A`
- Alternate success: `#059669`
- Healthy green: `#22C55E`
- Emerald: `#10B981`
- Warning amber: `#F59E0B`
- Pending dark amber: `#B45309`
- Critical red: `#EF4444`
- Alert rose: `#F43F5E`
- Blue tint: `#DBEAFE`
- Blue soft tint: `#EFF6FF`
- Green tint: `#ECFDF5`
- Amber tint: `#FEF6E7`
- Red tint: `#FFF1F3`
- Purple tint: `#F3E8FF`
- Divider: `#E2E8F0`

These values must be represented by semantic theme tokens, not referenced as raw colors throughout
screens.

## Responsive interpretation

The screenshots are visual targets, not fixed pixel canvases.

Implementation must:

- Use constraints and flexible layout
- Avoid absolute positioning for general page layout
- Handle narrower and taller phones
- Use scrollable content where appropriate
- Keep tap targets accessible
- Maintain consistent side padding and vertical rhythm
- Preserve content hierarchy when space changes
