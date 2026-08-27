import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lekec/ui/screens/ring.dart';
import 'package:lekec/ui/screens/appointment_ring_screen.dart';
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
import 'ui/screens/people_screen.dart';

export 'ui/screens/dashboard.dart' show DashboardScreenState;
export 'ui/screens/user_medications_screen.dart'
    show UserMedicationsScreenState;
import 'ui/screens/user_medications_screen.dart';
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
import 'ui/screens/add_appointment_screen.dart';
import 'ui/screens/medication_detail_screen.dart';
import 'features/core/providers/database_provider.dart';
import 'features/core/providers/theme_provider.dart';
import 'features/core/providers/onboarding_provider.dart';
import 'database/tables/medications.dart';
import 'data/services/server_message_service.dart';
import 'services/gemini_medication_service.dart';
import 'services/permission.dart';
import 'ui/theme/app_theme.dart';
import 'data/services/intake_schedule_generator.dart';
import 'data/services/notification_service.dart';
import 'data/services/notification_action_service.dart';
import 'data/services/background_task_service.dart';
import 'ui/screens/onboarding/onboarding_flow.dart';

export 'ui/widgets/medication_card.dart' show MedicationStatus;

late final AppDatabase db;
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<DashboardScreenState> homePageKey =
    GlobalKey<DashboardScreenState>();
final GlobalKey<MedsScreenState> medsPageKey = GlobalKey<MedsScreenState>();
final GlobalKey<UserMedicationsScreenState> userDetailsPageKey =
    GlobalKey<UserMedicationsScreenState>();

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
              path: '/history',
              builder: (context, state) => const MedsHistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/meds',
              builder: (context, state) => MedsScreen(key: medsPageKey),
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
              path: '/people',
              builder: (context, state) => const PeopleScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/ring',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final alarmSettings = state.extra as AlarmSettings;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ExampleAlarmRingScreen(alarmSettings: alarmSettings),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // No animation - instant appearance
            return child;
          },
        );
      },
    ),
    GoRoute(
      path: '/appointment-ring',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        final alarmSettings = state.extra as AlarmSettings;
        return CustomTransitionPage(
          key: state.pageKey,
          child: AppointmentRingScreen(alarmSettings: alarmSettings),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),
    GoRoute(
      path: '/dev',
      builder: (context, state) => const DeveloperSettingsScreen(),
    ),
    GoRoute(
      path: '/add-medication',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final presetTypeIndex = extra?['presetTypeIndex'] as int?;
        return AddMedicationScreen(
          presetName: extra?['presetName'] as String?,
          presetType: presetTypeIndex != null
              ? MedicationType.values[presetTypeIndex]
              : null,
          presetIntakeAdvice: extra?['presetIntakeAdvice'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/frequency',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        return MedicationFrequencySelectionScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          intakeAdvice: extra['intakeAdvice'] as String,
          userId: extra['userId'] as int,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/simple-planning',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        final frequencyIndex = extra['frequencyIndex'] as int;
        return SimpleMedicationPlanningScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          frequency: FrequencyOption.values[frequencyIndex],
          userId: extra['userId'] as int,
          intakeAdvice: extra['intakeAdvice'] as String,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        return AdvancedMedicationPlanningScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          intakeAdvice: extra['intakeAdvice'] as String,
          userId: extra['userId'] as int,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/interval',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        return IntervalPlanningScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          intakeAdvice: extra['intakeAdvice'] as String,
          userId: extra['userId'] as int,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/interval/configure',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        final intervalTypeIndex = extra['intervalTypeIndex'] as int;
        return IntervalConfigureScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          intervalType: IntervalType.values[intervalTypeIndex],
          intervalValue: extra['intervalValue'] as int,
          intakeAdvice: extra['intakeAdvice'] as String,
          userId: extra['userId'] as int,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/multiple-times',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        return MultipleTimesPlanningScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          intakeAdvice: extra['intakeAdvice'] as String,
          userId: extra['userId'] as int,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/multiple-times/times',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        return MultipleTimesSelectTimesScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          timesPerDay: extra['timesPerDay'] as int,
          intakeAdvice: extra['intakeAdvice'] as String,
          userId: extra['userId'] as int,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/specific-days',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        return SpecificDaysPlanningScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          intakeAdvice: extra['intakeAdvice'] as String,
          userId: extra['userId'] as int,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/specific-days/times',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        return SpecificDaysSelectTimesScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          selectedDays: List<int>.from(extra['selectedDays'] as List),
          intakeAdvice: extra['intakeAdvice'] as String,
          userId: extra['userId'] as int,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/cyclic',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        return CyclicPlanningScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          intakeAdvice: extra['intakeAdvice'] as String,
          userId: extra['userId'] as int,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-medication/advanced-planning/cyclic/configure',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        return CyclicConfigureScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          takingDays: extra['takingDays'] as int,
          pauseDays: extra['pauseDays'] as int,
          intakeAdvice: extra['intakeAdvice'] as String,
          userId: extra['userId'] as int,
          extractedData: extra['extractedData'] as MedicationExtractionResult?,
        );
      },
    ),
    GoRoute(
      path: '/add-single-entry',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AddSingleEntryScreen(userId: extra?['userId'] as int? ?? 1);
      },
    ),
    GoRoute(
      path: '/add-single-entry/quantity',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final medTypeIndex = extra['medTypeIndex'] as int;
        return AddSingleEntryQuantityScreen(
          medicationName: extra['name'] as String,
          medType: MedicationType.values[medTypeIndex],
          userId: extra['userId'] as int,
        );
      },
    ),
    GoRoute(
      path: '/add-appointment',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AddAppointmentScreen(
          userId: extra?['userId'] as int? ?? 1,
          existingAppointment: extra?['existingAppointment'] as Appointment?,
        );
      },
    ),
    GoRoute(
      path: '/medication-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MedicationDetailScreen(
          medicationId: extra['medicationId'] as int,
          medicationName: extra['medicationName'] as String,
          medType: extra['medType'] as MedicationType,
          pillsRemaining: extra['pillsRemaining'] as int,
          dosageAmount: extra['dosageAmount'] as double,
          frequency: extra['frequency'] as String,
          times: (extra['times'] as List).cast<String>(),
          intakeAdvice: extra['intakeAdvice'] as String?,
          criticalReminder: extra['criticalReminder'] as bool,
          onDelete: extra['onDelete'] as Future<void> Function(),
          onRefresh: extra['onRefresh'] as VoidCallback,
          isAsNeeded: (extra['isAsNeeded'] as bool?) ?? false,
          planId: extra['planId'] as int?,
          userId: extra['userId'] as int?,
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
            icon: Icon(Symbols.manage_search),
            label: 'Zgodovina',
          ),
          NavigationDestination(icon: Icon(Symbols.pill), label: 'Zdravila'),
          NavigationDestination(
            icon: Icon(Symbols.home),
            label: 'Tekoči pregled',
          ),
          NavigationDestination(icon: Icon(Symbols.group), label: 'Osebe'),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: true);
  }
}

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  setupLogging(showDebugLogs: true);

  // Initialize database early — constructor is cheap (lazy open)
  db = AppDatabase();
  AlarmService alarmService = AlarmService(rootNavigatorKey, db);

  try {
    // PRIORITY: Initialize alarm service FIRST for fastest response.
    // Retry once if platform channel isn't ready (hot restart / cold start race).
    try {
      await Alarm.init().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          Logger('main').warning('Alarm.init() timed out — continuing without it');
        },
      );
    } catch (e) {
      Logger('main').warning('Alarm.init() failed, retrying: $e');
      await Future.delayed(const Duration(milliseconds: 500));
      await Alarm.init().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          Logger('main').warning('Alarm.init() retry timed out');
        },
      );
    }

    // Initialize listeners
    alarmService.initialize();

    // Apply notification action button taps recorded while the app was closed
    // ("Sem vzel" / "Bom preskočil" / "Razumem") BEFORE checkInitialRingingAlarms
    // runs below — otherwise a just-handled alarm could re-pop its ring screen.
    await NotificationActionService(db)
        .drainPendingActions()
        .timeout(const Duration(seconds: 10), onTimeout: () {});

    // Keep applying taps as they happen: the ringing set changes whenever an
    // alarm starts or stops, including a stop triggered by a notification
    // action button.
    Alarm.ringing.listen((_) {
      NotificationActionService(db).drainPendingActions();
    });

    // Kill-warning notification is disabled app-wide (all alarms are set with
    // warningNotificationOnKill: false). Alarms persisted by older builds may
    // still carry the flag and keep the on-kill service running, so tear it
    // down explicitly on every launch. Re-enable the feature by restoring
    // setWarningNotificationOnKill here and the flags in NotificationService.
    await Alarm.disableWarningNotificationOnKill()
        .timeout(const Duration(seconds: 3), onTimeout: () {});
  } catch (e, st) {
    Logger('main').severe('Critical startup error', e, st);
  }

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

  // Check for ringing alarms ASAP after first frame, then remove splash
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
    alarmService.checkInitialRingingAlarms();
  });

  // Defer heavy initialization — give providers time to resolve first
  // so the app renders before background DB-heavy tasks start
  Future.delayed(const Duration(seconds: 2), () {
    _initializeServicesInBackground();
  });
}


// Run heavy initialization in background after app starts
Future<void> _initializeServicesInBackground() async {
  try {
    // Set screen orientation
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Apply any notification action button taps made while the app was closed.
    await NotificationActionService(db).drainPendingActions();

    // Generate upcoming intake schedules
    final scheduleGenerator = IntakeScheduleGenerator(db);

    // Clean up duplicates with a safety timeout so it can't block forever
    try {
      await scheduleGenerator.removeDuplicateEntries().timeout(
        const Duration(seconds: 15),
      );
    } catch (e) {
      Logger('main').warning('removeDuplicateEntries timed out or failed: $e');
    }

    try {
      await scheduleGenerator.generateScheduledIntakes().timeout(
        const Duration(seconds: 30),
      );
    } catch (e) {
      Logger(
        'main',
      ).warning('generateScheduledIntakes timed out or failed: $e');
    }

    // Schedule notifications for upcoming intakes
    try {
      await notificationService
          .scheduleAllUpcomingNotifications(db)
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      Logger('main').warning('scheduleAllUpcomingNotifications failed: $e');
    }

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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  /// Skip the very first `resumed` event — it fires right after the app is
  /// pushed to the foreground at cold start, and `_initializeServicesInBackground`
  /// already covers that path. Without this guard we'd run the same heavy work
  /// twice on every cold start.
  bool _skipFirstResume = true;

  /// Action buttons on non-critical reminders are delivered to a background
  /// isolate (see notificationTapBackground), so a tap made while the app is
  /// open isn't seen here directly. Poll the queue so those taps still get
  /// applied promptly without needing an app resume.
  Timer? _actionDrainTimer;

  /// Guards the one-per-launch full-screen-intent permission re-check.
  bool _fsiChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _actionDrainTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      NotificationActionService(db).drainPendingActions();
    });
  }

  @override
  void dispose() {
    _actionDrainTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_skipFirstResume) {
      _skipFirstResume = false;
      return;
    }
    _refreshSchedulesOnResume();
  }

  /// Triggered when the app comes back to the foreground. Extends the intake
  /// schedule horizon and re-arms OS notifications/alarms so a long backgrounded
  /// session can't leave the user without upcoming reminders.
  Future<void> _refreshSchedulesOnResume() async {
    // Pick up any notification action taps made while backgrounded.
    await NotificationActionService(db).drainPendingActions();
    // Re-check server messages (throttled inside; silent when offline).
    ServerMessageService(db).syncFromServer();
    try {
      final generator = IntakeScheduleGenerator(db);
      await generator.generateScheduledIntakes().timeout(
        const Duration(seconds: 30),
      );
    } catch (e) {
      Logger('main').warning('Resume: generateScheduledIntakes failed: $e');
    }
    try {
      await NotificationService()
          .scheduleAllUpcomingNotifications(db)
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      Logger('main').warning('Resume: scheduleAllUpcomingNotifications failed: $e');
    }
  }

  /// Re-checks the Android 14+ full-screen-intent permission once per launch.
  /// Without it, alarm reminders can't appear over the lock screen — and the
  /// grant is silently lost on an uninstall/reinstall or an OS upgrade, so the
  /// onboarding-time check alone isn't enough.
  void _scheduleFullScreenIntentCheck() {
    if (_fsiChecked) return;
    _fsiChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptFullScreenIntentIfNeeded();
    });
  }

  Future<void> _promptFullScreenIntentIfNeeded() async {
    // Let the app settle — and let any cold-start alarm screen open first.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // Never interrupt a ringing alarm with this dialog.
    if (Alarm.ringing.value.alarms.isNotEmpty) return;
    if (await AlarmPermissions.isFullScreenIntentAllowed()) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Symbols.lock_open),
        title: const Text('Opomniki se ne prikažejo čez zaklenjen zaslon'),
        content: const Text(
          'Da se opomnik za zdravilo pokaže čez zaklenjen zaslon — brez '
          'predhodnega odklepanja — mora imeti Lekec dovoljenje za '
          'celozaslonska obvestila.\n\nTo dovoljenje se ponastavi ob ponovni '
          'namestitvi aplikacije. Odprite nastavitve in ga znova omogočite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Pozneje'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              AlarmPermissions.openFullScreenIntentSettings();
            },
            child: const Text('Odpri nastavitve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final onboardingStatus = ref.watch(onboardingStatusProvider);

    return onboardingStatus.when(
      data: (isCompleted) {
        if (!isCompleted) {
          // Show onboarding flow
          return MaterialApp(
            title: 'Lekec',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode.value ?? ThemeMode.system,
            home: OnboardingFlow(
              onComplete: () {
                // Refresh the onboarding status to show the main app
                ref.invalidate(onboardingStatusProvider);
                // Use a slight delay to ensure the provider updates before navigation
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (rootNavigatorKey.currentContext != null) {
                    rootNavigatorKey.currentContext!.go('/meds');
                  }
                });
              },
            ),
          );
        }

        // Show main app
        _scheduleFullScreenIntentCheck();
        return MaterialApp.router(
          title: 'Lekec',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode.value ?? ThemeMode.system,
          routerConfig: _router,
        );
      },
      loading: () => MaterialApp(
        title: 'Lekec',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode.value ?? ThemeMode.system,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stack) => MaterialApp(
        title: 'Lekec',
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: Text('Napaka: $error'))),
      ),
    );
  }
}
