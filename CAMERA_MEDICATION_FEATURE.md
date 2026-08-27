# Camera-Based Medication Entry Feature

This feature allows users to capture medication information using their device camera and automatically extract medication details using Google's Gemini AI.

## 🎯 Features

- **Camera Icon**: Added next to the medication name field in the "Add Medication" screen
- **Camera Dialog**: Opens a live camera preview with capture button
- **Gallery Support**: Option to select existing images from the device gallery
- **AI Extraction**: Uses Google Gemini API to extract:
  - Medication name
  - Medication type (tablets, capsules, drops, etc.)
  - Pill/dosage size
  - Additional notes from the packaging
- **Auto-fill**: Automatically fills the medication form with extracted data
- **Editable**: Users can still manually edit or change the auto-filled information

## 🔧 Setup Instructions

### 1. Get a Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Create a new API key
4. Copy the API key

### 2. Configure the API Key

**Important:** The API key is stored in a file that is excluded from version control for security.

1. Navigate to `lib/config/` directory
2. Copy the template file:
   ```bash
   cp lib/config/api_keys.dart.template lib/config/api_keys.dart
   ```
3. Open `lib/config/api_keys.dart` and replace `YOUR_GEMINI_API_KEY_HERE` with your actual API key:
   ```dart
   class ApiKeys {
     static const String geminiApiKey = 'AIzaSy...your-actual-key-here';
   }
   ```

**⚠️ Security Note:** 
- The `api_keys.dart` file is in `.gitignore` and will NOT be committed to GitHub
- Never commit your actual API key to version control
- Each developer needs to create their own `api_keys.dart` file locally

### 3. Permissions (Already Configured)

The following permissions have been added to `android/app/src/main/AndroidManifest.xml`:
- `CAMERA` - To access the device camera
- `WRITE_EXTERNAL_STORAGE` - For saving captured images (Android 9 and below)

For iOS, ensure `ios/Runner/Info.plist` contains (add if missing):

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan medication labels</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select medication images</string>
```

## 📱 Usage

1. Navigate to the "Add Medication" screen
2. Click the camera icon (📷) next to the "Ime zdravila" field
3. Point the camera at the medication label/box
4. Click "Zajemi" (Capture) button
5. Wait for AI processing (shows "Obdelava..." while processing)
6. The form will auto-fill with extracted information
7. Review and edit the information if needed
8. Continue with the medication setup process

## 🏗️ Architecture

### Files Added/Modified

**New Files:**
- `lib/services/gemini_medication_service.dart` - Handles Gemini API calls
- `lib/ui/components/medication_camera_dialog.dart` - Camera dialog UI component

**Modified Files:**
- `lib/ui/screens/add_medication.dart` - Added camera icon and integration
- `lib/config/api_keys.dart` - Stores API keys (git-ignored, not in repo)
- `lib/config/api_keys.dart.template` - Template for API keys configuration
- `android/app/src/main/AndroidManifest.xml` - Added camera permissions
- `pubspec.yaml` - Added dependencies

### Dependencies Added

camera: ^0.11.0+2              # Camera access
image_picker: ^1.1.2           # Image selection from gallery
google_generative_ai: ^0.4.6   # Gemini AI API
http: ^1.2.2                   # HTTP requests
```

## 🧪 Testing

1. **Test Camera Access**: Ensure camera permission is granted on first use
2. **Test AI Extraction**: Test with various medication packages
4. **Test Auto-fill**: Verify form fields are populated correctly
5. **Test Auto-fill**: Verify form fields are populated correctly
6. **Test Manual Edit**: Ensure users can still manually edit extracted data

## 🐛 Troubleshooting

### Camera not working
- Check camera permissions in device settings
- Ensure device has a working camera
- Check for errors in the console logs

### AI extraction not working
- Verify API key is correct
- Check internet connection
- Ensure Gemini API quota is not exceeded
- Check API key restrictions in Google Cloud Console

### Poor extraction accuracy
- Ensure good lighting when capturing images
- Capture images with clear, focused medication labels
- Try different angles or closer shots
- The AI will return `null` for fields it cannot identify

## 🔮 Future Improvements

- [ ] Add loading indicator during API call
- [ ] Implement retry mechanism for failed extractions
- [ ] Add option to crop/rotate images before processing
- [ ] Store API key securely in environment variables
- [ ] Add multiple language support for medication labels
- [ ] Cache extracted results to avoid duplicate API calls
- [ ] Add confidence scores for extracted data
- [ ] Support for multiple medications in one image

## 📄 License

This feature integrates with Google's Gemini API. Ensure compliance with [Google's Generative AI Terms of Service](https://ai.google.dev/terms).
