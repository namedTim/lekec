import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import 'package:alarm/alarm.dart';
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';
import '../../data/services/medication_service.dart';
import '../../helpers/medication_unit_helper.dart';
import '../widgets/medication_details_card.dart';
import '../components/confirmation_dialog.dart';
import '../../main.dart' show db;
import '../screens/medication_detail_screen.dart';

class UserMedicationsScreen extends ConsumerStatefulWidget {
  final int userId;
  final String userName;

  const UserMedicationsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<UserMedicationsScreen> createState() =>
      _UserMedicationsScreenState();
}

class _UserMedicationsScreenState extends ConsumerState<UserMedicationsScreen> {
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserMedications();
  }

  Future<void> _loadUserMedications() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all active medication plans for this user
      final query = db.select(db.medicationPlans).join([
        drift.innerJoin(
          db.medications,
          db.medications.id.equalsExp(db.medicationPlans.medicationId),
        ),
      ])..where(
          db.medicationPlans.userId.equals(widget.userId) &
          db.medicationPlans.isActive.equals(true),
        );

      final results = await query.get();
      final medicationService = MedicationService(db);
      final medications = <Map<String, dynamic>>[];
      
      for (var row in results) {
        final medication = row.readTable(db.medications);
        
        // Get the full medication details including times
        final medDetails = await medicationService.loadMedicationsWithDetails();
        
        // Find this specific medication in the details
        final thisMedDetail = medDetails.firstWhere(
          (m) => m['id'] == medication.id,
          orElse: () => <String, dynamic>{},
        );
        
        if (thisMedDetail.isNotEmpty) {
          medications.add(thisMedDetail);
        }
      }

      setState(() {
        _medications = medications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Napaka pri nalaganju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMedication(int medicationId, String medicationName) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Izbris zdravila',
      message: 'Ali želite izbrisati zdravilo $medicationName za uporabnika ${widget.userName}?',
    );

    if (confirmed) {
      try {
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
          _loadUserMedications();
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

  Future<void> _deactivateUser() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Izbriši račun',
      message: 'Ali ste prepričani? Podatki bodo dostopni v zgodovini, račun pa izbrisan.',
    );

    if (confirmed) {
      try {
        // Cancel all alarms for this user's medications
        final allIntakes = await db.select(db.medicationIntakeLogs).get();
        for (var intake in allIntakes) {
          if (intake.userId == widget.userId) {
            try {
              await Alarm.stop(intake.id);
            } catch (e) {
              // Alarm might not exist, continue
            }
          }
        }
        
        // Deactivate the user
        await (db.update(db.users)..where((t) => t.id.equals(widget.userId)))
            .write(UsersCompanion(isActive: drift.Value(false)));

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Račun za ${widget.userName} je bil deaktiviran'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Go back to user list
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Symbols.person, color: colors.primary),
            const SizedBox(width: 8),
            Text(widget.userName),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zdravila Section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Zdravila',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_medications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Ni zdravil za tega uporabnika',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ..._medications.map((med) {
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
                                onRefresh: _loadUserMedications,
                              ),
                            ),
                          );
                        },
                        child: MedicationDetailsCard(
                          medName: med['name'] as String,
                          dosage: '$dosageCount ${getMedicationUnit(med['medType'] as MedicationType, dosageCount)}',
                          pillsRemaining: med['remaining'] as int,
                          frequency: med['frequency'] as String,
                          times: med['times'] as List<String>,
                          medType: med['medType'] as MedicationType,
                          onAddMedication: (quantity) async {
                            try {
                              final currentRemaining = med['remaining'] as int;
                              final newRemaining = (currentRemaining + quantity).clamp(0, 9999);

                              await (db.update(db.medications)
                                ..where((t) => t.id.equals(med['id'] as int)))
                                  .write(
                                MedicationsCompanion(
                                  dosagesRemaining: drift.Value(newRemaining.toDouble()),
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
                                    backgroundColor: quantity >= 0 ? Colors.green : Colors.orange,
                                  ),
                                );
                                _loadUserMedications();
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
                    }).toList(),
                  
                  const SizedBox(height: 32),
                  
                  // Uporabniški račun Section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Uporabniški račun',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Izbriši račun
                  GestureDetector(
                    onTap: _deactivateUser,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.error,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Symbols.delete,
                            color: colors.error,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Izbriši račun',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Deaktiviraj ta uporabniški račun',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Symbols.chevron_right,
                            color: colors.error,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
