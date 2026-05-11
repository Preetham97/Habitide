# Habitide

A simple iOS app for tracking daily habits with a three-state color system: green (good), orange (average), red (bad). Define a routine once, log it in seconds each day, and see trends over time.

## Features

- **Routine setup** — define a personal set of items to track (sleep, exercise, water, etc.) with emojis
- **Today view** — tap to mark each item green / orange / red, see an auto-computed overall score
- **Share card** — render today's progress as an image and share via Messages, Instagram, etc.
- **History** — calendar heatmap of past days, colored by overall score; tap a day to see its breakdown
- **Stats** — per-item green/orange/red breakdown, current streaks, and overall trend over the last 7 / 30 / 90 days
- **Settings** — edit your routine anytime (add, remove, reorder, rename items)

All data is local (SwiftData). No accounts, no network.

## Requirements

- iOS 17.0+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — used to generate the `.xcodeproj` from `project.yml`

## Setup

```bash
# 1. Install XcodeGen (one-time)
brew install xcodegen

# 2. Generate the Xcode project
cd Habitide
xcodegen

# 3. Open in Xcode
open Habitide.xcodeproj
```

Then pick a simulator (or your device) and ⌘R to run.

> The `.xcodeproj` is in `.gitignore` — regenerate it locally with `xcodegen` whenever you change `project.yml` or add new source files.

### Alternative setup (no XcodeGen)

If you'd rather not install XcodeGen:

1. In Xcode: `File > New > Project > iOS App` (SwiftUI, SwiftData, name it `Habitide`, bundle id `com.preetham.Habitide`)
2. Delete the auto-generated `ContentView.swift` and the default `App.swift`
3. Drag the `Habitide/` folder from this repo into the project navigator (check "Create groups")

## Project structure

```
Habitide/
├── HabitideApp.swift        # app entry, sets up SwiftData container
├── Models/                  # SwiftData @Model classes + ItemStatus enum
├── Helpers/                 # ScoreCalculator, date utilities, image renderer
└── Views/
    ├── RootView.swift       # tab bar + onboarding gate
    ├── Onboarding/
    ├── Today/
    ├── History/
    ├── Stats/
    ├── Settings/
    └── Components/
```

## Scoring

Each item: green = 2 pts, orange = 1 pt, red = 0 pts. Overall is computed only from logged items:

- `> 66%` of max → 🟩 green
- `< 34%` of max → 🟥 red
- otherwise → 🟧 orange

## Roadmap

- [ ] Notifications / daily logging reminder
- [ ] Home screen widget for one-tap logging
- [ ] Multiple routines (weekday / weekend variants)
- [ ] iCloud sync
- [ ] Export to CSV

## License

Personal project. No license yet.
