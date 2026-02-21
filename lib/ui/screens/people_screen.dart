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

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final db = ref.read(databaseProvider);
    final users = await (db.select(db.users)
          ..where((t) => t.isActive.equals(true)))
        .get();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddUserDialog() async {
    final result = await showDialog<AddUserResult>(
      context: context,
      builder: (context) => const AddUserDialog(),
    );

    if (result != null && result.name.isNotEmpty) {
      try {
        final db = ref.read(databaseProvider);
        await db.into(db.users).insert(
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Osebe',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _isLoading
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
                      top: 8,
                      left: 8,
                      right: 8,
                      bottom: 88,
                    ),
                    itemCount: _users.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _users.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: FilledButton.icon(
                            onPressed: _showAddUserDialog,
                            icon: const Icon(Symbols.person_add),
                            label: const Text('Dodaj uporabnika'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        );
                      }

                      final user = _users[index];
                      return UserCard(
                        userName: user.name,
                        userAge: user.age,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserMedicationsScreen(
                                userId: user.id,
                                userName: user.name,
                              ),
                            ),
                          );
                          // Refresh in case user was deactivated
                          _loadUsers();
                        },
                      );
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
