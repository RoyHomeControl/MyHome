#!/bin/bash
set -e

cd /workspace
flutter pub get
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk /output/myhome.apk