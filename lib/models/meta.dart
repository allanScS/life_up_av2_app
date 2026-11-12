import 'dart:convert';

class Meta {
  final String id;
  final int usuarioId;
  final String tipo;
  final String titulo;
  final String? descricao;
  final double valorObjetivo;
  final double valorAtual;
  final String status;
  final DateTime dataCriacao;
  final bool sincronizado;

  const Meta({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.titulo,
    this.descricao,
    required this.valorObjetivo,
    this.valorAtual = 0,
    this.status = 'pendente',
    required this.dataCriacao,
    this.sincronizado = false,
  });

  double get progresso {
    if (valorObjetivo <= 0) return 0;
    final p = (valorAtual / valorObjetivo) * 100;
    return p.clamp(0, 100);
  }

  bool get concluida => valorAtual >= valorObjetivo;

  Meta copyWith({
    String? titulo,
    String? descricao,
    double? valorObjetivo,
    double? valorAtual,
    String? status,
    bool? sincronizado,
  }) {
    final atual = valorAtual ?? this.valorAtual;
    final objetivo = valorObjetivo ?? this.valorObjetivo;
    String novoStatus = status ?? this.status;
    if (status == null) {
      if (atual >= objetivo) {
        novoStatus = 'concluida';
      } else if (atual > 0) {
        novoStatus = 'emAndamento';
      } else {
        novoStatus = 'pendente';
      }
    }
    return Meta(
      id: id,
      usuarioId: usuarioId,
      tipo: tipo,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      valorObjetivo: objetivo,
      valorAtual: atual,
      status: novoStatus,
      dataCriacao: dataCriacao,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'tipo': tipo,
        'titulo': titulo,
        'descricao': descricao,
        'valor_objetivo': valorObjetivo,
        'valor_atual': valorAtual,
        'status': status,
        'data_criacao': dataCriacao.toIso8601String(),
        'sincronizado': sincronizado ? 1 : 0,
      };

  factory Meta.fromMap(Map<String, dynamic> map) {
    final objetivo = (map['valor_objetivo'] as num?)?.toDouble() ?? 0;
    if (objetivo <= 0) {
      throw ArgumentError('O valor objetivo deve ser maior que zero.');
    }
    final atual = (map['valor_atual'] as num?)?.toDouble() ?? 0;
    if (atual < 0) {
      throw ArgumentError('O valor atual não pode ser negativo.');
    }
    return Meta(
      id: map['id']?.toString() ?? '',
      usuarioId: (map['usuario_id'] as num).toInt(),
      tipo: map['tipo']?.toString() ?? 'HIDRICA',
      titulo: map['titulo']?.toString() ?? '',
      descricao: map['descricao'] as String?,
      valorObjetivo: objetivo,
      valorAtual: atual,
      status: map['status']?.toString() ?? 'pendente',
      dataCriacao: DateTime.tryParse(map['data_criacao']?.toString() ?? '') ??
          DateTime.now(),
      sincronizado: map['sincronizado'] == 1 || map['sincronizado'] == true,
    );
  }

  Map<String, dynamic> toApiJson() => {
        'id': id,
        'usuario_id': usuarioId,
        'tipo': tipo,
        'titulo': titulo,
        'descricao': descricao,
        'valor_objetivo': valorObjetivo,
        'valor_atual': valorAtual,
        'status': status,
        'data_criacao': dataCriacao.toIso8601String(),
      };

  String toJson() => jsonEncode(toApiJson());
}
