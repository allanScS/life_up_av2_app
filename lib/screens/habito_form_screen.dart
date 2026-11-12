import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/habito.dart';

class HabitoFormScreen extends StatefulWidget {
  const HabitoFormScreen({super.key, this.habitoId});

  final String? habitoId;

  @override
  State<HabitoFormScreen> createState() => _HabitoFormScreenState();
}

class _HabitoFormScreenState extends State<HabitoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _tipo = 'hidratacao';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preencher());
  }

  Future<void> _preencher() async {
    if (widget.habitoId == null) return;
    final scope = AppScope.of(context);
    final lista = await scope.repository.listarHabitos(scope.usuario!.id);
    final h = lista.where((e) => e.id == widget.habitoId).firstOrNull;
    if (h == null || !mounted) return;
    setState(() {
      _nomeCtrl.text = h.nome;
      _descCtrl.text = h.descricao ?? '';
      _tipo = h.tipo;
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final scope = AppScope.of(context);
    try {
      await scope.repository.salvarHabito(
        usuarioId: scope.usuario!.id,
        id: widget.habitoId,
        nome: _nomeCtrl.text.trim(),
        descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        tipo: _tipo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hábito salvo localmente')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habitoId == null ? 'Novo hábito' : 'Editar hábito'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: Habito.tipos
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(Habito.rotuloTipo(t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v ?? _tipo),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _salvar,
                child: Text(_loading ? 'Salvando...' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
