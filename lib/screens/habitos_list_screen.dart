import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/habito.dart';
import '../models/registro.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/habito_card.dart';
import '../widgets/period_filter_chips.dart';
import '../widgets/quick_registro_sheet.dart';

class HabitosListScreen extends StatefulWidget {
  const HabitosListScreen({
    super.key,
    this.embeddedInShell = false,
  });

  final bool embeddedInShell;

  @override
  State<HabitosListScreen> createState() => HabitosListScreenState();
}

class HabitosListScreenState extends State<HabitosListScreen> {
  List<Habito> _itens = [];
  List<Registro> _registros = [];
  PeriodFilter _filtro = PeriodFilter.todos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => recarregar());
  }

  Future<void> recarregar() => _carregar();

  Future<void> _carregar() async {
    final scope = AppScope.of(context);
    final user = scope.usuario!;
    final lista = await scope.repository.listarHabitos(user.id);
    final registros = await scope.repository.listarRegistros(user.id);
    if (!mounted) return;
    setState(() {
      _itens = lista;
      _registros = registros;
      _loading = false;
    });
  }

  List<Habito> get _filtrados {
    if (_filtro == PeriodFilter.todos) return _itens;
    final idsAtivos = _registros
        .where((r) => periodoContem(_filtro, r.dataRegistro))
        .map((r) => r.habitoId)
        .whereType<String>()
        .toSet();
    return _itens.where((h) => idsAtivos.contains(h.id)).toList();
  }

  Future<void> _registroRapido(Habito h) async {
    final ok = await showQuickRegistroSheet(context, habito: h);
    if (ok && mounted) {
      await recarregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro rápido em "${h.nome}"')),
      );
    }
  }

  Future<void> _remover(Habito h) async {
    final scope = AppScope.of(context);
    await scope.repository.removerHabito(scope.usuario!.id, h.id);
    await _carregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hábito "${h.nome}" removido')),
    );
  }

  Future<void> _abrirForm([String? id]) async {
    await Navigator.pushNamed(context, '/habitos/form', arguments: id);
    if (!mounted) return;
    await recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = widget.embeddedInShell ? 24.0 : 88.0;
    final filtrados = _filtrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hábitos'),
        automaticallyImplyLeading: !widget.embeddedInShell,
        actions: widget.embeddedInShell
            ? null
            : [
                IconButton(
                  tooltip: 'Novo hábito',
                  onPressed: () => _abrirForm(),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
      ),
      floatingActionButton: widget.embeddedInShell
          ? null
          : FloatingActionButton(
              onPressed: () => _abrirForm(),
              child: const Icon(Icons.add_rounded),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _itens.isEmpty
              ? EmptyState(
                  icon: Icons.checklist_rounded,
                  title: 'Nenhum hábito ainda',
                  subtitle: widget.embeddedInShell
                      ? 'Use o + central para criar o primeiro.'
                      : 'Toque em + para criar o primeiro.',
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: PeriodFilterChips(
                        value: _filtro,
                        onChanged: (v) => setState(() => _filtro = v),
                      ),
                    ),
                    Expanded(
                      child: filtrados.isEmpty
                          ? EmptyState(
                              icon: Icons.filter_alt_outlined,
                              title: 'Nenhum hábito neste período',
                              subtitle: _filtro == PeriodFilter.hoje
                                  ? 'Registre um consumo hoje pelo botão + do card.'
                                  : 'Troque para Todos ou registre na semana.',
                            )
                          : ListView.separated(
                              padding:
                                  EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
                              itemCount: filtrados.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final h = filtrados[index];
                                return Dismissible(
                                  key: ValueKey(h.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.delete_rounded,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (_) => _remover(h),
                                  child: HabitoCard(
                                    habito: h,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/habitos/detalhe',
                                      arguments: h.id,
                                    ).then((_) => recarregar()),
                                    onQuickRegister: () =>
                                        _registroRapido(h),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
