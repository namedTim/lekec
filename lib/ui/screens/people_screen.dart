import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../../features/core/providers/database_provider.dart';
import '../widgets/user_card.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/empty_state_card.dart';
import 'user_medications_screen.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  bool _hasAutoNavigated = false;

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

      // Auto-open details only once (first load) when there's exactly one user
      if (users.length == 1 && !_hasAutoNavigated) {
        _hasAutoNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openUserDetails(users.first);
        });
      }
    }
  }

  Future<void> _openUserDetails(User user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserMedicationsScreen(
          userId: user.id,
          userName: user.name,
        ),
      ),
    );
    // Refresh in case user was deactivated, but _hasAutoNavigated stays true
    // so we never auto-open again when returning to this list
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Osebe',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isLoading && _users.isNotEmpty)
                          Text(
                            '${_users.length} ${_users.length == 1
                                ? 'oseba'
                                : _users.length < 5
                                ? 'osebe'
                                : 'oseb'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _users.isNotEmpty)
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
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                  ? Center(
                      child: EmptyStateCard(
                        icon: Symbols.group,
                        title: 'Ni dodanih uporabnikov',
                        subtitle:
                            'Dodajte uporabnike za upravljanje njihovih zdravil',
                        action: FilledButton.icon(
                          onPressed: _showAddUserDialog,
                          icon: const Icon(Symbols.person_add),
                          label: const Text('Dodaj uporabnika'),
                        ),
                      ),
                    )
                  : RefreshIndicator(
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
                            onTap: () => _openUserDetails(user),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
