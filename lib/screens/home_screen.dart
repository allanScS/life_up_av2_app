import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/habito.dart';
import '../models/meta.dart';
import '../models/registro.dart';
import '../theme/app_theme.dart';
import '../widgets/habito_card.dart';
import '../widgets/meta_progress_card.dart';
import '../widgets/quick_registro_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.embeddedInShell = false,
    this.onOpenHabitos,
    this.onOpenMetas,
    this.onOpenSync,
  });

  final bool embeddedInShell;
  final VoidCallback? onOpenHabitos;
  final VoidCallback? onOpenMetas;
  final VoidCallback? onOpenSync;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Habito> _habitos = [];
  List<Meta> _metas = [];
  List<Registro> _registros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => recarregar());
  }

  Future<void> recarregar() => _carregar();

  Future<void> _carregar() async {
    final scope = AppScope.of(context);
    final user = scope.usuario;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    setState(() => _loading = true);
    final habitos = await scope.repository.listarHabitos(user.id);
    final metas = await scope.repository.listarMetas(user.id);
    final registros = await scope.repository.listarRegistros(user.id);
    if (!mounted) return;
    setState(() {
      _habitos = habitos;
      _metas = metas;
      _registros = registros;
      _loading = false;
    });
  }

  Meta? get _metaDestaque {
    final hidrica = _metas.where((m) => m.tipo == 'HIDRICA').firstOrNull;
    if (hidrica != null) return hidrica;
    return _metas.firstOrNull;
  }

  void _goHabitos() {
    if (widget.onOpenHabitos != null) {
      widget.onOpenHabitos!();
    } else {
      Navigator.pushNamed(context, '/habitos').then((_) => recarregar());
    }
  }

  void _goMetas() {
    if (widget.onOpenMetas != null) {
      widget.onOpenMetas!();
    } else {
      Navigator.pushNamed(context, '/metas').then((_) => recarregar());
    }
  }

  void _goSync() {
    if (widget.onOpenSync != null) {
      widget.onOpenSync!();
    } else {
      Navigator.pushNamed(context, '/sync').then((_) => recarregar());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).usuario;
    final pendentes = [
      ..._habitos.where((e) => !e.sincronizado),
      ..._metas.where((e) => !e.sincronizado),
      ..._registros.where((e) => !e.sincronizado),
    ].length;
    final primeiroNome = user?.nome.split(' ').first ?? '';
    final meta = _metaDestaque;
    final bottomPad = widget.embeddedInShell ? 24.0 : 100.0;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: recarregar,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _DashboardHeader(
                      nome: primeiroNome,
                      pendentes: pendentes,
                      onSync: _goSync,
                      onPerfil: () =>
                          Navigator.pushNamed(context, '/perfil'),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
                    sliver: SliverList.list(
                      children: [
                        if (meta != null) ...[
                          const _SectionTitle('Meta em destaque'),
                          const SizedBox(height: 8),
                          MetaProgressCard(
                            meta: meta,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/metas/form',
                              arguments: meta.id,
                            ).then((_) => recarregar()),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _SyncStatusCard(
                          pendentes: pendentes,
                          onTap: _goSync,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: _SectionTitle('Hábitos'),
                            ),
                            TextButton(
                              onPressed: _goHabitos,
                              child: const Text('Ver todos'),
                            ),
                          ],
                        ),
                        if (_habitos.isEmpty)
                          const _MiniEmpty(
                            text: 'Nenhum hábito ainda. Crie o primeiro na aba Hábitos.',
                          )
                        else
                          ..._habitos.take(3).map(
                                (h) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: HabitoCard(
                                    habito: h,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/habitos/detalhe',
                                      arguments: h.id,
                                    ).then((_) => recarregar()),
                                    onQuickRegister: () async {
                                      final ok =
                                          await showQuickRegistroSheet(
                                        context,
                                        habito: h,
                                      );
                                      if (ok && mounted) await recarregar();
                                    },
                                  ),
                                ),
                              ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: _SectionTitle('Metas')),
                            TextButton(
                              onPressed: _goMetas,
                              child: const Text('Ver todas'),
                            ),
                          ],
                        ),
                        if (_metas.isEmpty)
                          const _MiniEmpty(
                            text: 'Cadastre uma meta hídrica ou calórica.',
                          )
                        else
                          ..._metas.take(2).map(
                                (m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: MetaProgressCard(
                                    meta: m,
                                    compact: true,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/metas/form',
                                      arguments: m.id,
                                    ).then((_) => recarregar()),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.water_drop_rounded,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            title: const Text(
                              'Registros',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${_registros.length} lançamento(s)',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/registros',
                            ).then((_) => recarregar()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: widget.embeddedInShell
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/registros/form')
                  .then((_) => recarregar()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar'),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.pendentes, required this.onTap});

  final int pendentes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ok = pendentes == 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ok
                      ? AppColors.primarySoft
                      : const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  ok ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
                  color: ok ? AppColors.primary : AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ok ? 'Tudo sincronizado' : '$pendentes pendente(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ok
                          ? 'Seus dados locais estão alinhados com a API.'
                          : 'Há itens para enviar quando estiver online.',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.nome,
    required this.pendentes,
    required this.onSync,
    required this.onPerfil,
  });

  final String nome;
  final int pendentes;
  final VoidCallback onSync;
  final VoidCallback onPerfil;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientTop, AppColors.gradientBottom],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'LifeUp',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sincronização',
                  onPressed: onSync,
                  icon: Badge(
                    isLabelVisible: pendentes > 0,
                    label: Text('$pendentes'),
                    child: const Icon(Icons.sync_rounded, color: Colors.white),
                  ),
                ),
                IconButton(
                  tooltip: 'Perfil',
                  onPressed: onPerfil,
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Olá, $nome',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Acompanhe hábitos e metas — funciona offline também.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
