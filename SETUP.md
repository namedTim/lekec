# Setup Instructions for Lekec

## First Time Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure API Keys

The Gemini API key is required for the medication scanning feature but is kept secure and NOT committed to the repository.

**Step-by-step:**

1. Navigate to the config directory:
   ```bash
   cd lib/config
   ```

2. Create the API keys file from the template:
   ```bash
   cp api_keys.dart.template api_keys.dart
   ```

3. Get your Gemini API key:
   - Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Sign in with your Google account
   - Click "Create API Key"
   - Copy the generated key

4. Open `lib/config/api_keys.dart` and replace the placeholder:
   ```dart
   class ApiKeys {
     static const String geminiApiKey = 'YOUR_ACTUAL_KEY_HERE';
   }
   ```

### 3. Run the App

```bash
flutter run
```

## Important Notes

- **DO NOT** commit `lib/config/api_keys.dart` to version control
- The file is already in `.gitignore` to prevent accidental commits
- Each developer must create their own `api_keys.dart` file locally
- Never share your API key publicly or commit it to GitHub

## Troubleshooting

### "Cannot find import 'package:../config/api_keys.dart'"

This means you haven't created the `api_keys.dart` file yet. Follow step 2 above.

### API Key Not Working

- Verify the key is correct in `lib/config/api_keys.dart`
- Check that your API key has the correct permissions in Google Cloud Console
- Ensure you haven't exceeded the API quota

## For New Team Members

When you clone this repository:
1. Run `flutter pub get`
2. Create your `api_keys.dart` file (see step 2 above)
3. Get your own Gemini API key
4. Run the app

The template file `api_keys.dart.template` shows the exact structure needed.
