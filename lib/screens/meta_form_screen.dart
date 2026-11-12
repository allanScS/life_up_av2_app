import 'package:flutter/material.dart';

import '../app_scope.dart';

class MetaFormScreen extends StatefulWidget {
  const MetaFormScreen({super.key, this.metaId});

  final String? metaId;

  @override
  State<MetaFormScreen> createState() => _MetaFormScreenState();
}

class _MetaFormScreenState extends State<MetaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController(text: '2000');
  final _atualCtrl = TextEditingController(text: '0');
  String _tipo = 'HIDRICA';
  List<String> _tiposDisponiveis = const ['HIDRICA', 'CALORICA'];
  bool _loading = false;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preencher());
  }

  Future<void> _preencher() async {
    final scope = AppScope.of(context);
    final lista = await scope.repository.listarMetas(scope.usuario!.id);

    if (widget.metaId != null) {
      final m = lista.where((e) => e.id == widget.metaId).firstOrNull;
      if (m != null && mounted) {
        setState(() {
          _tituloCtrl.text = m.titulo;
          _descCtrl.text = m.descricao ?? '';
          _objetivoCtrl.text = m.valorObjetivo.toString();
          _atualCtrl.text = m.valorAtual.toString();
          _tipo = m.tipo;
          _tiposDisponiveis = [m.tipo];
          _carregando = false;
        });
      } else if (mounted) {
        setState(() => _carregando = false);
      }
      return;
    }

    final usados = lista.map((m) => m.tipo).toSet();
    final disponiveis =
        ['HIDRICA', 'CALORICA'].where((t) => !usados.contains(t)).toList();
    if (!mounted) return;
    setState(() {
      _tiposDisponiveis = disponiveis;
      if (disponiveis.isNotEmpty) _tipo = disponiveis.first;
      _carregando = false;
    });
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _objetivoCtrl.dispose();
    _atualCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final scope = AppScope.of(context);
    try {
      await scope.repository.salvarMeta(
        usuarioId: scope.usuario!.id,
        id: widget.metaId,
        tipo: _tipo,
        titulo: _tituloCtrl.text.trim(),
        descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        valorObjetivo: double.parse(_objetivoCtrl.text.replaceAll(',', '.')),
        valorAtual: double.parse(_atualCtrl.text.replaceAll(',', '.')),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta salva')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _rotuloTipo(String tipo) =>
      tipo == 'CALORICA' ? 'Calórica (kcal)' : 'Hídrica (ml)';

  @override
  Widget build(BuildContext context) {
    final criando = widget.metaId == null;
    final semTipoLivre = criando && _tiposDisponiveis.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(criando ? 'Nova meta' : 'Editar meta'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (semTipoLivre)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Você já tem meta hídrica e calórica. '
                          'Edite uma existente na lista.',
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _tipo,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _tiposDisponiveis
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(_rotuloTipo(t)),
                              ),
                            )
                            .toList(),
                        onChanged: criando
                            ? (v) => setState(() => _tipo = v ?? _tipo)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tituloCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _objetivoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor objetivo',
                          prefixIcon: Icon(Icons.track_changes_outlined),
                        ),
                        validator: (v) {
                          final n =
                              double.tryParse((v ?? '').replaceAll(',', '.'));
                          if (n == null || n <= 0) return 'Deve ser > 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _atualCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor atual',
                          prefixIcon: Icon(Icons.speed_outlined),
                        ),
                        validator: (v) {
                          final n =
                              double.tryParse((v ?? '').replaceAll(',', '.'));
                          if (n == null || n < 0) return 'Inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : _salvar,
                        child: Text(_loading ? 'Salvando...' : 'Salvar'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
