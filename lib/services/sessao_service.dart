import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../datasources/remote/api_client.dart';
import '../models/usuario_sessao.dart';

class SessaoService {
  SessaoService(this._api);

  final ApiClient _api;
  static const _key = 'usuario_sessao';

  Future<UsuarioSessao?> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return UsuarioSessao.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _persistir(UsuarioSessao user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<UsuarioSessao> login({
    required String nomeUsuario,
    required String senha,
  }) async {
    final user = await _api.login(nomeUsuario: nomeUsuario, senha: senha);
    await _persistir(user);
    return user;
  }

  Future<UsuarioSessao> register({
    required String nome,
    required String nomeUsuario,
    required String senha,
  }) async {
    final user = await _api.register(
      nome: nome,
      nomeUsuario: nomeUsuario,
      senha: senha,
    );
    await _persistir(user);
    return user;
  }
}
