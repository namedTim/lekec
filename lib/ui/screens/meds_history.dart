import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lekec/database/drift_database.dart';
import 'package:lekec/features/core/providers/database_provider.dart';
import 'package:lekec/helpers/medication_unit_helper.dart';
import 'package:lekec/ui/components/history_time_slot.dart';
import 'package:lekec/data/services/history_service.dart';

enum HistoryFilter {
  all,
  taken,
  missed,
}

class MedsHistoryScreen extends ConsumerStatefulWidget {
  const MedsHistoryScreen({super.key});

  @override
  ConsumerState<MedsHistoryScreen> createState() => _MedsHistoryScreenState();
}

class _MedsHistoryScreenState extends ConsumerState<MedsHistoryScreen> {
  HistoryFilter _currentFilter = HistoryFilter.all;
  final List<Map<String, dynamic>> _allEntries = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 50;
  final ScrollController _scrollController = ScrollController();
  late HistoryService _historyService;

  @override
  void initState() {
    super.initState();
    _historyService = HistoryService(ref.read(databaseProvider));
    _loadMoreHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoading && _hasMore) {
        _loadMoreHistory();
      }
    }
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _allEntries.clear();
      _offset = 0;
      _hasMore = true;
    });
    await _loadMoreHistory();
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    final newEntries = await _historyService.loadHistory(
      limit: _limit,
      offset: _offset,
      onlyTaken: _currentFilter == HistoryFilter.taken ? true : null,
      onlyMissed: _currentFilter == HistoryFilter.missed ? true : null,
    );

    setState(() {
      _allEntries.addAll(newEntries);
      _offset += _limit;
      _hasMore = newEntries.length == _limit;
      _isLoading = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupEntriesByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final entry in _allEntries) {
      final date = entry['date'] as DateTime;
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(entry);
    }

    return grouped;
  }

  String _getDayName(DateTime date) {
    const days = [
      'Ponedeljek',
      'Torek',
      'Sreda',
      'Četrtek',
      'Petek',
      'Sobota',
      'Nedelja',
    ];
    return days[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    final dayName = _getDayName(date);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$dayName, $day. $month. $year';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final groupedHistory = _groupEntriesByDate();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with dropdown
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Zgodovina',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<HistoryFilter>(
                          value: _currentFilter,
                          isExpanded: true,
                          dropdownColor: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          items: const [
                            DropdownMenuItem(
                              value: HistoryFilter.all,
                              child: Text('Vsa zdravila'),
                            ),
                            DropdownMenuItem(
                              value: HistoryFilter.taken,
                              child: Text('Vzeta zdravila'),
                            ),
                            DropdownMenuItem(
                              value: HistoryFilter.missed,
                              child: Text('Izpuščena zdravila'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _currentFilter = value);
                              _refreshHistory();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // History list
            Expanded(
              child: _allEntries.isEmpty && _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allEntries.isEmpty
                      ? Center(
                          child: Text(
                            'Ni zgodovine',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 80,
                          ),
                          itemCount: groupedHistory.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show loading indicator at the end
                            if (index == groupedHistory.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final dateKey = groupedHistory.keys.elementAt(index);
                            final entries = groupedHistory[dateKey]!;
                            final date = entries.first['date'] as DateTime;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date header
                                Padding(
                                  padding: const EdgeInsets.only(top: 16, bottom: 12),
                                  child: HistoryTimeSlot(
                                    text: _formatDate(date),
                                    fontSize: 14,
                                  ),
                                ),

                                // Medications for this day
                                ...entries.map((entry) {
                                  final intake = entry['intake'] as MedicationIntakeLog;
                                  final medication = entry['medication'] as Medication;
                                  final plan = entry['plan'] as MedicationPlan?;
                                  final dosageAmount = plan?.dosageAmount ?? 1.0;
                                  final dosageCount = dosageAmount.toInt();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        // Medication info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                medication.name,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$dosageCount ${getMedicationUnit(medication.medType, dosageCount)}',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: colors.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        // Time and status
                                        HistoryTimeSlot(
                                          text: _formatTime(intake.scheduledTime),
                                          backgroundColor: intake.wasTaken 
                                              ? Colors.green.shade100 
                                              : Colors.red.shade100,
                                          textColor: intake.wasTaken 
                                              ? Colors.green.shade700 
                                              : Colors.red.shade700,
                                          fontSize: 13,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
