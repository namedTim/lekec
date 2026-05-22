import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../../features/core/providers/database_provider.dart';
import '../../main.dart' show homePageKey, medsPageKey, userDetailsPageKey;
import '../views/settings_view.dart';
import '../widgets/user_card.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/empty_state_card.dart';
import 'user_medications_screen.dart';

enum PeopleTab { people, settings }

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  PeopleTab _selectedTab = PeopleTab.people;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final db = ref.read(databaseProvider);
    final users = await (db.select(
      db.users,
    )..where((t) => t.isActive.equals(true))).get();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _openUserDetails(User user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserMedicationsScreen(
          key: userDetailsPageKey,
          userId: user.id,
          userName: user.name,
        ),
      ),
    );
    // Refresh in case the user was deactivated while we were on their details.
    _loadUsers();
  }

  Future<void> _showAddUserDialog() async {
    final result = await showDialog<AddUserResult>(
      context: context,
      builder: (context) => const AddUserDialog(),
    );

    if (result != null && result.name.isNotEmpty) {
      try {
        final db = ref.read(databaseProvider);
        await db
            .into(db.users)
            .insert(
              UsersCompanion.insert(
                name: result.name,
                createdAt: drift.Value(DateTime.now()),
                age: drift.Value(result.age),
                gender: drift.Value(result.gender),
              ),
            );

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uporabnik ${result.name} dodan'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
          // Active-user set changed: refresh the other tabs so their cards
          // pick up the new owner labels without an app restart.
          homePageKey.currentState?.loadUserData();
          homePageKey.currentState?.loadTodaysIntakes(autoScroll: false);
          medsPageKey.currentState?.refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab toggle — matches the Zdravila / Termini style on the meds screen.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<PeopleTab>(
                  segments: const [
                    ButtonSegment<PeopleTab>(
                      value: PeopleTab.people,
                      label: Text('Osebe'),
                      icon: Icon(Symbols.group),
                    ),
                    ButtonSegment<PeopleTab>(
                      value: PeopleTab.settings,
                      label: Text('Nastavitve'),
                      icon: Icon(Symbols.settings),
                    ),
                  ],
                  selected: {_selectedTab},
                  onSelectionChanged: (Set<PeopleTab> newSelection) {
                    setState(() {
                      _selectedTab = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: const VisualDensity(horizontal: -2),
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(fontSize: 13),
                    ),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedTab == PeopleTab.settings) {
      return const SettingsView();
    }
    return _buildPeopleList();
  }

  Widget _buildPeopleList() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_users.isEmpty) {
      return Center(
        child: EmptyStateCard(
          icon: Symbols.group,
          title: 'Ni dodanih uporabnikov',
          subtitle: 'Dodajte uporabnike za upravljanje njihovih zdravil',
          action: FilledButton.icon(
            onPressed: _showAddUserDialog,
            icon: const Icon(Symbols.person_add),
            label: const Text('Dodaj uporabnika'),
          ),
        ),
      );
    }

    // With a single user we auto-open their details (see _loadUsers) and the
    // list itself is mostly dead space. Show a compact "edit user" affordance
    // and a quiet hint instead of the usual list.
    if (_users.length == 1) {
      final user = _users.first;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserCard(
              userName: user.name,
              userAge: user.age,
              userId: user.id,
              onTap: () => _openUserDetails(user),
            ),
            const SizedBox(height: 12),
            Text(
              'Dotakni se kartice za pregled podatkov o osebi.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showAddUserDialog,
              icon: const Icon(Symbols.person_add, size: 18),
              label: const Text('Dodaj osebo'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${_users.length} ${_users.length == 1
                      ? 'oseba'
                      : _users.length < 5
                      ? 'osebe'
                      : 'oseb'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Symbols.person_add, size: 18),
                label: const Text('Dodaj'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: 4,
                left: 12,
                right: 12,
                bottom: 88,
              ),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return UserCard(
                  userName: user.name,
                  userAge: user.age,
                  userId: user.id,
                  onTap: () => _openUserDetails(user),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
