# Google Play Store Publishing Guide

## Prerequisites
1. Google Play Console account ($25 one-time registration fee)
2. Flutter SDK installed
3. Android Studio (for signing setup)

## Step 1: Update App Configuration

### 1.1 Update Package Name (Important!)
The current package name is `com.example.supportacrm` which cannot be used for Play Store.

**You need to change it to your own unique package name**, for example:
- `com.yourcompany.supportacrm`
- `com.supportta.crm`
- `com.yourname.supportacrm`

**Files to update:**
- `android/app/build.gradle.kts` - Change `applicationId` and `namespace`
- `android/app/src/main/kotlin/com/example/supportacrm/MainActivity.kt` - Move to new package path

### 1.2 Update App Version
In `pubspec.yaml`, update version:
```yaml
version: 1.0.0+1  # Format: versionName+versionCode
```
- `1.0.0` = version name (shown to users)
- `1` = version code (must increment for each release)

## Step 2: Set Up App Signing

### 2.1 Generate Keystore
Run this command in your project root:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important:** 
- Save the keystore file securely (you'll need it for all future updates)
- Remember the password and alias name
- Store credentials in a secure location

### 2.2 Create key.properties File
Create `android/key.properties` (add to .gitignore):
```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-your-keystore>/upload-keystore.jks
```

### 2.3 Update build.gradle.kts
The build.gradle.kts has been updated to use signing config.

## Step 3: Build Release Bundle (AAB)

### 3.1 Clean and Build
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### 3.2 Build App Bundle
```bash
flutter build appbundle --release
```

The AAB file will be at: `build/app/outputs/bundle/release/app-release.aab`

## Step 4: Google Play Console Setup

### 4.1 Create App
1. Go to [Google Play Console](https://play.google.com/console)
2. Click "Create app"
3. Fill in:
   - App name: "Supportta CRM"
   - Default language: English
   - App or game: App
   - Free or paid: Free
   - Declarations: Complete all required sections

### 4.2 App Content
Required sections:
- **Privacy Policy**: Create and host a privacy policy URL
- **Target Audience**: Select appropriate age group
- **Content Rating**: Complete questionnaire
- **Data Safety**: Declare what data you collect/use

### 4.3 Store Listing
Required assets:
- **App Icon**: 512x512 PNG (no transparency)
- **Feature Graphic**: 1024x500 PNG
- **Screenshots**: 
  - Phone: At least 2 (max 8), 16:9 or 9:16
  - Tablet (optional): 7" and 10"
- **Short Description**: 80 characters max
- **Full Description**: 4000 characters max
- **App Category**: Business/Productivity

### 4.4 Upload Release
1. Go to "Production" → "Create new release"
2. Upload the AAB file (`app-release.aab`)
3. Add release notes
4. Review and roll out

## Step 5: Testing (Recommended)

### 5.1 Internal Testing
1. Create internal test track
2. Upload AAB to internal testing
3. Add testers (up to 100)
4. Test thoroughly before production

### 5.2 Closed Testing
1. Create closed test track
2. Upload AAB
3. Add testers via email or Google Groups
4. Test with real users

## Step 6: Submit for Review

1. Complete all required sections (red warnings)
2. Upload AAB to production
3. Fill in all store listing details
4. Submit for review
5. Wait for approval (usually 1-7 days)

## Important Notes

⚠️ **Package Name**: Once published, you CANNOT change the package name. Choose carefully!

⚠️ **Version Code**: Must increment for each release (1, 2, 3, ...)

⚠️ **Keystore**: Keep it safe! You need it for all future updates.

⚠️ **Privacy Policy**: Required for apps that collect data (Supabase, etc.)

## Quick Commands Reference

```bash
# Build release bundle
flutter build appbundle --release

# Build APK (for testing)
flutter build apk --release

# Check app size
flutter build appbundle --release --analyze-size

# Test on device
flutter install --release
```

## Troubleshooting

**Issue**: "Upload failed: You need to use a different package name"
- **Solution**: Change package name in build.gradle.kts

**Issue**: "App signing error"
- **Solution**: Verify key.properties file and keystore path

**Issue**: "Version code already used"
- **Solution**: Increment version code in pubspec.yaml

