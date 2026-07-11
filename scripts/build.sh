#!/bin/bash
set -e
cd /workspace
echo "=== WorkSpace ==="
pwd
ls -al
flutter pub get
flutter build apk --release
echo "=== Build Output ==="
ls -al build/app/outputs/flutter-apk
echo "=== Output Before ==="
ls -al /output
cp build/app/outputs/flutter-apk/app-release.apk /output/myhome.apk
echo "=== Output After ==="
ls -al /output