import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../views/settings_view.dart';
import '../widgets/medication_details_card.dart';
import '../components/speed_dial_fab.dart';
import '../components/confirmation_dialog.dart';
import '../../database/tables/medications.dart';
import '../../features/core/providers/database_provider.dart';
import '../../utils/medication_utils.dart';
import 'dart:convert';

enum MedsTab { medications, users, settings }

class MedsScreen extends ConsumerStatefulWidget {
  const MedsScreen({super.key});

  @override
  ConsumerState<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends ConsumerState<MedsScreen> {
  MedsTab _selectedTab = MedsTab.medications;
  int _refreshKey = 0;

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
        await (db.delete(
          db.medications,
        )..where((m) => m.id.equals(medicationId))).go();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zdravilo $medicationName je bilo izbrisano'),
              backgroundColor: Colors.green,
            ),
          );
          _refreshMedications();
        }
      } catch (e) {
        if (mounted) {
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
      body: SafeArea(
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
      floatingActionButton: SpeedDialFab(
        options: [
          SpeedDialOption(
            label: 'Dodaj novo zdravilo',
            icon: Symbols.pill,
            heroTag: 'add_medication',
            onPressed: () {
              context.push('/add-medication');
            },
          ),
          SpeedDialOption(
            label: 'Dodaj enkraten vnos',
            icon: Symbols.add,
            heroTag: 'add_entry',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dodaj enkraten vnos')),
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case MedsTab.medications:
        final db = ref.watch(databaseProvider);
        return FutureBuilder(
          key: ValueKey(_refreshKey),
          future: _loadMedications(db),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Napaka: ${snapshot.error}'));
            }
            final medications = snapshot.data ?? [];
            if (medications.isEmpty) {
              return const Center(
                child: Text('Ni zdravil. Dodajte novo zdravilo.'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final med = medications[index];
                return MedicationDetailsCard(
                  medName: med['name'] as String,
                  dosage: med['dosage'] as String,
                  pillsRemaining: med['remaining'] as int,
                  frequency: med['frequency'] as String,
                  times: med['times'] as List<String>,
                  medType: med['medType'] as MedicationType,
                  onAddMedication: (quantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Dodajam $quantity ${getMedicationUnitShort(med['medType'] as MedicationType)}...',
                        ),
                      ),
                    );
                  },
                  onDelete: () => _deleteMedication(
                    med['id'] as int,
                    med['name'] as String,
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

  Future<List<Map<String, dynamic>>> _loadMedications(db) async {
    final query = await db.select(db.medications).join([
      drift.leftOuterJoin(
        db.medicationPlans,
        db.medicationPlans.medicationId.equalsExp(db.medications.id),
      ),
      drift.leftOuterJoin(
        db.medicationScheduleRules,
        db.medicationScheduleRules.planId.equalsExp(db.medicationPlans.id),
      ),
    ]).get();

    final result = <Map<String, dynamic>>[];
    for (final row in query) {
      final medication = row.readTable(db.medications);
      final plan = row.readTableOrNull(db.medicationPlans);
      final rule = row.readTableOrNull(db.medicationScheduleRules);

      String frequency = 'Po potrebi';
      List<String> times = [];

      if (rule != null && rule.timesOfDay != null) {
        final timesList = (jsonDecode(rule.timesOfDay!) as List)
            .map((e) => e.toString())
            .toList();
        times = timesList;
        frequency = '${times.length}x dnevno';
      }

      result.add({
        'id': medication.id,
        'name': medication.name,
        'dosage': plan != null
            ? '${plan.dosageAmount.toInt()} ${getMedicationUnit(medication.medType)}'
            : '1 ${getMedicationUnit(medication.medType)}',
        'remaining': medication.dosagesRemaining?.toInt() ?? 0,
        'frequency': frequency,
        'times': times,
        'medType': medication.medType,
      });
    }

    return result;
  }
}
