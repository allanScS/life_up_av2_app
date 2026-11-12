import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../datasources/local/habito_local_datasource.dart';
import '../datasources/local/meta_local_datasource.dart';
import '../datasources/local/registro_local_datasource.dart';
import '../datasources/remote/api_client.dart';
import '../models/habito.dart';
import '../models/meta.dart';
import '../models/registro.dart';

/// Repositório Offline-First: grava local primeiro; sync sob demanda (tela Sync).
class LifeUpRepository {
  LifeUpRepository({
    required HabitoLocalDatasource habitoLocal,
    required MetaLocalDatasource metaLocal,
    required RegistroLocalDatasource registroLocal,
    required ApiClient apiClient,
  })  : _habitoLocal = habitoLocal,
        _metaLocal = metaLocal,
        _registroLocal = registroLocal,
        _api = apiClient;

  final HabitoLocalDatasource _habitoLocal;
  final MetaLocalDatasource _metaLocal;
  final RegistroLocalDatasource _registroLocal;
  final ApiClient _api;
  final _uuid = const Uuid();

  // ---- Hábitos ----

  Future<List<Habito>> listarHabitos(int usuarioId) {
    return _habitoLocal.listarPorUsuario(usuarioId);
  }

  Future<Habito> salvarHabito({
    required int usuarioId,
    String? id,
    required String nome,
    String? descricao,
    required String tipo,
    bool ativo = true,
  }) async {
    final habito = Habito(
      id: id ?? _uuid.v4(),
      usuarioId: usuarioId,
      nome: nome,
      descricao: descricao,
      tipo: tipo,
      ativo: ativo,
      dataCriacao: DateTime.now(),
      sincronizado: false,
    );
    await _habitoLocal.salvarOuAtualizar(habito);
    final atualizado = await _habitoLocal.buscarPorId(habito.id);
    return atualizado ?? habito;
  }

  Future<void> removerHabito(int usuarioId, String id) async {
    await _habitoLocal.removerPorId(id);
  }

  // ---- Metas ----

  Future<List<Meta>> listarMetas(int usuarioId) {
    return _metaLocal.listarPorUsuario(usuarioId);
  }

  Future<Meta> salvarMeta({
    required int usuarioId,
    String? id,
    required String tipo,
    required String titulo,
    String? descricao,
    required double valorObjetivo,
    double valorAtual = 0,
  }) async {
    // API permite só 1 meta por tipo (HIDRICA/CALORICA) — reutiliza a existente.
    var metaId = id;
    Meta? existente;
    if (metaId == null) {
      final lista = await _metaLocal.listarPorUsuario(usuarioId);
      existente = lista.where((m) => m.tipo == tipo).firstOrNull;
      metaId = existente?.id ?? _uuid.v4();
    } else {
      existente = await _metaLocal.buscarPorId(metaId);
    }

    final meta = Meta(
      id: metaId,
      usuarioId: usuarioId,
      tipo: tipo,
      titulo: titulo,
      descricao: descricao,
      valorObjetivo: valorObjetivo,
      valorAtual: valorAtual,
      dataCriacao: existente?.dataCriacao ?? DateTime.now(),
      sincronizado: false,
    ).copyWith(valorAtual: valorAtual);
    await _metaLocal.salvarOuAtualizar(meta);
    return (await _metaLocal.buscarPorId(meta.id)) ?? meta;
  }

  Future<void> removerMeta(int usuarioId, String id) async {
    await _metaLocal.removerPorId(id);
  }

  // ---- Registros ----

  Future<List<Registro>> listarRegistros(int usuarioId) {
    return _registroLocal.listarPorUsuario(usuarioId);
  }

  Future<Registro> salvarRegistro({
    required int usuarioId,
    String? id,
    String? habitoId,
    required double valor,
    String? observacao,
  }) async {
    final registro = Registro(
      id: id ?? _uuid.v4(),
      usuarioId: usuarioId,
      habitoId: habitoId,
      valor: valor,
      observacao: observacao,
      dataRegistro: DateTime.now(),
      sincronizado: false,
    );
    await _registroLocal.salvarOuAtualizar(registro);

    // Atualiza meta hídrica/calórica localmente se observação indicar
    await _aplicarRegistroNasMetas(usuarioId, registro);

    return (await _registroLocal.buscarPorId(registro.id)) ?? registro;
  }

  Future<void> removerRegistro(int usuarioId, String id) async {
    await _registroLocal.removerPorId(id);
  }

  Future<void> _aplicarRegistroNasMetas(int usuarioId, Registro registro) async {
    final obs = (registro.observacao ?? '').toLowerCase();
    final metas = await _metaLocal.listarPorUsuario(usuarioId);
    for (final meta in metas) {
      final aplicaHidrica =
          meta.tipo == 'HIDRICA' && (obs.contains('água') || obs.contains('agua') || obs.contains('ml'));
      final aplicaCalorica =
          meta.tipo == 'CALORICA' && (obs.contains('kcal') || obs.contains('caloria'));
      if (aplicaHidrica || aplicaCalorica) {
        final atualizada = meta
            .copyWith(valorAtual: meta.valorAtual + registro.valor, sincronizado: false);
        await _metaLocal.salvarOuAtualizar(atualizada);
      }
    }
  }

  /// Sincroniza pendências com a API e consolida resposta no SQLite.
  Future<SyncResultado> sincronizar(int usuarioId) async {
    final habitosPend = await _habitoLocal.listarPendentes(usuarioId);
    final metasPend = await _metaLocal.listarPendentes(usuarioId);
    final registrosPend = await _registroLocal.listarPendentes(usuarioId);

    try {
      final remote = await _api.sync(
        usuarioId: usuarioId,
        habitos: habitosPend.map((e) => e.toApiJson()).toList(),
        metas: metasPend.map((e) => e.toApiJson()).toList(),
        registros: registrosPend.map((e) => e.toApiJson()).toList(),
      );

      await _aplicarRespostaRemota(usuarioId, remote);
      await _salvarUltimaSync();

      return SyncResultado(
        sucesso: true,
        enviados: habitosPend.length + metasPend.length + registrosPend.length,
        mensagem: 'Sincronização concluída.',
      );
    } on RedeException catch (e) {
      return SyncResultado(
        sucesso: false,
        enviados: 0,
        mensagem: e.message,
        offline: true,
      );
    } on ApiException catch (e) {
      return SyncResultado(
        sucesso: false,
        enviados: 0,
        mensagem: e.message,
      );
    } catch (e) {
      // Mantém dados locais; app continua operacional.
      return SyncResultado(
        sucesso: false,
        enviados: 0,
        mensagem: 'Falha inesperada: $e',
        offline: true,
      );
    }
  }

  /// Conta pendências locais. `checarApi` só deve ser true na tela Sync
  /// (evita HTTP automático ao navegar/salvar).
  Future<DiagnosticoSync> diagnostico(
    int usuarioId, {
    bool checarApi = false,
  }) async {
    final habitos = await _habitoLocal.listarPendentes(usuarioId);
    final metas = await _metaLocal.listarPendentes(usuarioId);
    final registros = await _registroLocal.listarPendentes(usuarioId);
    final prefs = await SharedPreferences.getInstance();
    final ultima = prefs.getString('ultima_sync');
    final online = checarApi ? await _api.health() : false;
    return DiagnosticoSync(
      habitosPendentes: habitos.length,
      metasPendentes: metas.length,
      registrosPendentes: registros.length,
      ultimaSyncIso: ultima,
      apiOnline: online,
    );
  }

  Future<void> _aplicarRespostaRemota(
    int usuarioId,
    Map<String, dynamic> remote,
  ) async {
    final habitos = (remote['habitos'] as List?) ?? const [];
    for (final item in habitos) {
      final map = Map<String, dynamic>.from(item as Map);
      map['sincronizado'] = 1;
      await _habitoLocal.salvarOuAtualizar(Habito.fromMap(map));
    }

    final metas = (remote['metas'] as List?) ?? const [];
    final remoteMetas = <Meta>[];
    for (final item in metas) {
      final map = Map<String, dynamic>.from(item as Map);
      map['sincronizado'] = 1;
      final meta = Meta.fromMap(map);
      remoteMetas.add(meta);
      await _metaLocal.salvarOuAtualizar(meta);
    }
    // Remove duplicatas locais do mesmo tipo com id diferente do servidor.
    final remoteIds = remoteMetas.map((m) => m.id).toSet();
    final remoteTipos = remoteMetas.map((m) => m.tipo).toSet();
    final locais = await _metaLocal.listarPorUsuario(usuarioId);
    for (final local in locais) {
      if (!remoteIds.contains(local.id) && remoteTipos.contains(local.tipo)) {
        await _metaLocal.removerPorId(local.id);
      }
    }

    final registros = (remote['registros'] as List?) ?? const [];
    for (final item in registros) {
      final map = Map<String, dynamic>.from(item as Map);
      map['sincronizado'] = 1;
      await _registroLocal.salvarOuAtualizar(Registro.fromMap(map));
    }
  }

  Future<void> _salvarUltimaSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultima_sync', DateTime.now().toIso8601String());
  }
}

class SyncResultado {
  SyncResultado({
    required this.sucesso,
    required this.enviados,
    required this.mensagem,
    this.offline = false,
  });

  final bool sucesso;
  final int enviados;
  final String mensagem;
  final bool offline;
}

class DiagnosticoSync {
  DiagnosticoSync({
    required this.habitosPendentes,
    required this.metasPendentes,
    required this.registrosPendentes,
    required this.ultimaSyncIso,
    required this.apiOnline,
  });

  final int habitosPendentes;
  final int metasPendentes;
  final int registrosPendentes;
  final String? ultimaSyncIso;
  final bool apiOnline;

  int get totalPendentes =>
      habitosPendentes + metasPendentes + registrosPendentes;
}
