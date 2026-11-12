class UsuarioSessao {
  final int id;
  final String nome;
  final String nomeUsuario;

  const UsuarioSessao({
    required this.id,
    required this.nome,
    required this.nomeUsuario,
  });

  factory UsuarioSessao.fromJson(Map<String, dynamic> json) {
    return UsuarioSessao(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      nomeUsuario: json['nome_usuario'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'nome_usuario': nomeUsuario,
      };
}
