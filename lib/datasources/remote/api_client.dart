import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/usuario_sessao.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class RedeException implements Exception {
  RedeException([this.message = 'Sem conexão com a API.']);
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, dynamic>> _decode(http.Response response) {
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (body is Map<String, dynamic>) return Future.value(body);
    if (body is Map) return Future.value(Map<String, dynamic>.from(body));
    return Future.value({'raw': body});
  }

  Future<http.Response> _send(
    Future<http.Response> Function() call,
  ) async {
    try {
      return await call().timeout(ApiConfig.timeout);
    } on SocketException catch (e) {
      throw RedeException(e.message);
    } on TimeoutException {
      throw RedeException('Timeout ao contatar a API.');
    } on http.ClientException catch (e) {
      throw RedeException(e.message);
    }
  }

  Future<UsuarioSessao> register({
    required String nome,
    required String nomeUsuario,
    required String senha,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/auth/register'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'nome': nome,
          'nome_usuario': nomeUsuario,
          'senha': senha,
        }),
      ),
    );
    final json = await _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(json['erro']?.toString() ?? 'Falha no cadastro',
          statusCode: response.statusCode);
    }
    return UsuarioSessao.fromJson(json);
  }

  Future<UsuarioSessao> login({
    required String nomeUsuario,
    required String senha,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'nome_usuario': nomeUsuario,
          'senha': senha,
        }),
      ),
    );
    final json = await _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(json['erro']?.toString() ?? 'Falha no login',
          statusCode: response.statusCode);
    }
    return UsuarioSessao.fromJson(json);
  }

  Future<Map<String, dynamic>> sync({
    required int usuarioId,
    required List<Map<String, dynamic>> habitos,
    required List<Map<String, dynamic>> metas,
    required List<Map<String, dynamic>> registros,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/usuarios/$usuarioId/sync'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'habitos': habitos,
          'metas': metas,
          'registros': registros,
        }),
      ),
    );
    final json = await _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(json['erro']?.toString() ?? 'Falha no sync',
          statusCode: response.statusCode);
    }
    return json;
  }

  Future<Map<String, dynamic>> backup(int usuarioId) async {
    final response = await _send(
      () => _client.get(_uri('/usuarios/$usuarioId/backup')),
    );
    final json = await _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(json['erro']?.toString() ?? 'Falha no backup',
          statusCode: response.statusCode);
    }
    return json;
  }

  Future<bool> health() async {
    try {
      final response = await _send(() => _client.get(_uri('/health')));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
