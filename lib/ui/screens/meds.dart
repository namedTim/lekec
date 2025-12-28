import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../views/settings_view.dart';

enum MedsTab { medications, users, settings }

class MedsScreen extends StatefulWidget {
  const MedsScreen({super.key});

  @override
  State<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends State<MedsScreen> {
  MedsTab _selectedTab = MedsTab.medications;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
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
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case MedsTab.medications:
        return const Center(child: Text('Seznam zdravil'));
      case MedsTab.users:
        return const Center(child: Text('Seznam uporabnikov'));
      case MedsTab.settings:
        return const SettingsView();
    }
  }
}
