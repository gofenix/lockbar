# LockBar

LockBar is a Flutter-built macOS menu bar utility that locks your screen with a single click.

## What It Does

- Runs as a menu bar app with no Dock icon
- Left-clicks lock immediately after Accessibility permission is granted
- Right-click menu includes `Lock Now`, `Launch at Login`, `Open Settings`, and `Quit`
- Shows a lightweight settings window for permission guidance and startup control

## Local Development

```bash
flutter pub get
flutter run -d macos
```

## Build Notes

- Target platform: macOS 13+
- Uses the system Accessibility permission to synthesize `Control + Command + Q`
- Uses the `LaunchAtLogin` Swift package to support login items on macOS

## DMG Release

Store your notarization credentials once:

```bash
xcrun notarytool store-credentials lockbar-notary \
  --apple-id <YOUR_APPLE_ID> \
  --team-id 993F5N3HV6 \
  --password <APP_SPECIFIC_PASSWORD>
```

Build, sign, notarize, and package a distributable DMG:

```bash
./scripts/release-macos.sh
```

To override the app version embedded in the release artifacts:

```bash
./scripts/release-macos.sh --build-name 1.0.0 --build-number 1
```
