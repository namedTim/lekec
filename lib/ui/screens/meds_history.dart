import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../database/drift_database.dart';
import '../../features/core/providers/database_provider.dart';
import '../../helpers/medication_unit_helper.dart';
import '../components/history_time_slot.dart';
import '../widgets/empty_state_card.dart';
import '../../data/services/history_service.dart';
import '../../data/services/mood_service.dart';

enum HistoryFilter { all, taken, missed }

enum EntryType { medications, mood, appointments }

class MedsHistoryScreen extends ConsumerStatefulWidget {
  const MedsHistoryScreen({super.key});

  @override
  ConsumerState<MedsHistoryScreen> createState() => _MedsHistoryScreenState();
}

class _MedsHistoryScreenState extends ConsumerState<MedsHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  HistoryFilter _currentFilter = HistoryFilter.all;
  final Set<EntryType> _selectedEntryTypes = {
    EntryType.medications,
    EntryType.mood,
    EntryType.appointments,
  };
  int? _selectedUserId; // null = all users
  List<User> _users = [];

  final List<Map<String, dynamic>> _allEntries = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _medOffset = 0;
  int _moodOffset = 0;
  int _appointmentOffset = 0;
  final int _limit = 50;
  final ScrollController _scrollController = ScrollController();
  late HistoryService _historyService;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _historyService = HistoryService(ref.read(databaseProvider));
    _scrollController.addListener(_onScroll);
    _loadUsers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allEntries.isEmpty || !_isLoading) {
      _refreshHistory();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await _historyService.getActiveUsers();
    if (mounted) setState(() => _users = users);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoading && _hasMore) {
        _loadMoreHistory();
      }
    }
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _allEntries.clear();
      _medOffset = 0;
      _moodOffset = 0;
      _appointmentOffset = 0;
      _hasMore = true;
    });
    await _loadMoreHistory();
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    final List<Map<String, dynamic>> newEntries = [];
    bool medHasMore = false;
    bool moodHasMore = false;
    bool appointmentHasMore = false;

    // Load medication entries
    if (_selectedEntryTypes.contains(EntryType.medications)) {
      final medEntries = await _historyService.loadHistory(
        limit: _limit,
        offset: _medOffset,
        onlyTaken: _currentFilter == HistoryFilter.taken ? true : null,
        onlyMissed: _currentFilter == HistoryFilter.missed ? true : null,
        userId: _selectedUserId,
      );
      newEntries.addAll(medEntries);
      _medOffset += _limit;
      medHasMore = medEntries.length == _limit;
    }

    // Load mood entries
    if (_selectedEntryTypes.contains(EntryType.mood)) {
      final moodEntries = await _historyService.loadMoodHistory(
        limit: _limit,
        offset: _moodOffset,
        userId: _selectedUserId,
      );
      newEntries.addAll(moodEntries);
      _moodOffset += _limit;
      moodHasMore = moodEntries.length == _limit;
    }

    // Load appointment entries
    if (_selectedEntryTypes.contains(EntryType.appointments)) {
      final apptEntries = await _historyService.loadAppointmentHistory(
        limit: _limit,
        offset: _appointmentOffset,
        userId: _selectedUserId,
      );
      newEntries.addAll(apptEntries);
      _appointmentOffset += _limit;
      appointmentHasMore = apptEntries.length == _limit;
    }

    // Sort all entries by time descending
    newEntries.sort((a, b) {
      final timeA = a['sortTime'] as DateTime;
      final timeB = b['sortTime'] as DateTime;
      return timeB.compareTo(timeA);
    });

    setState(() {
      _allEntries.addAll(newEntries);
      _hasMore = medHasMore || moodHasMore || appointmentHasMore;
      _isLoading = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupEntriesByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final entry in _allEntries) {
      final date = entry['date'] as DateTime;
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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

  String? _getUserName(int userId) {
    final user = _users.where((u) => u.id == userId).firstOrNull;
    return user?.name;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final groupedHistory = _groupEntriesByDate();
    final showUserNames = _selectedUserId == null && _users.length > 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Zgodovina',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Filters row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // User filter
                  Expanded(
                    child: _buildDropdown<int?>(
                      value: _selectedUserId,
                      icon: Symbols.person,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Vsi uporabniki'),
                        ),
                        ..._users.map(
                          (u) => DropdownMenuItem<int?>(
                            value: u.id,
                            child: Text(u.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedUserId = value);
                        _refreshHistory();
                      },
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Med status filter
                  Expanded(
                    child: _buildDropdown<HistoryFilter>(
                      value: _currentFilter,
                      icon: Symbols.filter_list,
                      items: const [
                        DropdownMenuItem(
                          value: HistoryFilter.all,
                          child: Text('Vsi vnosi'),
                        ),
                        DropdownMenuItem(
                          value: HistoryFilter.taken,
                          child: Text('Vzeta'),
                        ),
                        DropdownMenuItem(
                          value: HistoryFilter.missed,
                          child: Text('Izpuščena'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currentFilter = value);
                          _refreshHistory();
                        }
                      },
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Entry type toggle chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Zdravila',
                    icon: Symbols.pill,
                    selected: _selectedEntryTypes.contains(
                      EntryType.medications,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedEntryTypes.add(EntryType.medications);
                        } else if (_selectedEntryTypes.length > 1) {
                          _selectedEntryTypes.remove(EntryType.medications);
                        }
                      });
                      _refreshHistory();
                    },
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Razpoloženje',
                    icon: Symbols.mood,
                    selected: _selectedEntryTypes.contains(EntryType.mood),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedEntryTypes.add(EntryType.mood);
                        } else if (_selectedEntryTypes.length > 1) {
                          _selectedEntryTypes.remove(EntryType.mood);
                        }
                      });
                      _refreshHistory();
                    },
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Termini',
                    icon: Symbols.calendar_month,
                    selected: _selectedEntryTypes.contains(
                      EntryType.appointments,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedEntryTypes.add(EntryType.appointments);
                        } else if (_selectedEntryTypes.length > 1) {
                          _selectedEntryTypes.remove(EntryType.appointments);
                        }
                      });
                      _refreshHistory();
                    },
                    colors: colors,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // History list
            Expanded(
              child: _allEntries.isEmpty && _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allEntries.isEmpty
                  ? Center(
                      child: EmptyStateCard(
                        icon: Symbols.history,
                        title: 'Ni zgodovine',
                        subtitle: 'Tapnite za dodajanje zdravil',
                        onTap: () => context.push('/add-medication'),
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
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 12,
                              ),
                              child: HistoryTimeSlot(
                                text: _formatDate(date),
                                fontSize: 14,
                              ),
                            ),
                            ...entries.map((entry) {
                              if (entry['type'] == 'mood') {
                                return _buildMoodCard(
                                  entry,
                                  theme,
                                  colors,
                                  showUserNames,
                                );
                              } else if (entry['type'] == 'appointment') {
                                return _buildAppointmentCard(
                                  entry,
                                  theme,
                                  colors,
                                  showUserNames,
                                );
                              } else {
                                return _buildMedicationCard(
                                  entry,
                                  theme,
                                  colors,
                                  showUserNames,
                                );
                              }
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

  Widget _buildDropdown<T>({
    required T value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Symbols.arrow_drop_down, color: colors.onSurfaceVariant),
          dropdownColor: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(fontSize: 13, color: colors.onSurface),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
    required ColorScheme colors,
  }) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildMedicationCard(
    Map<String, dynamic> entry,
    ThemeData theme,
    ColorScheme colors,
    bool showUserNames,
  ) {
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
                if (showUserNames) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Symbols.person,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getUserName(intake.userId) ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
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
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> entry,
    ThemeData theme,
    ColorScheme colors,
    bool showUserNames,
  ) {
    final appt = entry['appointment'] as Appointment;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Symbols.calendar_today,
              color: colors.onSecondaryContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (appt.note != null && appt.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    appt.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (showUserNames) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Symbols.person,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getUserName(appt.userId) ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          HistoryTimeSlot(
            text: _formatTime(appt.appointmentTime),
            backgroundColor: colors.secondaryContainer,
            textColor: colors.onSecondaryContainer,
            fontSize: 13,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard(
    Map<String, dynamic> entry,
    ThemeData theme,
    ColorScheme colors,
    bool showUserNames,
  ) {
    final mood = entry['mood'] as MoodEntry;
    final emoji = MoodService.moodEmojis[mood.moodLevel] ?? '😐';
    final label = MoodService.moodLabels[mood.moodLevel] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (mood.note != null && mood.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    mood.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (showUserNames) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Symbols.person,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getUserName(mood.userId) ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          HistoryTimeSlot(
            text: _formatTime(mood.createdAt),
            backgroundColor: colors.primaryContainer,
            textColor: colors.onPrimaryContainer,
            fontSize: 13,
          ),
        ],
      ),
    );
  }
}
