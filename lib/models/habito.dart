import 'dart:convert';

class Habito {
  final String id;
  final int usuarioId;
  final String nome;
  final String? descricao;
  final String tipo;
  final bool ativo;
  final DateTime dataCriacao;
  final bool sincronizado;

  const Habito({
    required this.id,
    required this.usuarioId,
    required this.nome,
    this.descricao,
    required this.tipo,
    this.ativo = true,
    required this.dataCriacao,
    this.sincronizado = false,
  });

  Habito copyWith({
    String? nome,
    String? descricao,
    String? tipo,
    bool? ativo,
    bool? sincronizado,
  }) {
    return Habito(
      id: id,
      usuarioId: usuarioId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'nome': nome,
        'descricao': descricao,
        'tipo': tipo,
        'ativo': ativo ? 1 : 0,
        'data_criacao': dataCriacao.toIso8601String(),
        'sincronizado': sincronizado ? 1 : 0,
      };

  factory Habito.fromMap(Map<String, dynamic> map) {
    final nome = (map['nome'] as String?)?.trim() ?? '';
    if (nome.isEmpty) {
      throw ArgumentError('O nome do hábito não pode ser vazio.');
    }
    return Habito(
      id: map['id']?.toString() ?? '',
      usuarioId: (map['usuario_id'] as num).toInt(),
      nome: nome,
      descricao: map['descricao'] as String?,
      tipo: map['tipo']?.toString() ?? 'outro',
      ativo: map['ativo'] == 1 || map['ativo'] == true,
      dataCriacao: DateTime.tryParse(map['data_criacao']?.toString() ?? '') ??
          DateTime.now(),
      sincronizado: map['sincronizado'] == 1 || map['sincronizado'] == true,
    );
  }

  Map<String, dynamic> toApiJson() => {
        'id': id,
        'usuario_id': usuarioId,
        'nome': nome,
        'descricao': descricao,
        'tipo': tipo,
        'ativo': ativo,
        'data_criacao': dataCriacao.toIso8601String(),
      };

  String toJson() => jsonEncode(toApiJson());

  static const tipos = [
    'hidratacao',
    'alimentacao',
    'atividadeFisica',
    'sono',
    'estudo',
    'outro',
  ];

  static String rotuloTipo(String tipo) {
    switch (tipo) {
      case 'hidratacao':
        return 'Hidratação';
      case 'alimentacao':
        return 'Alimentação';
      case 'atividadeFisica':
        return 'Atividade física';
      case 'sono':
        return 'Sono';
      case 'estudo':
        return 'Estudo';
      default:
        return 'Outro';
    }
  }
}
