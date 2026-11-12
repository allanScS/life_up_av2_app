import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_scope.dart';
import '../models/registro.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/period_filter_chips.dart';
import '../widgets/sync_badge.dart';

class RegistrosListScreen extends StatefulWidget {
  const RegistrosListScreen({super.key});

  @override
  State<RegistrosListScreen> createState() => _RegistrosListScreenState();
}

class _RegistrosListScreenState extends State<RegistrosListScreen> {
  List<Registro> _itens = [];
  bool _loading = true;
  PeriodFilter _filtro = PeriodFilter.hoje;
  final _fmt = DateFormat('dd/MM HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final scope = AppScope.of(context);
    final lista = await scope.repository.listarRegistros(scope.usuario!.id);
    if (!mounted) return;
    setState(() {
      _itens = lista;
      _loading = false;
    });
  }

  List<Registro> get _filtrados =>
      _itens.where((r) => periodoContem(_filtro, r.dataRegistro)).toList();

  Future<void> _remover(Registro r) async {
    final scope = AppScope.of(context);
    await scope.repository.removerRegistro(scope.usuario!.id, r.id);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;

    return Scaffold(
      appBar: AppBar(title: const Text('Registros')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/registros/form')
            .then((_) => _carregar()),
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                  child: _itens.isEmpty
                      ? const EmptyState(
                          icon: Icons.water_drop_rounded,
                          title: 'Nenhum registro ainda',
                          subtitle: 'Lance um valor para começar o histórico.',
                        )
                      : filtrados.isEmpty
                          ? EmptyState(
                              icon: Icons.filter_alt_outlined,
                              title: 'Nada neste período',
                              subtitle: _filtro == PeriodFilter.hoje
                                  ? 'Sem lançamentos hoje. Troque o filtro ou registre pelo FAB.'
                                  : 'Sem lançamentos na semana. Veja em Todos.',
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 88),
                              itemCount: filtrados.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final r = filtrados[index];
                                return Dismissible(
                                  key: ValueKey(r.id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) => _remover(r),
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
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    child: ListTile(
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.water_drop_rounded,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                      title: Text(
                                        r.valor.toStringAsFixed(0),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${r.observacao ?? 'sem observação'} • ${_fmt.format(r.dataRegistro)}',
                                      ),
                                      trailing: SyncBadge(
                                        sincronizado: r.sincronizado,
                                      ),
                                    ),
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
