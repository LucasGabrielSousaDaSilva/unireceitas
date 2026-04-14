/// Modelo que representa um usuário no aplicativo.
class Usuario {
  /// Identificador único do usuário
  final String id;

  /// Nome do usuário
  String nome;

  /// Email do usuário (usado para login)
  String email;

  /// Senha do usuário
  String senha;

  Usuario({
    String? id,
    required this.nome,
    required this.email,
    required this.senha,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'senha': senha,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String,
      senha: map['senha'] as String,
    );
  }
}
