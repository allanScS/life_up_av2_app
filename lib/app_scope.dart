import 'package:flutter/material.dart';

import 'datasources/remote/api_client.dart';
import 'models/usuario_sessao.dart';
import 'repositories/lifeup_repository.dart';
import 'services/sessao_service.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.api,
    required this.repository,
    required this.sessao,
    required this.usuario,
    required this.onUsuarioChanged,
    required super.child,
  });

  final ApiClient api;
  final LifeUpRepository repository;
  final SessaoService sessao;
  final UsuarioSessao? usuario;
  final ValueChanged<UsuarioSessao?> onUsuarioChanged;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return oldWidget.usuario?.id != usuario?.id;
  }
}
