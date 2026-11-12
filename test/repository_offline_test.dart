import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:life_up_av2_app/datasources/local/habito_local_datasource.dart';
import 'package:life_up_av2_app/datasources/local/meta_local_datasource.dart';
import 'package:life_up_av2_app/datasources/local/registro_local_datasource.dart';
import 'package:life_up_av2_app/datasources/remote/api_client.dart';
import 'package:life_up_av2_app/models/habito.dart';
import 'package:life_up_av2_app/models/meta.dart';
import 'package:life_up_av2_app/models/registro.dart';
import 'package:life_up_av2_app/repositories/lifeup_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeHabitoLocal implements HabitoLocalDatasource {
  final map = <String, Habito>{};

  @override
  Future<Habito?> buscarPorId(String id) async => map[id];

  @override
  Future<List<Habito>> listarPendentes(int usuarioId) async =>
      map.values.where((e) => e.usuarioId == usuarioId && !e.sincronizado).toList();

  @override
  Future<List<Habito>> listarPorUsuario(int usuarioId) async =>
      map.values.where((e) => e.usuarioId == usuarioId).toList();

  @override
  Future<void> marcarSincronizado(String id, {required bool sincronizado}) async {
    final h = map[id];
    if (h != null) map[id] = h.copyWith(sincronizado: sincronizado);
  }

  @override
  Future<void> removerPorId(String id) async => map.remove(id);

  @override
  Future<void> salvarOuAtualizar(Habito habito) async => map[habito.id] = habito;
}

class FakeMetaLocal implements MetaLocalDatasource {
  final map = <String, Meta>{};

  @override
  Future<Meta?> buscarPorId(String id) async => map[id];

  @override
  Future<List<Meta>> listarPendentes(int usuarioId) async =>
      map.values.where((e) => e.usuarioId == usuarioId && !e.sincronizado).toList();

  @override
  Future<List<Meta>> listarPorUsuario(int usuarioId) async =>
      map.values.where((e) => e.usuarioId == usuarioId).toList();

  @override
  Future<void> removerPorId(String id) async => map.remove(id);

  @override
  Future<void> salvarOuAtualizar(Meta meta) async => map[meta.id] = meta;
}

class FakeRegistroLocal implements RegistroLocalDatasource {
  final map = <String, Registro>{};

  @override
  Future<Registro?> buscarPorId(String id) async => map[id];

  @override
  Future<List<Registro>> listarPendentes(int usuarioId) async =>
      map.values.where((e) => e.usuarioId == usuarioId && !e.sincronizado).toList();

  @override
  Future<List<Registro>> listarPorUsuario(int usuarioId) async =>
      map.values.where((e) => e.usuarioId == usuarioId).toList();

  @override
  Future<void> removerPorId(String id) async => map.remove(id);

  @override
  Future<void> salvarOuAtualizar(Registro registro) async =>
      map[registro.id] = registro;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('LifeUpRepository Offline-First', () {
    test('salva hábito localmente mesmo com API 500', () async {
      final habitos = FakeHabitoLocal();
      final metas = FakeMetaLocal();
      final registros = FakeRegistroLocal();
      final client = MockClient((_) async => http.Response('erro', 500));
      final repo = LifeUpRepository(
        habitoLocal: habitos,
        metaLocal: metas,
        registroLocal: registros,
        apiClient: ApiClient(client: client, baseUrl: 'http://test'),
      );

      final salvo = await repo.salvarHabito(
        usuarioId: 1,
        nome: 'Caminhada',
        tipo: 'atividadeFisica',
      );

      expect(habitos.map.length, 1);
      expect(salvo.nome, 'Caminhada');
      expect(habitos.map.values.first.sincronizado, isFalse);
    });

    test('sincronizar marca itens quando API responde ok', () async {
      final habitos = FakeHabitoLocal();
      final metas = FakeMetaLocal();
      final registros = FakeRegistroLocal();
      await habitos.salvarOuAtualizar(
        Habito(
          id: 'h1',
          usuarioId: 9,
          nome: 'Água',
          tipo: 'hidratacao',
          dataCriacao: DateTime(2026),
        ),
      );

      final client = MockClient((request) async {
        expect(request.url.path, contains('/sync'));
        return http.Response(
          '''
{"habitos":[{"id":"h1","usuario_id":9,"nome":"Água","tipo":"hidratacao","ativo":true,"data_criacao":"2026-01-01T00:00:00.000"}],
 "metas":[],"registros":[]}
''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = LifeUpRepository(
        habitoLocal: habitos,
        metaLocal: metas,
        registroLocal: registros,
        apiClient: ApiClient(client: client, baseUrl: 'http://test'),
      );

      final result = await repo.sincronizar(9);
      expect(result.sucesso, isTrue);
      expect(habitos.map['h1']!.sincronizado, isTrue);
    });

    test('sincronizar com falha de rede retorna offline=true', () async {
      final repo = LifeUpRepository(
        habitoLocal: FakeHabitoLocal(),
        metaLocal: FakeMetaLocal(),
        registroLocal: FakeRegistroLocal(),
        apiClient: ApiClient(
          client: MockClient((_) async => throw http.ClientException('fail')),
          baseUrl: 'http://test',
        ),
      );
      final result = await repo.sincronizar(1);
      expect(result.sucesso, isFalse);
      expect(result.offline, isTrue);
    });

    test('salvar meta e listar', () async {
      final metas = FakeMetaLocal();
      final repo = LifeUpRepository(
        habitoLocal: FakeHabitoLocal(),
        metaLocal: metas,
        registroLocal: FakeRegistroLocal(),
        apiClient: ApiClient(
          client: MockClient((_) async => http.Response('{}', 500)),
          baseUrl: 'http://test',
        ),
      );
      await repo.salvarMeta(
        usuarioId: 3,
        tipo: 'HIDRICA',
        titulo: '2L',
        valorObjetivo: 2000,
      );
      final lista = await repo.listarMetas(3);
      expect(lista.length, 1);
      expect(lista.first.titulo, '2L');
    });

    test('salvar registro aplica progresso em meta hídrica', () async {
      final metas = FakeMetaLocal();
      final registros = FakeRegistroLocal();
      await metas.salvarOuAtualizar(
        Meta(
          id: 'm1',
          usuarioId: 1,
          tipo: 'HIDRICA',
          titulo: 'Água',
          valorObjetivo: 2000,
          dataCriacao: DateTime(2026),
        ),
      );
      final repo = LifeUpRepository(
        habitoLocal: FakeHabitoLocal(),
        metaLocal: metas,
        registroLocal: registros,
        apiClient: ApiClient(
          client: MockClient((_) async => http.Response('{}', 500)),
          baseUrl: 'http://test',
        ),
      );
      await repo.salvarRegistro(
        usuarioId: 1,
        valor: 250,
        observacao: 'água 250ml',
      );
      expect(metas.map['m1']!.valorAtual, 250);
      expect(registros.map.length, 1);
    });

    test('remover hábito limpa datasource', () async {
      final habitos = FakeHabitoLocal();
      final repo = LifeUpRepository(
        habitoLocal: habitos,
        metaLocal: FakeMetaLocal(),
        registroLocal: FakeRegistroLocal(),
        apiClient: ApiClient(
          client: MockClient((_) async => http.Response('{}', 500)),
          baseUrl: 'http://test',
        ),
      );
      final h = await repo.salvarHabito(
        usuarioId: 1,
        nome: 'Sono',
        tipo: 'sono',
      );
      await repo.removerHabito(1, h.id);
      expect(habitos.map, isEmpty);
    });

    test('diagnostico conta pendentes', () async {
      final habitos = FakeHabitoLocal();
      await habitos.salvarOuAtualizar(
        Habito(
          id: 'a',
          usuarioId: 1,
          nome: 'X',
          tipo: 'outro',
          dataCriacao: DateTime(2026),
        ),
      );
      final repo = LifeUpRepository(
        habitoLocal: habitos,
        metaLocal: FakeMetaLocal(),
        registroLocal: FakeRegistroLocal(),
        apiClient: ApiClient(
          client: MockClient((_) async => http.Response('ok', 200)),
          baseUrl: 'http://test',
        ),
      );
      final diag = await repo.diagnostico(1, checarApi: true);
      expect(diag.habitosPendentes, 1);
      expect(diag.totalPendentes, 1);
      expect(diag.apiOnline, isTrue);
    });
  });

  group('ApiClient', () {
    test('login lança ApiException em 401', () async {
      final api = ApiClient(
        client: MockClient((_) async => http.Response('{"erro":"x"}', 401)),
        baseUrl: 'http://test',
      );
      expect(
        () => api.login(nomeUsuario: 'a', senha: 'bbbb'),
        throwsA(isA<ApiException>()),
      );
    });

    test('health false em erro', () async {
      final api = ApiClient(
        client: MockClient((_) async => throw http.ClientException('down')),
        baseUrl: 'http://test',
      );
      expect(await api.health(), isFalse);
    });

    test('register lança ApiException em 409', () async {
      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response('{"erro":"já existe"}', 409),
        ),
        baseUrl: 'http://test',
      );
      expect(
        () => api.register(
          nome: 'A',
          nomeUsuario: 'allan',
          senha: '1234',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('DiagnosticoSync', () {
    test('totalPendentes soma as três filas', () {
      final diag = DiagnosticoSync(
        habitosPendentes: 2,
        metasPendentes: 1,
        registrosPendentes: 3,
        ultimaSyncIso: null,
        apiOnline: false,
      );
      expect(diag.totalPendentes, 6);
      expect(diag.apiOnline, isFalse);
    });
  });
}
