import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum PeriodFilter { hoje, semana, todos }

class PeriodFilterChips extends StatelessWidget {
  const PeriodFilterChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PeriodFilter value;
  final ValueChanged<PeriodFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in PeriodFilter.values) ...[
          if (item != PeriodFilter.values.first) const SizedBox(width: 8),
          Expanded(
            child: _Chip(
              label: switch (item) {
                PeriodFilter.hoje => 'Hoje',
                PeriodFilter.semana => 'Semana',
                PeriodFilter.todos => 'Todos',
              },
              selected: value == item,
              onTap: () => onChanged(item),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.white : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

bool periodoContem(PeriodFilter filter, DateTime data) {
  final agora = DateTime.now();
  final dia = DateTime(data.year, data.month, data.day);
  final hoje = DateTime(agora.year, agora.month, agora.day);

  switch (filter) {
    case PeriodFilter.hoje:
      return dia == hoje;
    case PeriodFilter.semana:
      final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));
      final fimSemana = inicioSemana.add(const Duration(days: 7));
      return !dia.isBefore(inicioSemana) && dia.isBefore(fimSemana);
    case PeriodFilter.todos:
      return true;
  }
}
