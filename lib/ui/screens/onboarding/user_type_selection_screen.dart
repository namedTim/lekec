import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../database/tables/onboarding_settings.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  final Function(UserType) onNext;

  const UserTypeSelectionScreen({super.key, required this.onNext});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  UserType? _selectedType = UserType.personal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nastavitev'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              Text(
                'Kako boste uporabljali Lekec?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'To nam pomaga prilagoditi aplikacijo vašim potrebam',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Personal Use Option
              _UserTypeCard(
                icon: Symbols.person,
                title: 'Osebna uporaba',
                description: 'Sledim svojim zdravilom',
                isSelected: _selectedType == UserType.personal,
                onTap: () => setState(() => _selectedType = UserType.personal),
                colors: colors,
              ),

              const SizedBox(height: 16),

              // Family Use Option
              _UserTypeCard(
                icon: Symbols.family_restroom,
                title: 'Družinska uporaba',
                description: 'Upravljam zdravila za družinske člane',
                isSelected: _selectedType == UserType.family,
                onTap: () => setState(() => _selectedType = UserType.family),
                colors: colors,
              ),

              const SizedBox(height: 16),

              // Caregiver Option
              _UserTypeCard(
                icon: Symbols.medical_services,
                title: 'Negovalec / Zdravstveni delavec',
                description:
                    'Pomagam starejšim ali več osebam pri jemanju zdravil',
                isSelected: _selectedType == UserType.caregiver,
                onTap: () => setState(() => _selectedType = UserType.caregiver),
                colors: colors,
              ),

              const Spacer(),

              // Continue Button
              FilledButton(
                onPressed: _selectedType != null
                    ? () => widget.onNext(_selectedType!)
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Naprej',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;

  const _UserTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outline.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: colors.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withOpacity(0.15)
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Symbols.check_circle, color: colors.primary, fill: 1),
          ],
        ),
      ),
    );
  }
}
