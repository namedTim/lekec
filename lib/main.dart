// drift InsertMode not used here; rely on default insert behavior
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:lekec/database/drift_database.dart';
import 'ui/screens/developer_settings.dart';
import 'ui/screens/meds.dart';
import 'ui/screens/meds_history.dart';
import 'ui/screens/add_medication.dart';
import 'ui/screens/medication_frequency_selection.dart';
import 'ui/screens/simple_medication_planning.dart';
import 'features/core/providers/database_provider.dart';
import 'features/core/providers/theme_provider.dart';
import 'package:lekec/database/tables/medications.dart';
import '/ui/screens/medication_frequency_selection.dart'
    show FrequencyOption;

import 'ui/theme/app_theme.dart';
import 'ui/widgets/medication_card.dart';
import 'ui/widgets/time_island.dart';
import 'ui/components/time_slot.dart';
import 'data/services/intake_schedule_generator.dart';
import 'package:drift/drift.dart' as drift;
import 'data/services/notification_service.dart';
import 'data/services/background_task_service.dart';

export 'ui/widgets/medication_card.dart' show MedicationStatus;

late final AppDatabase db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  db = AppDatabase();

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

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
    ],
    child: const MyApp(),
  ));
}

final _router = GoRouter(
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
              builder: (context, state) => MyHomePage(key: homePageKey, title: 'Lekec'),
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
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

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
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Symbols.pill),
            label: 'Zdravila',
          ),
          NavigationDestination(
            icon: const Icon(Symbols.home),
            label: 'Tekoči pregled',
          ),
          NavigationDestination(
            icon: const Icon(Symbols.manage_search),
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

final GlobalKey<_MyHomePageState> homePageKey = GlobalKey<_MyHomePageState>();

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final controller = TimeIslandController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();
  
  Map<String, List<Map<String, dynamic>>> _groupedIntakes = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    loadTodaysIntakes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadTodaysIntakes() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final intakes = await (db.select(db.medicationIntakeLogs)
          ..where((t) => t.scheduledTime.isBiggerOrEqualValue(startOfDay))
          ..where((t) => t.scheduledTime.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.scheduledTime)]))
        .get();

    // Load medication details for each intake
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final intake in intakes) {
      final plan = await (db.select(db.medicationPlans)
            ..where((t) => t.id.equals(intake.planId)))
          .getSingleOrNull();
      
      if (plan == null) continue;
      
      final medication = await (db.select(db.medications)
            ..where((t) => t.id.equals(plan.medicationId)))
          .getSingleOrNull();
      
      if (medication == null) continue;

      final timeKey = '${intake.scheduledTime.hour.toString().padLeft(2, '0')}:${intake.scheduledTime.minute.toString().padLeft(2, '0')}';
      
      grouped.putIfAbsent(timeKey, () => []);
      grouped[timeKey]!.add({
        'intake': intake,
        'plan': plan,
        'medication': medication,
      });
    }

    setState(() {
      _groupedIntakes = grouped;
    });

    // Scroll to next intake
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNextIntake();
    });
  }

  void _scrollToNextIntake() {
    if (_groupedIntakes.isEmpty) return;
    
    final now = DateTime.now();
    final times = _groupedIntakes.keys.toList();
    
    // Find the next upcoming time
    int nextIndex = times.indexWhere((timeStr) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final timeToday = DateTime(now.year, now.month, now.day, hour, minute);
      return timeToday.isAfter(now);
    });

    if (nextIndex > 0 && _scrollController.hasClients) {
      // Scroll to show the next time slot near the top
      // Each time slot + cards is roughly 100-150px, adjust as needed
      final offset = (nextIndex * 120.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _updateIntakeStatus(int intakeId, MedicationStatus newStatus) async {
    try {
      final wasTaken = newStatus == MedicationStatus.taken;
      
      await (db.update(db.medicationIntakeLogs)
            ..where((t) => t.id.equals(intakeId)))
          .write(MedicationIntakeLogsCompanion(
            wasTaken: drift.Value(wasTaken),
            takenTime: drift.Value(wasTaken ? DateTime.now() : null),
          ));

      // Refresh the view
      await loadTodaysIntakes();

      if (mounted) {
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasTaken ? 'Vnos zdravila zabeležen' : 'Zdravilo označeno kot ne-vzeto',
              style: TextStyle(color: colors.onSurface),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: colors.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Napaka: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleSpeedDial() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onAddSingleEntry() {
    _toggleSpeedDial();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dodaj enkraten vnos')),
    );
  }

  void _onAddNewMedication() {
    _toggleSpeedDial();
    context.push('/add-medication');
  }

  String _getMedicationUnit(MedicationType type) {
    switch (type) {
      case MedicationType.pills:
        return 'tableto/e';
      case MedicationType.capsules:
        return 'kapsulo/e';
      case MedicationType.drops:
        return 'kapljic/o';
      case MedicationType.milliliters:
        return 'ml';
      case MedicationType.sprays:
        return 'brizgov/a';
      case MedicationType.injections:
        return 'injekcijo/e';
      case MedicationType.patches:
        return 'obliž/ev';
      case MedicationType.puffs:
        return 'vdihov/a';
      case MedicationType.applications:
        return 'nanosov/a';
      case MedicationType.ampules:
        return 'ampulo/e';
      case MedicationType.grams:
        return 'gramov/a';
      case MedicationType.milligrams:
        return 'mg';
      case MedicationType.micrograms:
        return 'mcg';
      case MedicationType.tablespoons:
        return 'žličk/o';
      case MedicationType.portions:
        return 'porcijo/e';
      case MedicationType.pieces:
        return 'kos/ov';
      case MedicationType.units:
        return 'enot/o';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TimeIsland(
                totalDuration: const Duration(minutes: 30),
                remainingDuration: const Duration(minutes: 5),
                controller: controller,
              ),
            ),
          ),
          Expanded(
            child: _groupedIntakes.isEmpty
                ? Center(
                    child: Text(
                      'Ni načrtovanih zdravil za danes',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _groupedIntakes.length,
                    itemBuilder: (context, index) {
                      final timeKey = _groupedIntakes.keys.elementAt(index);
                      final intakesAtTime = _groupedIntakes[timeKey]!;

                      // Determine if this time slot is in the past
                      final now = DateTime.now();
                      final parts = timeKey.split(':');
                      final hour = int.parse(parts[0]);
                      final minute = int.parse(parts[1]);
                      final slotTime = DateTime(now.year, now.month, now.day, hour, minute);
                      final isPast = slotTime.isBefore(now);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TimeSlot(time: timeKey, isPast: isPast),
                          ...intakesAtTime.map((intakeData) {
                            final medication = intakeData['medication'] as Medication;
                            final plan = intakeData['plan'] as MedicationPlan;
                            final intake = intakeData['intake'] as MedicationIntakeLog;

                            // Determine status based on wasTaken and time
                            MedicationStatus status;
                            if (intake.wasTaken) {
                              status = MedicationStatus.taken;
                            } else if (isPast) {
                              status = MedicationStatus.notTaken;
                            } else {
                              status = MedicationStatus.upcoming;
                            }

                            return MedicationCard(
                              medName: medication.name,
                              dosage: '${plan.dosageAmount.toInt()} ${_getMedicationUnit(medication.medType)}',
                              medicineRemaining: '', // TODO: Calculate remaining
                              pillCount: 0, // TODO: Calculate from inventory
                              showName: false,
                              username: 'jaz', // TODO: Get from user
                              userId: '1',
                              status: status,
                              onStatusChanged: (newStatus) async {
                                await _updateIntakeStatus(intake.id, newStatus);
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Speed dial options
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              if (!_isExpanded && _animation.value == 0) {
                return const SizedBox.shrink();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Option 2: Add new medication
                  Transform.scale(
                    scale: _animation.value,
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: _animation.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Dodaj novo zdravilo',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FloatingActionButton(
                              heroTag: 'add_medication',
                              mini: true,
                              onPressed: _onAddNewMedication,
                              child: const Icon(Symbols.pill),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Option 1: Add single entry
                  Transform.scale(
                    scale: _animation.value,
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: _animation.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Dodaj enkraten vnos zdravila',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FloatingActionButton(
                              heroTag: 'add_entry',
                              mini: true,
                              onPressed: _onAddSingleEntry,
                              child: const Icon(Symbols.add),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Main FAB
          FloatingActionButton(
            heroTag: 'main_fab',
            onPressed: _toggleSpeedDial,
            tooltip: 'Dodaj',
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                bottomLeft: Radius.circular(32),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Symbols.pill),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}