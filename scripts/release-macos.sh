#!/bin/bash

set -euo pipefail

APP_NAME="LockBar"
BUNDLE_ID="io.github.fenix.lockbar"
TEAM_ID="993F5N3HV6"
CERTIFICATE_NAME="Developer ID Application: zhu zhenfeng (993F5N3HV6)"
NOTARY_PROFILE="lockbar-notary"
SCHEME="Runner"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC_PATH="$ROOT_DIR/pubspec.yaml"
WORKSPACE_PATH="$ROOT_DIR/macos/Runner.xcworkspace"
EXPORT_OPTIONS_PLIST="$ROOT_DIR/scripts/exportOptions-developer-id.plist"
RELEASE_DIR="$ROOT_DIR/build/macos/release"
ARCHIVE_PATH="$RELEASE_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$RELEASE_DIR/export"
DMG_STAGE_PATH="$RELEASE_DIR/dmg-stage"
APP_ZIP_PATH=""
DMG_PATH=""
LAUNCH_AT_LOGIN_BUNDLE_RELATIVE_PATH="Contents/Resources/LaunchAtLogin_LaunchAtLogin.bundle"

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

die() {
  printf '\nError: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: ./scripts/release-macos.sh [--build-name <semver>] [--build-number <int>]

Builds, signs, notarizes, and packages LockBar for direct macOS distribution.
Defaults to the version declared in pubspec.yaml.
EOF
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

require_file() {
  [[ -f "$1" ]] || die "Required file not found: $1"
}

check_certificate() {
  security find-identity -v -p codesigning | grep -Fq "$CERTIFICATE_NAME" \
    || die "Missing signing identity: $CERTIFICATE_NAME"
}

check_notary_profile() {
  local output

  set +e
  output="$(xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" --output-format json 2>&1)"
  local status=$?
  set -e

  if [[ $status -eq 0 ]]; then
    return
  fi

  if [[ "$output" == *"No Keychain password item found for profile"* ]]; then
    die "Missing notarytool profile '$NOTARY_PROFILE'. Run: xcrun notarytool store-credentials $NOTARY_PROFILE --apple-id <APPLE_ID> --team-id $TEAM_ID --password <APP_SPECIFIC_PASSWORD>"
  fi

  die "Unable to validate notarytool profile '$NOTARY_PROFILE': $output"
}

read_pubspec_version() {
  local version_line

  version_line="$(awk '/^version: / { print $2; exit }' "$PUBSPEC_PATH")"
  [[ -n "$version_line" ]] || die "Unable to read version from $PUBSPEC_PATH"

  if [[ "$version_line" == *"+"* ]]; then
    DEFAULT_BUILD_NAME="${version_line%%+*}"
    DEFAULT_BUILD_NUMBER="${version_line##*+}"
  else
    DEFAULT_BUILD_NAME="$version_line"
    DEFAULT_BUILD_NUMBER="1"
  fi
}

parse_args() {
  BUILD_NAME="${DEFAULT_BUILD_NAME}"
  BUILD_NUMBER="${DEFAULT_BUILD_NUMBER}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build-name)
        [[ $# -ge 2 ]] || die "--build-name requires a value"
        BUILD_NAME="$2"
        shift 2
        ;;
      --build-number)
        [[ $# -ge 2 ]] || die "--build-number requires a value"
        BUILD_NUMBER="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done

  [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]] || die "Build number must be an integer"
}

prepare_dirs() {
  rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$DMG_STAGE_PATH"
  mkdir -p "$RELEASE_DIR"
  APP_ZIP_PATH="$RELEASE_DIR/$APP_NAME-$BUILD_NAME.zip"
  DMG_PATH="$RELEASE_DIR/$APP_NAME-$BUILD_NAME.dmg"
  rm -f "$APP_ZIP_PATH" "$DMG_PATH"
}

archive_app() {
  log "Running Flutter macOS release build"
  flutter pub get
  flutter build macos --release --build-name "$BUILD_NAME" --build-number "$BUILD_NUMBER"

  log "Archiving signed macOS app"
  xcodebuild \
    -workspace "$WORKSPACE_PATH" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    FLUTTER_BUILD_NAME="$BUILD_NAME" \
    FLUTTER_BUILD_NUMBER="$BUILD_NUMBER" \
    archive
}

write_manual_export_plist() {
  local plist_path="$1"

  cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>export</string>
  <key>distributionBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>method</key>
  <string>developer-id</string>
  <key>signingCertificate</key>
  <string>Developer ID Application</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>teamID</key>
  <string>$TEAM_ID</string>
</dict>
</plist>
EOF
}

export_archive() {
  local manual_plist

  log "Exporting Developer ID app with automatic signing"
  if xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -allowProvisioningUpdates; then
    return
  fi

  log "Automatic export failed, retrying with explicit Developer ID signing"
  rm -rf "$EXPORT_PATH"
  manual_plist="$(mktemp "${TMPDIR:-/tmp}/lockbar-export-manual.XXXXXX.plist")"
  trap 'rm -f "$manual_plist"' RETURN
  write_manual_export_plist "$manual_plist"

  xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$manual_plist"
}

cleanup_launch_at_login_bundle() {
  local app_path="$1"
  local launch_bundle_path="$app_path/$LAUNCH_AT_LOGIN_BUNDLE_RELATIVE_PATH"

  if [[ ! -d "$launch_bundle_path" ]]; then
    return
  fi

  log "Removing legacy LaunchAtLogin helper bundle before notarization"
  rm -rf "$launch_bundle_path"

  log "Re-signing app after LaunchAtLogin cleanup"
  codesign \
    --force \
    --sign "$CERTIFICATE_NAME" \
    --timestamp \
    --options runtime \
    --entitlements "$ROOT_DIR/macos/Runner/Release.entitlements" \
    "$app_path"
}

notarize() {
  local artifact_path="$1"
  local log_path="$2"

  log "Submitting $(basename "$artifact_path") for notarization"
  xcrun notarytool submit "$artifact_path" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait \
    --output-format json | tee "$log_path"
}

verify_exported_app() {
  local app_path="$EXPORT_PATH/$APP_NAME.app"

  [[ -d "$app_path" ]] || die "Exported app not found at $app_path"

  cleanup_launch_at_login_bundle "$app_path"

  log "Packaging app for notarization"
  ditto -c -k --keepParent "$app_path" "$APP_ZIP_PATH"
  notarize "$APP_ZIP_PATH" "$RELEASE_DIR/notary-app.json"

  log "Stapling notarization ticket to app"
  xcrun stapler staple "$app_path"
  xcrun stapler validate "$app_path"
  codesign --verify --deep --strict --verbose=2 "$app_path"
  spctl -a -vvv "$app_path"
}

build_dmg() {
  local app_path="$EXPORT_PATH/$APP_NAME.app"

  log "Creating DMG staging folder"
  mkdir -p "$DMG_STAGE_PATH"
  ditto "$app_path" "$DMG_STAGE_PATH/$APP_NAME.app"
  ln -s /Applications "$DMG_STAGE_PATH/Applications"

  log "Building compressed DMG"
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGE_PATH" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

  log "Signing DMG container"
  codesign --force --sign "$CERTIFICATE_NAME" --timestamp "$DMG_PATH"
  notarize "$DMG_PATH" "$RELEASE_DIR/notary-dmg.json"

  log "Stapling notarization ticket to DMG"
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
  spctl -a -vvv --type open --context context:primary-signature "$DMG_PATH"
}

print_summary() {
  local app_path="$EXPORT_PATH/$APP_NAME.app"

  log "Release artifacts"
  echo "App: $app_path"
  echo "DMG: $DMG_PATH"
  echo "App notarization log: $RELEASE_DIR/notary-app.json"
  echo "DMG notarization log: $RELEASE_DIR/notary-dmg.json"

  log "Code signing summary"
  codesign -dv --verbose=4 "$app_path" 2>&1 | sed -n '1,40p'
}

main() {
  require_command awk
  require_command codesign
  require_command ditto
  require_command flutter
  require_command hdiutil
  require_command security
  require_command spctl
  require_command xcodebuild
  require_command xcrun

  require_file "$PUBSPEC_PATH"
  require_file "$EXPORT_OPTIONS_PLIST"

  read_pubspec_version
  parse_args "$@"
  check_certificate
  check_notary_profile
  prepare_dirs
  archive_app
  export_archive
  verify_exported_app
  build_dmg
  print_summary
}

main "$@"
