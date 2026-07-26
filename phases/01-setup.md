# Phase 1: Project Setup & Tooling

## Goal
Establish the development environment, directory structure, build tooling, and agent documentation. The app should compile against macOS 14+ with no warnings.

## Steps

### 1. Lower Deployment Target to macOS 14
Edit `idiot.xcodeproj/project.pbxproj`:
- Change `MACOSX_DEPLOYMENT_TARGET = 26.5;` to `MACOSX_DEPLOYMENT_TARGET = 14.0;` in both Debug and Release project-level build configurations (check if target-level override exists too).
- Verify no APIs newer than macOS 14 are used (SwiftData and Swift Charts are available on 14+).

### 2. Create Directory Structure
Inside `idiot/`, create the following folders:
```
Models/
Views/
ViewModels/
Helpers/
Resources/
```

Existing files (`idiotApp.swift`, `ContentView.swift`, `Assets.xcassets/`) stay in place.

### 3. Create `Helpers/DateExtensions.swift`
- `startOfMonth`, `endOfMonth`, `isInCurrentMonth`, `isInPastMonth` computed properties on `Date`.
- `formatted(style: DateFormatter.Style)` helper.
- `weekOfMonth` computed property (1-based).

### 4. Create `Helpers/ColorExtensions.swift`
- `init(hex: String)` initializer for `Color` that parses `#RRGGBB` or `RRGGBB` hex strings.
- Predefined palette of category colors as static vars (`.categoryBlue`, `.categoryGreen`, `.categoryOrange`, `.categoryRed`, `.categoryPurple`, etc.).

### 5. Create `Helpers/NumberFormatterExtensions.swift`
- `currencyFormatter: NumberFormatter` that uses the current locale's currency symbol with 2 decimal places.
- `formattedCurrency` computed property on `Double`.

### 6. Verify Build
- Confirm project builds with `make build`.

## Implementation Guide
(To be filled after Phase 1 implementation.)
