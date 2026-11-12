import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../repositories/lifeup_repository.dart';
import '../theme/app_theme.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({
    super.key,
    this.embeddedInShell = false,
  });

  final bool embeddedInShell;

  @override
  State<SyncScreen> createState() => SyncScreenState();
}

class SyncScreenState extends State<SyncScreen> {
  DiagnosticoSync? _diag;
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => recarregar());
  }

  Future<void> recarregar() => _carregar();

  Future<void> _carregar() async {
    final scope = AppScope.of(context);
    final diag = await scope.repository.diagnostico(
      scope.usuario!.id,
      checarApi: true,
    );
    if (!mounted) return;
    setState(() {
      _diag = diag;
      _loading = false;
    });
  }

  Future<void> sincronizarAgora() => _sincronizar();

  Future<void> _sincronizar() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final scope = AppScope.of(context);
    final result = await scope.repository.sincronizar(scope.usuario!.id);
    await _carregar();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.mensagem),
        backgroundColor:
            result.sucesso ? AppColors.success : AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _diag;
    final bottomPad = widget.embeddedInShell ? 24.0 : 16.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronização'),
        automaticallyImplyLeading: !widget.embeddedInShell,
      ),
      body: _loading || d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: d.apiOnline
                                ? AppColors.primarySoft
                                : const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            d.apiOnline
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_off_rounded,
                            color: d.apiOnline
                                ? AppColors.primary
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.apiOnline ? 'API online' : 'API offline',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                d.ultimaSyncIso == null
                                    ? 'Nunca sincronizou'
                                    : 'Última sync: ${d.ultimaSyncIso}',
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _row('Hábitos pendentes', d.habitosPendentes),
                      const Divider(height: 1),
                      _row('Metas pendentes', d.metasPendentes),
                      const Divider(height: 1),
                      _row('Registros pendentes', d.registrosPendentes),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _syncing ? null : _sincronizar,
                  icon: _syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: const Text('Sincronizar agora'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Em modo avião o app continua gravando no SQLite. '
                  'Quando a rede voltar, envie as pendências.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, int value) {
    final ok = value == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 28,
            constraints: const BoxConstraints(minWidth: 28),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ok ? AppColors.primarySoft : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                color: ok ? AppColors.primary : AppColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
