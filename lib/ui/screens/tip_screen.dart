import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/tip_service.dart';
import '../widgets/tip_celebration_overlay.dart';

/// "Buy me a coffee" screen that lets the user pick a one-shot tip tier
/// from the Play Store / App Store.
class TipScreen extends StatefulWidget {
  const TipScreen({super.key});

  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  final TipService _service = TipService.instance;

  bool _loading = true;
  String? _error;
  String? _purchaseInProgressId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _service.initialize(
      onSuccess: _handleSuccess,
      onError: _handleError,
      onPending: _handlePending,
      onCanceled: _handleCanceled,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = _service.initError;
    });
  }

  void _handleSuccess(ProductDetails p) {
    if (!mounted) return;
    setState(() => _purchaseInProgressId = null);
    ScaffoldMessenger.of(context).clearSnackBars();
    TipCelebrationOverlay.show(
      context,
      title: p.title.isNotEmpty
          ? p.title.replaceAll(RegExp(r'\s*\(.*\)$'), '')
          : 'Podpora razvoju',
      icon: _iconForTier(p.id),
    );
  }

  IconData _iconForTier(String id) {
    switch (id) {
      case 'tip_tier_1':
        return Symbols.coffee;
      case 'tip_tier_2':
        return Symbols.bakery_dining;
      case 'tip_tier_3':
        return Symbols.lunch_dining;
      case 'tip_tier_4':
        return Symbols.restaurant;
      default:
        return Symbols.favorite;
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() => _purchaseInProgressId = null);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Napaka: $message'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _handlePending() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plačilo v obdelavi…')),
    );
  }

  void _handleCanceled() {
    if (!mounted) return;
    setState(() => _purchaseInProgressId = null);
  }

  Future<void> _buy(ProductDetails p) async {
    setState(() => _purchaseInProgressId = p.id);
    final ok = await _service.buy(p);
    if (!ok && mounted) {
      setState(() => _purchaseInProgressId = null);
      _handleError('Plačila ni bilo mogoče zagnati.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Podpri razvoj'),
        actions: [
          const IconButton(
            tooltip: 'Hvala za podporo',
            icon: Icon(Symbols.celebration),
            onPressed: null,
          ),
        ],
      ),
      body: _buildBody(theme, colors),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError(theme, colors, _error!);
    }
    if (_service.products.isEmpty) {
      return _buildError(
        theme,
        colors,
        'Trenutno ni razpoložljivih možnosti. Poskusite kasneje.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Symbols.favorite, color: colors.primary, size: 36, fill: 1),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Lekec je brezplačen. Če vam pomaga, lahko razvoj '
                  'podprete z neobveznim prispevkom.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final p in _service.products) ...[
          _TipCard(
            product: p,
            isLoading: _purchaseInProgressId == p.id,
            disabled: _purchaseInProgressId != null && _purchaseInProgressId != p.id,
            onTap: () => _buy(p),
            colors: colors,
            theme: theme,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildError(ThemeData theme, ColorScheme colors, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.sentiment_dissatisfied,
                size: 64, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.product,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  final ProductDetails product;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;
  final ColorScheme colors;
  final ThemeData theme;

  IconData _iconFor(String id) {
    // Cosmetic only — picks a fun icon tier.
    switch (id) {
      case 'tip_tier_1':
        return Symbols.coffee;
      case 'tip_tier_2':
        return Symbols.bakery_dining;
      case 'tip_tier_3':
        return Symbols.lunch_dining;
      case 'tip_tier_4':
        return Symbols.restaurant;
      default:
        return Symbols.favorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconFor(product.id),
                  color: colors.primary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title.isNotEmpty
                        ? product.title.replaceAll(RegExp(r'\s*\(.*\)$'), '')
                        : product.id,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            isLoading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.price,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
