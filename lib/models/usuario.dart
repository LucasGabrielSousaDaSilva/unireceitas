/// Modelo que representa um usuário no aplicativo.
class Usuario {

  final String id;
  String nome;
  String email;
  String senha;

  Usuario({
    String? id,
    required this.nome,
    required this.email,
    required this.senha,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}
