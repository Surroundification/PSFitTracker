# PSFitTracker

PSFitTracker is a Flutter workout and body-measurement tracker. Workout plans,
completed sessions, and check-ins are stored locally on the device; no account
or app-store distribution is required.

## Features

- Create as many workout plans as you need, with dynamic exercise lists.
- Set target sets, reps, and a rest interval for each exercise.
- Log reps and kilograms for every set and mark completed sets as you go.
- Navigate to other tabs while a workout is in progress and return to the
  preserved session from the full-width button above the tab bar. Cancel a
  workout to discard its draft after confirming.
- New workouts prefill each exercise set with its weight from the latest
  matching recorded workout. Add or remove sets while recording. Completing a
  set starts its
  exercise's rest timer, replacing any timer already running; rest intervals
  can be adjusted. The phone vibrates when the countdown finishes.
- Add notes to each exercise while recording a workout. Workout dates can be
  set to a past date.
- Track total workout time as you train; saved sessions show the duration in
  history in minutes or hours and minutes. A confirmation after saving shows
  completed exercises, reps, and workout time.
- Save completed sessions and review each exercise and recorded set in
  read-only workout history, including per-exercise workout notes.
- Browse workouts by date in the read-only monthly calendar above history;
  long plan names are truncated to fit their day.
- Workout and check-in history initially shows the most recent 14 days.
  “Show more” reveals older entries in batches of 14 without deleting or
  excluding them from saved data or weight averages.
- Edit and delete body check-ins; check-in dates can be set to a past date.
  Deleting check-ins and recorded workout sessions requires confirmation.
- Log body weight, waist, and body-fat percentage independently; same-day
  check-ins are merged so each date has at most one weight.
- Compare the previous seven-day average body weight with the current rolling
  seven-day average using recorded weights only. Missing daily readings are
  not extrapolated; the chart shows moving averages only on dates with a
  recorded weight.

## Build an Android APK

The Android runner is included in this project. With Flutter 3.27 or later,
JDK 17 or later, and the Android SDK installed, run these commands from this
directory to test the app and create a debug APK:

```sh
flutter pub get
flutter test
flutter build apk --debug
```

The testable APK is created at
`build/app/outputs/flutter-apk/app-debug.apk`. Install it on a connected,
USB-debugging-enabled Android device with:

```sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

To make a sideloadable release APK instead, run `flutter build apk --release`;
it is created at `build/app/outputs/flutter-apk/app-release.apk`. Copy it to
the Android device and open it to install; allow installation from that file
source if Android asks. No Google Play account or store upload is needed.

To build an iOS app, generate the iOS project on macOS with
`flutter create --project-name my_workout_tracker --platforms ios .`, then use
Xcode signing and `flutter build ios`.

## Local privacy

All workout and measurement data is saved using on-device preferences. The app
does not require an internet connection or transmit personal data.
