import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/meta.dart';
import '../widgets/empty_state.dart';
import '../widgets/meta_progress_card.dart';

class MetasListScreen extends StatefulWidget {
  const MetasListScreen({
    super.key,
    this.embeddedInShell = false,
  });

  final bool embeddedInShell;

  @override
  State<MetasListScreen> createState() => MetasListScreenState();
}

class MetasListScreenState extends State<MetasListScreen> {
  List<Meta> _itens = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => recarregar());
  }

  Future<void> recarregar() => _carregar();

  Future<void> _carregar() async {
    final scope = AppScope.of(context);
    final lista = await scope.repository.listarMetas(scope.usuario!.id);
    if (!mounted) return;
    setState(() {
      _itens = lista;
      _loading = false;
    });
  }

  Future<void> _abrirForm([String? id]) async {
    await Navigator.pushNamed(context, '/metas/form', arguments: id);
    if (!mounted) return;
    await recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = widget.embeddedInShell ? 24.0 : 88.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
        automaticallyImplyLeading: !widget.embeddedInShell,
        actions: widget.embeddedInShell
            ? null
            : [
                IconButton(
                  tooltip: 'Nova meta',
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
                  icon: Icons.flag_rounded,
                  title: 'Nenhuma meta ainda',
                  subtitle: widget.embeddedInShell
                      ? 'Use o + central para definir a primeira meta.'
                      : 'Defina um objetivo e acompanhe o progresso.',
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
                  itemCount: _itens.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final m = _itens[index];
                    return MetaProgressCard(
                      meta: m,
                      onTap: () => _abrirForm(m.id),
                    );
                  },
                ),
    );
  }
}
