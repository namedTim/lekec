import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../database/tables/medications.dart';

({IconData icon, Color color}) getMedicationStyle(MedicationType type) {
  switch (type) {
    case MedicationType.pills:
      return (icon: Symbols.pill, color: const Color(0xFF6366F1));
    case MedicationType.capsules:
      return (icon: Symbols.medication, color: const Color(0xFF8B5CF6));
    case MedicationType.drops:
      return (icon: Symbols.water_drop, color: const Color(0xFF06B6D4));
    case MedicationType.milliliters:
      return (icon: Symbols.medication_liquid, color: const Color(0xFF0EA5E9));
    case MedicationType.sprays:
      return (icon: Symbols.airwave, color: const Color(0xFF14B8A6));
    case MedicationType.injections:
      return (icon: Symbols.vaccines, color: const Color(0xFFEC4899));
    case MedicationType.patches:
      return (icon: Symbols.healing, color: const Color(0xFFF59E0B));
    case MedicationType.puffs:
      return (icon: Symbols.pulmonology, color: const Color(0xFF38BDF8));
    case MedicationType.applications:
      return (icon: Symbols.healing, color: const Color(0xFFF97316));
    case MedicationType.ampules:
      return (icon: Symbols.science, color: const Color(0xFFA855F7));
    case MedicationType.grams:
    case MedicationType.milligrams:
    case MedicationType.micrograms:
      return (icon: Symbols.scale, color: const Color(0xFF64748B));
    case MedicationType.tablespoons:
      return (icon: Symbols.restaurant, color: const Color(0xFFEAB308));
    case MedicationType.portions:
      return (icon: Symbols.restaurant_menu, color: const Color(0xFFD97706));
    case MedicationType.pieces:
      return (icon: Symbols.category, color: const Color(0xFF10B981));
    case MedicationType.units:
      return (icon: Symbols.inventory_2, color: const Color(0xFF22C55E));
  }
}
