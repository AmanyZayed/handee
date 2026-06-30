#!/usr/bin/env bash
# Run Handee from D: with build caches on D: (avoids full C: drive).
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Always force D: (ignore profile env that points at full C: drive).
export GRADLE_USER_HOME="D:/dev/gradle-home"
export PUB_CACHE="D:/dev/pub-cache"
export TMPDIR="D:/dev/tmp"
export TEMP="D:/dev/tmp"
export TMP="D:/dev/tmp"

mkdir -p "$GRADLE_USER_HOME" "$PUB_CACHE" "$TMPDIR" "$TEMP"

# Prefer Flutter on D: if installed there (see android/local.properties).
FLUTTER_BIN="${FLUTTER_BIN:-}"
if [[ -z "$FLUTTER_BIN" && -x "/d/src/flutter/bin/flutter" ]]; then
  FLUTTER_BIN="/d/src/flutter/bin/flutter"
elif [[ -z "$FLUTTER_BIN" ]]; then
  FLUTTER_BIN="flutter"
fi

echo "Project:  $PROJECT_ROOT"
echo "Gradle:   $GRADLE_USER_HOME"
echo "Pub cache: $PUB_CACHE"
echo "Temp:     $TMPDIR"
echo ""

# android/build.gradle.kts redirects Gradle output here (C: is too small for Unity).
GRADLE_APK="D:/HandeeBuild/handee-android/app/outputs/apk/debug/app-debug.apk"
BACKUP_APK="D:/HandeeBuild/handee-android/app/outputs/flutter-apk/app-debug.apk"
FLUTTER_APK="build/app/outputs/flutter-apk/app-debug.apk"

copy_verified_apk() {
  local src="$1"
  if [[ ! -f "$src" ]]; then
    return 1
  fi
  if ! verify_apk_signature "$src"; then
    return 1
  fi
  mkdir -p "$(dirname "$FLUTTER_APK")"
  cp -f "$src" "$FLUTTER_APK"
  echo "Synced APK: $src -> $FLUTTER_APK"
}

sync_gradle_apk() {
  if copy_verified_apk "$GRADLE_APK"; then
    return 0
  fi
  if [[ -f "$GRADLE_APK" ]]; then
    echo "Gradle APK exists but is not signed — build may have been interrupted."
  fi
  if copy_verified_apk "$BACKUP_APK"; then
    echo "Using signed backup APK from flutter-apk output."
    return 0
  fi
  echo "Run: $FLUTTER_BIN build apk --debug"
  return 1
}

verify_apk_signature() {
  local apk="$1"
  local apksigner=""
  local java_home="${JAVA_HOME:-}"

  if [[ -z "$java_home" && -x "/c/Program Files/Android/Android Studio/jbr/bin/java" ]]; then
    java_home="/c/Program Files/Android/Android Studio/jbr"
  fi

  for v in 37.0.0 36.1.0 35.0.0; do
    if [[ -x "/d/Android/Sdk/build-tools/$v/apksigner.bat" ]]; then
      apksigner="/d/Android/Sdk/build-tools/$v/apksigner.bat"
      break
    fi
  done

  if [[ -z "$apksigner" || -z "$java_home" ]]; then
    # Best effort when SDK tools are unavailable.
    return 0
  fi

  JAVA_HOME="$java_home" "$apksigner" verify "$apk" >/dev/null 2>&1
}

resolve_apk() {
  if [[ -f "$FLUTTER_APK" ]]; then
    echo "$FLUTTER_APK"
  elif [[ -f "$GRADLE_APK" ]]; then
    sync_gradle_apk
    echo "$FLUTTER_APK"
  else
    return 1
  fi
}

run_flutter() {
  if "$FLUTTER_BIN" run "$@"; then
    return 0
  fi
  echo "Flutter could not find APK — syncing from Gradle output on D:..."
  if ! sync_gradle_apk; then
    echo "Missing or invalid APK at $GRADLE_APK — run: $FLUTTER_BIN build apk --debug"
    return 1
  fi
  "$FLUTTER_BIN" run "$@" --use-application-binary="$FLUTTER_APK"
}

"$FLUTTER_BIN" pub get

if [[ "${1:-}" == "--build-only" ]]; then
  # Gradle output is on D:; Flutter may exit 1 even when assembleDebug succeeded.
  "$FLUTTER_BIN" build apk --debug || true
  sync_gradle_apk || exit 1
  exit 0
fi

if [[ "${1:-}" == "--install-only" ]]; then
  APK="$(resolve_apk)" || {
    echo "Missing APK — run: $0 --build-only"
    exit 1
  }
  ADB="${ADB:-/d/Android/Sdk/platform-tools/adb.exe}"
  "$ADB" install -r "$APK"
  exit 0
fi

DEVICE="${1:-}"
if [[ -n "$DEVICE" ]]; then
  run_flutter -d "$DEVICE"
else
  run_flutter
fi
