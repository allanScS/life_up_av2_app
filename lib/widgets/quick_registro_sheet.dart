import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/habito.dart';
import '../theme/app_theme.dart';

class _Preset {
  const _Preset(this.valor, this.label, this.observacao);
  final double valor;
  final String label;
  final String observacao;
}

List<_Preset> _presetsPara(Habito habito) {
  switch (habito.tipo) {
    case 'hidratacao':
      return const [
        _Preset(200, '200 ml', 'água 200ml'),
        _Preset(250, '250 ml', 'água 250ml'),
        _Preset(500, '500 ml', 'água 500ml'),
      ];
    case 'alimentacao':
      return const [
        _Preset(150, '150 kcal', 'kcal 150'),
        _Preset(300, '300 kcal', 'kcal 300'),
        _Preset(500, '500 kcal', 'kcal 500'),
      ];
    case 'atividadeFisica':
      return const [
        _Preset(15, '15 min', 'atividade 15min'),
        _Preset(30, '30 min', 'atividade 30min'),
        _Preset(60, '60 min', 'atividade 60min'),
      ];
    case 'sono':
      return const [
        _Preset(6, '6 h', 'sono 6h'),
        _Preset(7, '7 h', 'sono 7h'),
        _Preset(8, '8 h', 'sono 8h'),
      ];
    case 'estudo':
      return const [
        _Preset(25, '25 min', 'estudo 25min'),
        _Preset(45, '45 min', 'estudo 45min'),
        _Preset(60, '60 min', 'estudo 60min'),
      ];
    default:
      return const [
        _Preset(1, '1', 'registro rápido'),
        _Preset(5, '5', 'registro rápido'),
        _Preset(10, '10', 'registro rápido'),
      ];
  }
}

/// Bottom sheet para registrar consumo rápido vinculado a um hábito.
Future<bool> showQuickRegistroSheet(
  BuildContext context, {
  required Habito habito,
}) async {
  final presets = _presetsPara(habito);
  var selecionado = presets[1 < presets.length ? 1 : 0];
  var salvando = false;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + MediaQuery.paddingOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Registrar — ${habito.nome}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Habito.rotuloTipo(habito.tipo),
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in presets)
                      ChoiceChip(
                        label: Text(p.label),
                        selected: selecionado.valor == p.valor &&
                            selecionado.label == p.label,
                        onSelected: salvando
                            ? null
                            : (_) => setModal(() => selecionado = p),
                        selectedColor: AppColors.primarySoft,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selecionado.valor == p.valor &&
                                  selecionado.label == p.label
                              ? AppColors.primary
                              : AppColors.inkMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: salvando
                      ? null
                      : () async {
                          setModal(() => salvando = true);
                          final scope = AppScope.of(ctx);
                          try {
                            await scope.repository.salvarRegistro(
                              usuarioId: scope.usuario!.id,
                              habitoId: habito.id,
                              valor: selecionado.valor,
                              observacao: selecionado.observacao,
                            );
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } catch (e) {
                            setModal(() => salvando = false);
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        },
                  child: Text(
                    salvando ? 'Salvando...' : 'Confirmar ${selecionado.label}',
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  return ok == true;
}
