import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/drift_database.dart';
import '../../../features/core/providers/database_provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../../data/services/server_message_service.dart';
import 'welcome_screen.dart';
import 'user_setup_screen.dart';
import 'app_guide_screen.dart';
import 'permissions_screen.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _currentStep = 0;
  List<String> _userNames = [];
  List<int?> _userAges = [];
  List<String?> _userGenders = [];

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _handleUserSetup(List<String> userNames, List<int?> userAges, List<String?> userGenders) {
    setState(() {
      _userNames = userNames;
      _userAges = userAges;
      _userGenders = userGenders;
      _currentStep++;
    });
  }

  Future<void> _completeOnboarding() async {
    final db = ref.read(databaseProvider);

    try {
      // Create users in database
      for (int i = 0; i < _userNames.length; i++) {
        final userName = _userNames[i];
        final userAge = i < _userAges.length ? _userAges[i] : null;
        final userGender = i < _userGenders.length ? _userGenders[i] : null;
        await db.into(db.users).insert(
              UsersCompanion.insert(
                name: userName,
                age: drift.Value(userAge),
                gender: drift.Value(userGender),
              ),
            );
      }

      // Get the first user as default
      final users = await db.select(db.users).get();
      final defaultUser = users.isNotEmpty ? users.first : null;

      // Save onboarding settings. userType/familyName are intentionally left
      // unset — the app never reads them, so onboarding no longer collects them.
      await db.into(db.onboardingSettings).insert(
            OnboardingSettingsCompanion.insert(
              isCompleted: const drift.Value(true),
              completedAt: drift.Value(DateTime.now()),
            ),
          );

      // Greet the new user with a locally generated message; everything else
      // in server_messages comes live from the server.
      await ServerMessageService(db).insertWelcomeMessage();

      // Update app settings with default user if available
      final appSettings = await (db.select(db.appSettings)..limit(1)).getSingleOrNull();
      if (appSettings != null && defaultUser != null) {
        await (db.update(db.appSettings)..where((t) => t.id.equals(appSettings.id)))
            .write(AppSettingsCompanion(defaultUserId: drift.Value(defaultUser.id)));
      } else if (defaultUser != null) {
        // Create app settings if they don't exist
        await db.into(db.appSettings).insert(
              AppSettingsCompanion.insert(
                defaultUserId: drift.Value(defaultUser.id),
              ),
            );
      }

      widget.onComplete();
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Napaka pri shranjevanju: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentStep,
      children: [
        // Step 0: Welcome
        WelcomeScreen(onNext: _nextStep),

        // Step 1: User Setup (add people — first person is the app owner)
        UserSetupScreen(onNext: _handleUserSetup),

        // Step 2: App Guide
        AppGuideScreen(
          userName: _userNames.isNotEmpty ? _userNames.first : null,
          onComplete: _nextStep,
        ),

        // Step 3: Permissions explainer (primes the user before
        // the system permission dialogs fire).
        PermissionsScreen(onComplete: _completeOnboarding),
      ],
    );
  }
}
