# Habitide

A simple iOS app for tracking daily habits with a three-state color system: 🟩 great, 🟧 okay, 🟥 off. Define routines once, log them in seconds each day, and see trends over time.

## Features

- **Multiple routines per week** — assign different routines to different weekdays (e.g. a Weekday routine for Mon–Fri and a Weekend routine for Sat–Sun). Each day is owned by exactly one routine; days claimed by another routine appear locked in the editor so you can never double-book.
- **Editable routines** — rename items, swap emojis, reorder via drag, add/remove. Edits to today's routine immediately reflect in Today and the share card; past days stay frozen as snapshots.
- **Today view** — pick today's routine automatically by weekday, tap items to mark them ⬇ / ━ / ⬆ (off / okay / great), see the overall verdict in a segmented ring.
- **Share card** — render the day as a clean light-tinted card with the same segmented ring and item list, then share via Messages, Instagram, etc. Footer uses the actual app icon.
- **History** — monthly calendar where each day is colored by its overall verdict. Today's cell is outlined; tap any past day for a full breakdown.
- **Stats** — three layers of insight:
  - **Highlights** — dynamic sentence-based headlines picked from your data (e.g. "5-day streak", "Strongest on Saturdays", "Diet up 23%")
  - **Patterns** — day-of-week breakdown showing your green % per weekday, plus a 12-week trend bar chart
  - **Items** — tappable rows per item with a 30-day mini strip, current streak, and delta vs the previous 30 days. Tap one for a full drill-down (calendar, longest streak, weekday breakdown)
- **Daily reminder** — a local notification at a time you pick (defaults to 22:00) nudges you to log your routine. Toggleable in Settings.
- **Appearance** — System / Light / Dark theme override in Settings.
- **Full emoji keyboard** for routine items — the full iOS emoji set including search and skin tones, not a hand-picked subset.

All data is local (SwiftData). No accounts, no network.

## Scoring

Strict majority over logged items:

- 🟩 **Great** if greens > oranges + reds
- 🟥 **Off** if reds > greens + oranges
- 🟧 **Okay** otherwise (including ties)

Examples: 4🟩 + 2🟧 → great. 3🟩 + 3🟧 → okay. 4🟥 + 2🟧 → off.

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

1. In Xcode: `File > New > Project > iOS App` (SwiftUI, SwiftData, name it `Habitide`, bundle id `com.preetham.Habitide`)
2. Delete the auto-generated `ContentView.swift` and the default `App.swift`
3. Drag the `Habitide/` folder from this repo into the project navigator (check "Create groups")

## Project structure

```
Habitide/
├── HabitideApp.swift        # app entry, sets up SwiftData container
├── Models/                  # SwiftData @Models: Routine, RoutineItem, DayLog, ItemLog + ItemStatus enum
├── Helpers/                 # ScoreCalculator, NotificationManager, theme, image renderer, date utils
├── Assets.xcassets/         # AppIcon, BrandIcon (used in share card footer)
└── Views/
    ├── RootView.swift       # tab bar + onboarding gate
    ├── Onboarding/          # RoutineSetupView (also used for editing)
    ├── Today/               # TodayView + ShareCardView
    ├── History/             # monthly calendar + DayDetailView
    ├── Stats/               # windowed stats
    ├── Settings/            # routine list + reminder controls
    └── Components/          # OverallRing, StatusPicker, WeekdayPicker, EmojiPicker
```

## Roadmap

- [ ] Home-screen widget for one-tap logging
- [ ] iCloud sync across devices
- [ ] Export to CSV

## License

Personal project. No license yet.
