import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:lekec/screens/ring.dart';
import 'package:lekec/services/alarm_service.dart';
import 'package:lekec/utils/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'database/drift_database.dart';
import 'ui/screens/developer_settings.dart';
import 'ui/screens/meds.dart';
import 'ui/screens/meds_history.dart';
import 'ui/screens/dashboard.dart';

export 'ui/screens/dashboard.dart' show DashboardScreenState;
import 'ui/screens/add_medication.dart';
import 'ui/screens/add_single_entry.dart';
import 'ui/screens/add_single_entry_quantity.dart';
import 'ui/screens/medication_frequency_selection.dart';
import 'ui/screens/simple_medication_planning.dart';
import 'ui/screens/advanced_medication_planning.dart';
import 'ui/screens/interval_planning.dart';
import 'ui/screens/interval_configure.dart';
import 'ui/screens/multiple_times_planning.dart';
import 'ui/screens/multiple_times_select_times.dart';
import 'ui/screens/specific_days_planning.dart';
import 'ui/screens/specific_days_select_times.dart';
import 'ui/screens/cyclic_planning.dart';
import 'ui/screens/cyclic_configure.dart';
import 'features/core/providers/database_provider.dart';
import 'features/core/providers/theme_provider.dart';
import 'database/tables/medications.dart';
import 'ui/theme/app_theme.dart';
import 'data/services/intake_schedule_generator.dart';
import 'data/services/notification_service.dart';
import 'data/services/background_task_service.dart';

export 'ui/widgets/medication_card.dart' show MedicationStatus;

late final AppDatabase db;
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<DashboardScreenState> homePageKey =
    GlobalKey<DashboardScreenState>();

final _router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/meds',
              builder: (context, state) => const MedsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  DashboardScreen(key: homePageKey, title: 'Lekec'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const MedsHistoryScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/ring',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final alarmSettings = state.extra as AlarmSettings;
        return ExampleAlarmRingScreen(alarmSettings: alarmSettings);
      },
    ),
    GoRoute(
      path: '/dev',
      builder: (context, state) => const DeveloperSettingsScreen(),
    ),
    GoRoute(
      path: '/add-medication',
      builder: (context, state) => const AddMedicationScreen(),
    ),
    GoRoute(
      path: '/add-medication/frequency',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MedicationFrequencySelectionScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          intakeAdvice: extra['intakeAdvice'] as String,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/simple-planning',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return SimpleMedicationPlanningScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          frequency: extra['frequency'] as FrequencyOption,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return AdvancedMedicationPlanningScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          intakeAdvice: extra['intakeAdvice'] as String,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/interval',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return IntervalPlanningScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          intakeAdvice: extra['intakeAdvice'] as String,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/interval/configure',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return IntervalConfigureScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          intervalType: extra['intervalType'] as IntervalType,
          intervalValue: extra['intervalValue'] as int,
          intakeAdvice: extra['intakeAdvice'] as String,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/multiple-times',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MultipleTimesPlanningScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          intakeAdvice: extra['intakeAdvice'] as String,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/multiple-times/times',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MultipleTimesSelectTimesScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          timesPerDay: extra['timesPerDay'] as int,
          intakeAdvice: extra['intakeAdvice'] as String,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/specific-days',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return SpecificDaysPlanningScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          intakeAdvice: extra['intakeAdvice'] as String,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/specific-days/times',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return SpecificDaysSelectTimesScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          selectedDays: List<int>.from(extra['selectedDays'] as List),
          intakeAdvice: extra['intakeAdvice'] as String,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/cyclic',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CyclicPlanningScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          intakeAdvice: extra['intakeAdvice'] as String,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/cyclic/configure',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CyclicConfigureScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
          takingDays: extra['takingDays'] as int,
          pauseDays: extra['pauseDays'] as int,
          intakeAdvice: extra['intakeAdvice'] as String,
        );
      },
    ),
    GoRoute(
      path: '/add-single-entry',
      builder: (context, state) => const AddSingleEntryScreen(),
    ),
    GoRoute(
      path: '/add-single-entry/quantity',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return AddSingleEntryQuantityScreen(
          medicationName: extra['name'] as String,
          medType: extra['medType'] as MedicationType,
        );
      },
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) => _onTap(context, index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Symbols.pill),
            label: 'Zdravila',
          ),
          NavigationDestination(
            icon: Icon(Symbols.home),
            label: 'Tekoči pregled',
          ),
          NavigationDestination(
            icon: Icon(Symbols.manage_search),
            label: 'Zgodovina',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  setupLogging(showDebugLogs: true);

  // PRIORITY: Initialize alarm service FIRST for fastest response
  await Alarm.init();
  
  // Create alarm service immediately and initialize listeners
  final alarmService = AlarmService(rootNavigatorKey);
  alarmService.initialize();

  // Initialize database (quick, no heavy operations)
  db = AppDatabase();

  // Set alarm warning notification
  await Alarm.setWarningNotificationOnKill(
    "Aktivnost opozoril",
    "Pustite aplikacijo zagnano v ozadju, da prejmete opozorila o zdravilih.",
  );

  // Start the app immediately so alarm can show
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        alarmServiceProvider.overrideWithValue(alarmService),
      ],
      child: const MyApp(),
    ),
  );

  // Check for ringing alarms ASAP after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    alarmService.checkInitialRingingAlarms();
  });

  // Defer heavy initialization to background after app is running
  _initializeServicesInBackground();
}

// Run heavy initialization in background after app starts
Future<void> _initializeServicesInBackground() async {
  try {
    // Set screen orientation
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Generate upcoming intake schedules
    final scheduleGenerator = IntakeScheduleGenerator(db);
    await scheduleGenerator.generateScheduledIntakes();

    // Schedule notifications for upcoming intakes
    await notificationService.scheduleAllUpcomingNotifications(db);

    // Initialize and schedule background tasks
    final backgroundService = BackgroundTaskService();
    await backgroundService.initialize();
    await backgroundService.scheduleScheduleGeneration();
    await backgroundService.scheduleNotificationRefresh();

    Logger('main').info('Background services initialized successfully');
  } catch (e, st) {
    Logger('main').severe('Error initializing background services', e, st);
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Lekec',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode.value ?? ThemeMode.system,
      routerConfig: _router,
    );
  }
}
