import 'package:flutter_test/flutter_test.dart';
import 'package:life_up_av2_app/models/habito.dart';
import 'package:life_up_av2_app/models/meta.dart';
import 'package:life_up_av2_app/models/registro.dart';
import 'package:life_up_av2_app/models/usuario_sessao.dart';
import 'package:life_up_av2_app/widgets/period_filter_chips.dart';

void main() {
  group('Habito', () {
    test('fromMap/toMap preserva campos e sincronizado', () {
      final h = Habito.fromMap({
        'id': 'h1',
        'usuario_id': 1,
        'nome': 'Beber água',
        'descricao': '2L',
        'tipo': 'hidratacao',
        'ativo': 1,
        'data_criacao': '2026-01-01T10:00:00.000',
        'sincronizado': 0,
      });
      expect(h.nome, 'Beber água');
      expect(h.sincronizado, isFalse);
      expect(h.toMap()['sincronizado'], 0);
      expect(h.copyWith(sincronizado: true).sincronizado, isTrue);
    });

    test('rejeita nome vazio', () {
      expect(
        () => Habito.fromMap({
          'id': 'h1',
          'usuario_id': 1,
          'nome': '   ',
          'tipo': 'outro',
          'data_criacao': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rotuloTipo cobre tipos conhecidos', () {
      expect(Habito.rotuloTipo('hidratacao'), 'Hidratação');
      expect(Habito.rotuloTipo('alimentacao'), 'Alimentação');
      expect(Habito.rotuloTipo('atividadeFisica'), 'Atividade física');
      expect(Habito.rotuloTipo('sono'), 'Sono');
      expect(Habito.rotuloTipo('estudo'), 'Estudo');
      expect(Habito.rotuloTipo('xyz'), 'Outro');
    });

    test('toApiJson não inclui flag sincronizado', () {
      final h = Habito(
        id: '1',
        usuarioId: 1,
        nome: 'X',
        tipo: 'outro',
        dataCriacao: DateTime(2026),
        sincronizado: false,
      );
      expect(h.toApiJson().containsKey('sincronizado'), isFalse);
      expect(h.toJson(), contains('X'));
    });
  });

  group('Meta', () {
    test('calcula progresso e conclusão', () {
      final m = Meta(
        id: 'm1',
        usuarioId: 1,
        tipo: 'HIDRICA',
        titulo: 'Água',
        valorObjetivo: 2000,
        valorAtual: 500,
        dataCriacao: DateTime(2026),
      );
      expect(m.progresso, 25);
      expect(m.concluida, isFalse);
      expect(m.copyWith(valorAtual: 2000).concluida, isTrue);
    });

    test('fromMap rejeita objetivo inválido', () {
      expect(
        () => Meta.fromMap({
          'id': 'm1',
          'usuario_id': 1,
          'tipo': 'HIDRICA',
          'titulo': 'x',
          'valor_objetivo': 0,
          'data_criacao': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromMap rejeita valor atual negativo', () {
      expect(
        () => Meta.fromMap({
          'id': 'm1',
          'usuario_id': 1,
          'tipo': 'CALORICA',
          'titulo': 'x',
          'valor_objetivo': 10,
          'valor_atual': -1,
          'data_criacao': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('copyWith atualiza status automaticamente', () {
      final m = Meta(
        id: 'm1',
        usuarioId: 1,
        tipo: 'HIDRICA',
        titulo: 'Água',
        valorObjetivo: 100,
        dataCriacao: DateTime(2026),
      );
      expect(m.copyWith(valorAtual: 10).status, 'emAndamento');
      expect(m.copyWith(valorAtual: 100).status, 'concluida');
    });

    test('toMap usa 0/1 para sincronizado', () {
      final m = Meta(
        id: 'm1',
        usuarioId: 1,
        tipo: 'HIDRICA',
        titulo: 'Água',
        valorObjetivo: 100,
        dataCriacao: DateTime(2026),
        sincronizado: true,
      );
      expect(m.toMap()['sincronizado'], 1);
      expect(m.toJson(), contains('HIDRICA'));
    });
  });

  group('Registro', () {
    test('fromMap/toMap roundtrip', () {
      final r = Registro.fromMap({
        'id': 'r1',
        'usuario_id': 2,
        'habito_id': 'h1',
        'valor': 250,
        'observacao': 'água',
        'data_registro': '2026-02-01T08:00:00.000',
        'sincronizado': 1,
      });
      expect(r.valor, 250);
      expect(r.sincronizado, isTrue);
      expect(r.toMap()['habito_id'], 'h1');
    });

    test('rejeita valor <= 0', () {
      expect(
        () => Registro.fromMap({
          'id': 'r1',
          'usuario_id': 1,
          'valor': 0,
          'data_registro': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('copyWith altera sincronizado', () {
      final r = Registro(
        id: 'r1',
        usuarioId: 1,
        valor: 10,
        dataRegistro: DateTime(2026),
      );
      expect(r.copyWith(sincronizado: true).sincronizado, isTrue);
      expect(r.toApiJson()['valor'], 10);
    });

    test('toApiJson inclui habito_id nulo quando ausente', () {
      final r = Registro(
        id: 'r2',
        usuarioId: 1,
        valor: 100,
        dataRegistro: DateTime(2026, 3, 1),
      );
      expect(r.toApiJson()['habito_id'], isNull);
      expect(r.toJson(), contains('"valor":100'));
    });
  });

  group('UsuarioSessao', () {
    test('fromJson/toJson roundtrip', () {
      final user = UsuarioSessao.fromJson({
        'id': 7,
        'nome': 'Allan',
        'nome_usuario': 'allan',
      });
      expect(user.id, 7);
      expect(user.nome, 'Allan');
      expect(user.nomeUsuario, 'allan');
      expect(user.toJson()['nome_usuario'], 'allan');
    });

    test('fromJson aceita id numérico decimal do JSON', () {
      final user = UsuarioSessao.fromJson({
        'id': 3.0,
        'nome': 'Max',
        'nome_usuario': 'max',
      });
      expect(user.id, 3);
    });
  });

  group('PeriodFilter', () {
    test('hoje só aceita o dia atual', () {
      final agora = DateTime.now();
      expect(periodoContem(PeriodFilter.hoje, agora), isTrue);
      expect(
        periodoContem(
          PeriodFilter.hoje,
          agora.subtract(const Duration(days: 1)),
        ),
        isFalse,
      );
    });

    test('todos sempre retorna true', () {
      expect(
        periodoContem(PeriodFilter.todos, DateTime(2020, 1, 1)),
        isTrue,
      );
    });
  });
}
