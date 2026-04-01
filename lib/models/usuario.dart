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
}
