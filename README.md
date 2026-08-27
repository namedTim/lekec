# lekec

A Flutter project.

## Database

Regenerate Drift's `*.g.dart` files after adding/changing tables or migrations:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## App build

Run on a connected device:

```sh
flutter run --release
```

Build a release APK / AAB:

```sh
flutter build apk --release
flutter build appbundle --release
```

## Launcher icons & splash screen

Both are generated at build-time from source assets. Re-run them after
changing any image under `assets/icons/`, after a `flutter clean`, or if you
hit a `PlatformException: invalid icon` for `@mipmap/launcher_icon` in
release builds (= the launcher icon never got generated for this build).

### Launcher icons

Config: `flutter_launcher_icons.yaml` (sources under `assets/icons/`,
output mipmap name: `launcher_icon`).

```sh
dart run flutter_launcher_icons
```

Generates `android/app/src/main/res/mipmap-*/launcher_icon.png` and the
adaptive-icon XML in `mipmap-anydpi-v26/`. The Android manifest references
`@mipmap/launcher_icon` and `keep.xml` pins it against `shrinkResources`.

### Native splash

Config: `flutter_native_splash.yaml`.

```sh
dart run flutter_native_splash:create
```

After running either generator, do a clean rebuild so the new resources
are picked up:

```sh
flutter clean && flutter pub get && flutter build apk --release
```

## Notes

- App package: `si.lekec.app` (Android `applicationId` and `namespace`).
- Notification icons referenced by string at runtime (e.g.
  `@drawable/notification_icon`, `@mipmap/launcher_icon`) must be pinned
  in `android/app/src/main/res/raw/keep.xml`, otherwise the resource
  shrinker strips them from release builds.

# Useful links

- https://pub.dev/packages/flutter_launcher_icons
- https://pub.dev/packages/flutter_native_splash
- https://developer.android.com/studio/write/create-app-icons
