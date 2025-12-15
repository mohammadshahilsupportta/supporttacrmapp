#!/bin/bash
# Script to clean Flutter build and remove file_picker cache

echo "🧹 Cleaning Flutter build cache..."

cd /home/shahil/Desktop/Flutter_Supportta/supportacrm

# Remove Flutter build artifacts
rm -rf build/
rm -rf .dart_tool/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies
rm -rf pubspec.lock

# Remove Android build cache
cd android
./gradlew clean 2>/dev/null || echo "Gradle clean skipped"
rm -rf .gradle/
rm -rf app/build/
rm -rf build/
cd ..

# Remove iOS build cache (if exists)
rm -rf ios/Pods/
rm -rf ios/.symlinks/
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec

echo "✅ Clean complete!"
echo ""
echo "Now run: flutter pub get"
echo "Then: flutter clean"
echo "Finally: flutter pub get again"


