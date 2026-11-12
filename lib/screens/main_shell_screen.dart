import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/lifeup_bottom_nav.dart';
import 'habitos_list_screen.dart';
import 'home_screen.dart';
import 'metas_list_screen.dart';
import 'sync_screen.dart';

/// Shell logado com navbar inferior + FAB contextual por aba.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;
  int _pendentes = 0;
  final _homeKey = GlobalKey<HomeScreenState>();
  final _habitosKey = GlobalKey<HabitosListScreenState>();
  final _metasKey = GlobalKey<MetasListScreenState>();
  final _syncKey = GlobalKey<SyncScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _atualizarPendentes());
  }

  Future<void> _atualizarPendentes() async {
    final scope = AppScope.of(context);
    final user = scope.usuario;
    if (user == null) return;
    final diag = await scope.repository.diagnostico(user.id);
    if (!mounted) return;
    setState(() => _pendentes = diag.totalPendentes);
  }

  void _onTab(int i) {
    setState(() => _index = i);
    _refreshTab(i);
  }

  void _refreshTab(int i) {
    switch (i) {
      case 0:
        _homeKey.currentState?.recarregar();
      case 1:
        _habitosKey.currentState?.recarregar();
      case 2:
        _metasKey.currentState?.recarregar();
      case 3:
        _syncKey.currentState?.recarregar();
    }
    _atualizarPendentes();
  }

  Future<void> _onFab() async {
    switch (_index) {
      case 1:
        await Navigator.pushNamed(context, '/habitos/form');
        break;
      case 2:
        await Navigator.pushNamed(context, '/metas/form');
        break;
      case 3:
        await _syncKey.currentState?.sincronizarAgora();
        break;
      default:
        await Navigator.pushNamed(context, '/registros/form');
        break;
    }
    if (!mounted) return;
    _refreshTab(_index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            key: _homeKey,
            embeddedInShell: true,
            onOpenHabitos: () => _onTab(1),
            onOpenMetas: () => _onTab(2),
            onOpenSync: () => _onTab(3),
          ),
          HabitosListScreen(key: _habitosKey, embeddedInShell: true),
          MetasListScreen(key: _metasKey, embeddedInShell: true),
          SyncScreen(key: _syncKey, embeddedInShell: true),
        ],
      ),
      bottomNavigationBar: LifeUpBottomNav(
        currentIndex: _index,
        syncBadgeCount: _pendentes,
        onTap: _onTab,
        onFabTap: _onFab,
        fabIcon: _index == 3 ? Icons.sync_rounded : Icons.add_rounded,
      ),
    );
  }
}
