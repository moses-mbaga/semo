#!/bin/bash

# Generate env.g.dart file
echo "// Generated file - do not modify" > lib/utils/env/env.g.dart
echo "part of 'env.dart';" >> lib/utils/env/env.g.dart
echo "" >> lib/utils/env/env.g.dart
echo "class _Env {" >> lib/utils/env/env.g.dart
echo "  static const String tmdbAccessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjYTc2MDk3MTlhNTYxYjM0MWM4MDYyYzMzN2FiZTM5NyIsIm5iZiI6MTc0NDI5MzUwOC4xMDQsInN1YiI6IjY3ZjdjZTg0MzE3NzUyNzZkNmQ5OTM4OCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.jB-LdCFKnX7xETXv3UgAHXffgoCOFK9wfyr6Z8y4AzI';" >> lib/utils/env/env.g.dart
echo "  static const String subdlApiKey = 'l0cgAb7VNM_KMN2KwkLCFNuRsk8q3tEg';" >> lib/utils/env/env.g.dart
echo "}" >> lib/utils/env/env.g.dart

# Build APK with the name INDEX
flutter build apk --release --split-per-abi -v --no-tree-shake-icons --build-name=1.0.0 --build-number=1 --target-platform android-arm,android-arm64,android-x64 --obfuscate --split-debug-info=./symbols

# Rename the APK files to INDEX
mkdir -p build/app/outputs/apk/release/INDEX
cp build/app/outputs/apk/release/app-armeabi-v7a-release.apk build/app/outputs/apk/release/INDEX/INDEX-armeabi-v7a-release.apk
cp build/app/outputs/apk/release/app-arm64-v8a-release.apk build/app/outputs/apk/release/INDEX/INDEX-arm64-v8a-release.apk
cp build/app/outputs/apk/release/app-x86_64-release.apk build/app/outputs/apk/release/INDEX/INDEX-x86_64-release.apk

echo "APK files have been built and renamed to INDEX"