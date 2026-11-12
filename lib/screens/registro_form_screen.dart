import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/habito.dart';

class RegistroFormScreen extends StatefulWidget {
  const RegistroFormScreen({super.key});

  @override
  State<RegistroFormScreen> createState() => _RegistroFormScreenState();
}

class _RegistroFormScreenState extends State<RegistroFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  List<Habito> _habitos = [];
  String? _habitoId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarHabitos());
  }

  Future<void> _carregarHabitos() async {
    final scope = AppScope.of(context);
    final lista = await scope.repository.listarHabitos(scope.usuario!.id);
    if (!mounted) return;
    setState(() => _habitos = lista);
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final scope = AppScope.of(context);
    try {
      await scope.repository.salvarRegistro(
        usuarioId: scope.usuario!.id,
        habitoId: _habitoId,
        valor: double.parse(_valorCtrl.text.replaceAll(',', '.')),
        observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro salvo localmente')),
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
      appBar: AppBar(title: const Text('Novo registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _valorCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor (ml / kcal / etc.)',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Informe um valor > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  prefixIcon: Icon(Icons.notes_rounded),
                  helperText: 'Ex.: água / kcal para refletir na meta',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _habitoId,
                decoration: const InputDecoration(
                  labelText: 'Hábito (opcional)',
                  prefixIcon: Icon(Icons.checklist_rounded),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Nenhum'),
                  ),
                  ..._habitos.map(
                    (h) => DropdownMenuItem<String?>(
                      value: h.id,
                      child: Text(h.nome),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _habitoId = v),
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
