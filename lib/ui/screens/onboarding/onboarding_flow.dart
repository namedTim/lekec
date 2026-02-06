import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/drift_database.dart';
import '../../../database/tables/onboarding_settings.dart';
import '../../../features/core/providers/database_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'welcome_screen.dart';
import 'user_type_selection_screen.dart';
import 'user_setup_screen.dart';
import 'app_guide_screen.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _currentStep = 0;
  UserType? _selectedUserType;
  String? _familyName;
  List<String> _userNames = [];

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _handleUserTypeSelection(UserType userType) {
    setState(() {
      _selectedUserType = userType;
      _currentStep++;
    });
  }

  void _handleUserSetup(String? familyName, List<String> userNames) {
    setState(() {
      _familyName = familyName;
      _userNames = userNames;
      _currentStep++;
    });
  }

  Future<void> _completeOnboarding() async {
    final db = ref.read(databaseProvider);

    try {
      // Create users in database
      for (final userName in _userNames) {
        await db.into(db.users).insert(
              UsersCompanion.insert(name: userName),
            );
      }

      // Get the first user as default
      final users = await db.select(db.users).get();
      final defaultUser = users.isNotEmpty ? users.first : null;

      // Save onboarding settings
      await db.into(db.onboardingSettings).insert(
            OnboardingSettingsCompanion.insert(
              isCompleted: const drift.Value(true),
              userType: drift.Value(_selectedUserType),
              familyName: drift.Value(_familyName),
              completedAt: drift.Value(DateTime.now()),
            ),
          );

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
        
        // Step 1: User Type Selection
        UserTypeSelectionScreen(onNext: _handleUserTypeSelection),
        
        // Step 2: User Setup
        if (_selectedUserType != null)
          UserSetupScreen(
            userType: _selectedUserType!,
            onNext: _handleUserSetup,
          )
        else
          const SizedBox.shrink(),
        
        // Step 3: App Guide
        AppGuideScreen(
          userName: _userNames.isNotEmpty ? _userNames.first : null,
          userType: _selectedUserType,
          onComplete: _completeOnboarding,
        ),
      ],
    );
  }
}
