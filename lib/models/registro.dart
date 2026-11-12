import 'dart:convert';

class Registro {
  final String id;
  final int usuarioId;
  final String? habitoId;
  final double valor;
  final String? observacao;
  final DateTime dataRegistro;
  final bool sincronizado;

  const Registro({
    required this.id,
    required this.usuarioId,
    this.habitoId,
    required this.valor,
    this.observacao,
    required this.dataRegistro,
    this.sincronizado = false,
  });

  Registro copyWith({
    String? habitoId,
    double? valor,
    String? observacao,
    bool? sincronizado,
  }) {
    return Registro(
      id: id,
      usuarioId: usuarioId,
      habitoId: habitoId ?? this.habitoId,
      valor: valor ?? this.valor,
      observacao: observacao ?? this.observacao,
      dataRegistro: dataRegistro,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'habito_id': habitoId,
        'valor': valor,
        'observacao': observacao,
        'data_registro': dataRegistro.toIso8601String(),
        'sincronizado': sincronizado ? 1 : 0,
      };

  factory Registro.fromMap(Map<String, dynamic> map) {
    final valor = (map['valor'] as num?)?.toDouble() ?? 0;
    if (valor <= 0) {
      throw ArgumentError('O valor do registro deve ser maior que zero.');
    }
    return Registro(
      id: map['id']?.toString() ?? '',
      usuarioId: (map['usuario_id'] as num).toInt(),
      habitoId: map['habito_id']?.toString(),
      valor: valor,
      observacao: map['observacao'] as String?,
      dataRegistro:
          DateTime.tryParse(map['data_registro']?.toString() ?? '') ??
              DateTime.now(),
      sincronizado: map['sincronizado'] == 1 || map['sincronizado'] == true,
    );
  }

  Map<String, dynamic> toApiJson() => {
        'id': id,
        'usuario_id': usuarioId,
        'habito_id': habitoId,
        'valor': valor,
        'observacao': observacao,
        'data_registro': dataRegistro.toIso8601String(),
      };

  String toJson() => jsonEncode(toApiJson());
}
