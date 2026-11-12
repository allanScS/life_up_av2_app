import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/habito.dart';
import '../theme/app_theme.dart';
import '../widgets/sync_badge.dart';

class HabitoDetailScreen extends StatefulWidget {
  const HabitoDetailScreen({super.key, required this.habitoId});

  final String habitoId;

  @override
  State<HabitoDetailScreen> createState() => _HabitoDetailScreenState();
}

class _HabitoDetailScreenState extends State<HabitoDetailScreen> {
  Habito? _habito;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final scope = AppScope.of(context);
    final lista = await scope.repository.listarHabitos(scope.usuario!.id);
    if (!mounted) return;
    setState(() {
      _habito = lista.where((e) => e.id == widget.habitoId).firstOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = _habito;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do hábito'),
        actions: [
          if (h != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => Navigator.pushNamed(
                context,
                '/habitos/form',
                arguments: h.id,
              ).then((_) => _carregar()),
            ),
        ],
      ),
      body: h == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.checklist_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                h.nome,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SyncBadge(sincronizado: h.sincronizado),
                          ],
                        ),
                        if (h.descricao != null && h.descricao!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            h.descricao!,
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: const Text('Tipo'),
                        trailing: Text(Habito.rotuloTipo(h.tipo)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.toggle_on_outlined),
                        title: const Text('Ativo'),
                        trailing: Text(h.ativo ? 'sim' : 'não'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Criado em'),
                        subtitle: Text('${h.dataCriacao}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
