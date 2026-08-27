# Onboarding Flow - Lekec

## Overview
The onboarding flow is designed to welcome new users and help them set up the Lekec medication reminder app based on their specific use case.

## Onboarding Screens

### 1. Welcome Screen
- **Purpose**: Introduce the app and its key features
- **Greeting**: "Pozdravljeni v Lekec" (Welcome to Lekec)
- **Features Highlighted**:
  - 🔔 Smart reminders for medications
  - 📅 Flexible scheduling options
  - 👥 Multi-user support for families

### 2. User Type Selection
Users can choose from three usage scenarios:

#### Personal Use (`UserType.personal`)
- For individuals tracking their own medications
- Icon: Person
- Title: "Osebna uporaba"

#### Family Use (`UserType.family`)
- For managing medications for family members
- Icon: Family
- Title: "Družinska uporaba"
- Additional field: Family name (optional)

#### Caregiver/Medical Professional (`UserType.caregiver`)
- For healthcare workers or caregivers helping elderly/multiple people
- Icon: Medical Services
- Title: "Negovalec / Zdravstveni delavec"

### 3. User Setup
- **Dynamic based on user type**:
  - Personal: "Kako vam rečejo?" (What's your name?)
  - Family: "Kdo bo uporabljal aplikacijo?" (Who will use the app?)
  - Caregiver: "Dodajte osebe, za katere skrbite" (Add people you care for)

- **Features**:
  - Add multiple users
  - Family name field (only for family type)
  - User list with avatars
  - Delete users option

### 4. App Guide
- **4-step tutorial** explaining:
  1. Adding medications
  2. Setting schedules
  3. Receiving reminders
  4. Tracking history

- **Personalized greeting**: Uses the first added user's name
- **Skip option**: Users can skip to start using the app immediately

## Technical Implementation

### Database
- **Table**: `OnboardingSettings`
- **Fields**:
  - `id`: Auto-increment primary key
  - `isCompleted`: Boolean (default: false)
  - `userType`: Enum (personal/family/caregiver)
  - `familyName`: Nullable text
  - `completedAt`: Nullable datetime

### File Structure
```
lib/
├── database/tables/
│   └── onboarding_settings.dart          # Data model
├── ui/screens/onboarding/
│   ├── welcome_screen.dart               # Step 1
│   ├── user_type_selection_screen.dart   # Step 2
│   ├── user_setup_screen.dart            # Step 3
│   ├── app_guide_screen.dart             # Step 4
│   └── onboarding_flow.dart              # Controller
└── features/core/providers/
    └── onboarding_provider.dart          # State management
```

### Provider
```dart
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = await (db.select(db.onboardingSettings)..limit(1)).getSingleOrNull();
  return settings?.isCompleted ?? false;
});
```

## Flow Logic

1. **App Launch**: Check if onboarding is completed
2. **First Launch**: Show onboarding flow
3. **Subsequent Launches**: Go directly to main app
4. **On Completion**:
   - Create users in database
   - Set first user as default
   - Mark onboarding as completed
   - Save user type and family name
   - Navigate to main app

## User Experience Features

### Personalization
- Greets user by name in the app guide
- Different messaging based on user type
- Family name stored for future use

### Visual Design
- Material Design 3 (Material Symbols Icons)
- Color-coded cards for user types
- Smooth transitions between screens
- Progress indicators (page dots)

### Accessibility
- Clear, readable text
- Large tap targets
- Skip option available
- Back navigation supported

## Testing

### Reset Onboarding
For testing purposes, you can reset the onboarding flow:

1. Go to **Developer Settings** (from main menu)
2. Tap **Reset Onboarding**
3. Restart the app
4. Onboarding screens will appear again

### Manual Database Reset
```dart
await db.delete(db.onboardingSettings).go();
ref.invalidate(onboardingStatusProvider);
```

## Future Enhancements

Potential improvements for the onboarding flow:

1. **User Profiles**: Add photos or avatars for users
2. **Permissions**: Request notification permissions during onboarding
3. **Tutorial**: Interactive tutorial with actual medication addition
4. **Import**: Allow importing existing medication data
5. **Language**: Detect system language and show appropriate greeting
6. **Analytics**: Track which user types are most common
7. **Customization**: Let users customize notification sounds during onboarding

## Localization

Current language: **Slovenian (Slovene)**

Key phrases:
- "Pozdravljeni" - Greetings/Welcome
- "Začnimo" - Let's begin
- "Naprej" - Next
- "Preskoči" - Skip
- "Začnimo!" - Let's start!

## Schema Migration

The onboarding table was added in **schema version 6**:

```dart
if (from < 6) {
  await m.createTable(onboardingSettings);
}
```

## Dependencies

- `drift`: Database ORM
- `flutter_riverpod`: State management
- `material_symbols_icons`: Modern icons
- `go_router`: Navigation (for main app)
