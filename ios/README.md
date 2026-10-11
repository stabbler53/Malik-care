# رعاية مالك (MalikCare) — step 1

A simple, Arabic, right-to-left iPhone app for Nashoo to log Malik's feeds, diapers and sleep.
All data stays on the iPhone (SwiftData). No account, no sync, no internet needed.

## Open and run
1. On a Mac with **Xcode 16 or newer**, open `MalikCare.xcodeproj`.
2. Select the **MalikCare** target → *Signing & Capabilities* → choose your Apple ID team.
3. Plug in the iPhone (iOS 17+) and press Run.

If the project ever refuses to open, install XcodeGen (`brew install xcodegen`) and run `xcodegen` in this folder; it rebuilds the project from `project.yml`.

## What's in step 1
- **Home**: today's summary (last feed and side, feeds, diapers, sleep, awake time) and big buttons at the bottom, within thumb reach.
- **Breastfeeding timer**: right/left buttons, tap to start or switch, tap again to pause. Remembers the last side and suggests the next one. Keeps running if the app is closed.
- **Bottle**: breast milk or formula, amount in ml or oz with big +/− and quick amounts.
- **Pumping**: amount per side and duration.
- **Diaper**: "wet" saves in one tap; dirty/mixed can add stool colour and consistency, with gentle warnings for red, pale or black stool.
- **Sleep**: one tap to start, one tap to stop; daily total and awake time are calculated.
- **Log**: every entry grouped by day with daily totals; tap to edit, swipe to delete, add a past nap.
- **Night mode**: true black, dimmed colours; moon button on home, or set in Settings.
- **Settings**: baby name, birth date (shows age), mother's name, ml/oz.

## Code layout
- `MalikCare/Models` — SwiftData models (`FeedEntry`, `DiaperEntry`, `SleepEntry`).
- `MalikCare/Views` — screens.
- `MalikCare/Support` — Arabic formatting, colours/theme, settings keys, daily stats.

Steps 2 (health, growth, postpartum) and 3 (reminders, trends, PDF report, widget) come later.
