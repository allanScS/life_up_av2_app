import 'package:flutter/material.dart';

import '../models/meta.dart';
import '../theme/app_theme.dart';
import 'sync_badge.dart';

class MetaProgressCard extends StatelessWidget {
  const MetaProgressCard({
    super.key,
    required this.meta,
    required this.onTap,
    this.compact = false,
  });

  final Meta meta;
  final VoidCallback onTap;
  final bool compact;

  Color get _accent {
    switch (meta.tipo) {
      case 'CALORICA':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF0284C7);
    }
  }

  IconData get _icon {
    switch (meta.tipo) {
      case 'CALORICA':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.water_drop_rounded;
    }
  }

  String get _unidade => meta.tipo == 'CALORICA' ? 'kcal' : 'ml';

  @override
  Widget build(BuildContext context) {
    final pct = meta.progresso.clamp(0, 100);
    final progresso = (pct / 100).toDouble();

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon, color: _accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta.tipo == 'CALORICA' ? 'Meta calórica' : 'Meta hídrica',
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SyncBadge(sincronizado: meta.sincronizado),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${meta.valorAtual.toStringAsFixed(0)} / '
                '${meta.valorObjetivo.toStringAsFixed(0)} $_unidade',
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 8,
                  backgroundColor: _accent.withValues(alpha: 0.12),
                  color: _accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
