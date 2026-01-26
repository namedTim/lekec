import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../views/settings_view.dart';
import '../widgets/medication_details_card.dart';
import '../components/speed_dial_fab.dart';
import '../components/confirmation_dialog.dart';
import '../../database/tables/medications.dart';
import '../../features/core/providers/database_provider.dart';
import '../../helpers/medication_unit_helper.dart';
import '../../data/services/medication_service.dart';
import 'medication_detail_screen.dart';
import '../../main.dart' show homePageKey;

enum MedsTab { medications, users, settings }

class MedsScreen extends ConsumerStatefulWidget {
  const MedsScreen({super.key});

  @override
  ConsumerState<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends ConsumerState<MedsScreen> {
  MedsTab _selectedTab = MedsTab.medications;
  int _refreshKey = 0;
  final ValueNotifier<bool> _fabExpandedNotifier = ValueNotifier(false);

  @override
  void dispose() {
    _fabExpandedNotifier.dispose();
    super.dispose();
  }

  void _refreshMedications() {
    setState(() {
      _refreshKey++;
    });
  }

  Future<void> _deleteMedication(
    int medicationId,
    String medicationName,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Izbris zdravila',
      message: 'Ali želite izbrisati zdravilo $medicationName?',
    );

    if (confirmed) {
      try {
        final db = ref.read(databaseProvider);
        final medicationService = MedicationService(db);
        await medicationService.deleteMedication(medicationId);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zdravilo $medicationName je bilo izbrisano'),
              backgroundColor: Colors.green,
            ),
          );
          _refreshMedications();
          // Refresh home screen to reflect deleted medication
          homePageKey.currentState?.loadTodaysIntakes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Napaka pri brisanju: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<MedsTab>(
                      segments: const [
                        ButtonSegment<MedsTab>(
                          value: MedsTab.medications,
                          label: Text('Zdravila'),
                          icon: Icon(Symbols.pill),
                        ),
                        ButtonSegment<MedsTab>(
                          value: MedsTab.users,
                          label: Text('Uporabniki'),
                          icon: Icon(Symbols.group),
                        ),
                        ButtonSegment<MedsTab>(
                          value: MedsTab.settings,
                          label: Text('Nastavitve'),
                          icon: Icon(Symbols.settings),
                        ),
                      ],
                      selected: {_selectedTab},
                      onSelectionChanged: (Set<MedsTab> newSelection) {
                        setState(() {
                          _selectedTab = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity(horizontal: -2),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
          // Full-screen barrier when FAB is expanded
          ValueListenableBuilder<bool>(
            valueListenable: _fabExpandedNotifier,
            builder: (context, isExpanded, child) {
              if (!isExpanded) return const SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _fabExpandedNotifier.value = false;
                  },
                  child: Container(color: Colors.black.withOpacity(0.01)),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: SpeedDialFab(
        onExpandedChanged: (expanded) {
          _fabExpandedNotifier.value = expanded;
        },
        options: [
          SpeedDialOption(
            label: 'Dodaj enkraten vnos',
            icon: Symbols.add,
            heroTag: 'add_entry_meds',
            onPressed: () async {
              await context.push('/add-single-entry');
              _refreshMedications();
            },
          ),
          SpeedDialOption(
            label: 'Dodaj novo zdravilo',
            icon: Symbols.pill,
            heroTag: 'add_medication_meds',
            onPressed: () async {
              await context.push('/add-medication');
              _refreshMedications();
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    switch (_selectedTab) {
      case MedsTab.medications:
        final db = ref.watch(databaseProvider);
        final medicationService = MedicationService(db);
        return FutureBuilder(
          key: ValueKey(_refreshKey),
          future: medicationService.loadMedicationsWithDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Napaka: ${snapshot.error}'));
            }
            final medications = snapshot.data ?? [];

            if (medications.isEmpty) {
              return Center(
                child: Text(
                  'Ni dodanih zdravil.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: 88,
              ),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final med = medications[index];
                final dosageAmount = med['dosage'] as double;
                final dosageCount = dosageAmount.toInt();
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MedicationDetailScreen(
                          medicationId: med['id'] as int,
                          medicationName: med['name'] as String,
                          medType: med['medType'] as MedicationType,
                          pillsRemaining: med['remaining'] as int,
                          dosageAmount: dosageAmount,
                          frequency: med['frequency'] as String,
                          times: med['times'] as List<String>,
                          intakeAdvice: med['intakeAdvice'] as String?,
                          criticalReminder: med['criticalReminder'] as bool,
                          onDelete: () => _deleteMedication(
                            med['id'] as int,
                            med['name'] as String,
                          ),
                          onRefresh: _refreshMedications,
                        ),
                      ),
                    );
                  },
                  child: MedicationDetailsCard(
                    medName: med['name'] as String,
                    dosage:
                        '$dosageCount ${getMedicationUnit(med['medType'] as MedicationType, dosageCount)}',
                    pillsRemaining: med['remaining'] as int,
                    frequency: med['frequency'] as String,
                    times: med['times'] as List<String>,
                    medType: med['medType'] as MedicationType,
                    onAddMedication: (quantity) async {
                      try {
                        final db = ref.read(databaseProvider);
                        final currentRemaining = med['remaining'] as int;
                        final newRemaining = (currentRemaining + quantity)
                            .clamp(0, 9999);

                        await (db.update(
                          db.medications,
                        )..where((t) => t.id.equals(med['id'] as int))).write(
                          MedicationsCompanion(
                            dosagesRemaining: drift.Value(
                              newRemaining.toDouble(),
                            ),
                          ),
                        );

                        if (mounted) {
                          final absQuantity = quantity.abs();
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                quantity >= 0
                                    ? 'Dodal $quantity ${getMedicationUnitShort(med['medType'] as MedicationType, quantity)}'
                                    : 'Odstranil $absQuantity ${getMedicationUnitShort(med['medType'] as MedicationType, absQuantity)}',
                              ),
                              backgroundColor: quantity >= 0
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          );
                          _refreshMedications();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Napaka: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    onDelete: () => _deleteMedication(
                      med['id'] as int,
                      med['name'] as String,
                    ),
                  ),
                );
              },
            );
          },
        );
      case MedsTab.users:
        return const Center(child: Text('Seznam uporabnikov'));
      case MedsTab.settings:
        return const SettingsView();
    }
  }
}
