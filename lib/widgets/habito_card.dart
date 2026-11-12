import 'package:flutter/material.dart';

import '../models/habito.dart';
import '../theme/app_theme.dart';
import 'sync_badge.dart';

class HabitoCard extends StatelessWidget {
  const HabitoCard({
    super.key,
    required this.habito,
    required this.onTap,
    this.onQuickRegister,
  });

  final Habito habito;
  final VoidCallback onTap;
  final VoidCallback? onQuickRegister;

  Color get _color {
    switch (habito.tipo) {
      case 'hidratacao':
        return const Color(0xFF0284C7);
      case 'alimentacao':
        return const Color(0xFFEA580C);
      case 'atividadeFisica':
        return const Color(0xFF059669);
      case 'sono':
        return const Color(0xFF7C3AED);
      case 'estudo':
        return const Color(0xFF0F766E);
      default:
        return AppColors.inkMuted;
    }
  }

  IconData get _icon {
    switch (habito.tipo) {
      case 'hidratacao':
        return Icons.water_drop_rounded;
      case 'alimentacao':
        return Icons.restaurant_rounded;
      case 'atividadeFisica':
        return Icons.directions_run_rounded;
      case 'sono':
        return Icons.bedtime_rounded;
      case 'estudo':
        return Icons.menu_book_rounded;
      default:
        return Icons.checklist_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habito.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Habito.rotuloTipo(habito.tipo),
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SyncBadge(sincronizado: habito.sincronizado),
              if (onQuickRegister != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Registrar',
                  onPressed: onQuickRegister,
                  icon: Icon(Icons.add_circle_rounded, color: _color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
