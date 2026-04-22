#!/bin/bash
# Build the Android APK end-to-end.
#
# This is the canonical entry point used both locally and in CI to turn the
# Elixir LiveView project (this repository) into an Android APK that embeds
# a pre-built Erlang/OTP runtime.
#
# Requirements:
#   - Elixir/Erlang at the versions pinned in rel/android/app/.tool-versions
#     (the embedded Android runtime is ABI-locked to a specific OTP release,
#     so the BEAM bytecode must be produced by a matching compiler).
#   - Node.js (for the Phoenix asset pipeline).
#   - JDK 17.
#   - Android SDK + NDK + CMake 3.22.x exposed via ANDROID_SDK_ROOT or
#     ANDROID_HOME.
#
# Usage:
#   scripts/build_android.sh                    # builds debug APK (default)
#   scripts/build_android.sh assembleRelease    # builds release APK
#   scripts/build_android.sh bundleRelease      # builds AAB for the Play Store
#
# Any extra arguments are forwarded verbatim to ./gradlew. Gradle in turn calls
# rel/android/app/run_mix which builds the Elixir release from this project
# root and zips it into rel/android/app/src/main/assets/app.zip.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/rel/android"

if [ "$#" -gt 0 ]; then
    GRADLE_ARGS=("$@")
else
    GRADLE_ARGS=("assembleDebug")
fi

cd "$ANDROID_DIR"
exec ./gradlew --stacktrace "${GRADLE_ARGS[@]}"
