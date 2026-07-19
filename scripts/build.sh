#!/bin/bash
set -e
cd /workspace
flutter pub get
flutter build apk --release --dart-define=COUCHDB_USER=${secrets.COUCHDB_USER} --dart-define=COUCHDB_PASSWORD=${secrets.COUCHDB_PASSWORD}
cp build/app/outputs/flutter-apk/app-release.apk /output/myhome.apk