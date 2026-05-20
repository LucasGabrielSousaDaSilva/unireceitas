/// ValidationService - Valida dados de entrada do usuário
class ValidationService {
  /// Valida email
  static String? validarEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email é obrigatório';
    }

    // Expressão regular para validar email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Email inválido';
    }

    return null;
  }

  /// Valida senha com requisitos de força
  static String? validarSenha(String? senha) {
    if (senha == null || senha.isEmpty) {
      return 'Senha é obrigatória';
    }

    if (senha.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }

    if (senha.length < 8) {
      return 'Recomenda-se no mínimo 8 caracteres para maior segurança';
    }

    return null;
  }

  /// Valida força da senha (retorna pontuação 0-3)
  static int calcularForcaSenha(String senha) {
    int forcaScore = 0;

    // Verifica comprimento
    if (senha.length >= 8) forcaScore++;
    if (senha.length >= 12) forcaScore++;

    // Verifica complexidade
    if (RegExp(r'[a-z]').hasMatch(senha) &&
        RegExp(r'[A-Z]').hasMatch(senha)) {
      forcaScore++;
    }

    if (RegExp(r'[0-9]').hasMatch(senha)) {
      forcaScore++;
    }

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(senha)) {
      forcaScore++;
    }

    return forcaScore;
  }

  /// Retorna descrição da força da senha
  static String obterDescricaoForca(int score) {
    switch (score) {
      case 0:
        return 'Muito fraca';
      case 1:
        return 'Fraca';
      case 2:
        return 'Média';
      case 3:
        return 'Forte';
      default:
        return 'Muito forte';
    }
  }

  /// Retorna cor para indicador de força (Material color)
  static int obterCorForca(int score) {
    switch (score) {
      case 0:
        return 0xFFD32F2F; // Vermelho escuro
      case 1:
        return 0xFFFF6F00; // Laranja escuro
      case 2:
        return 0xFFFDD835; // Amarelo
      case 3:
        return 0xFF388E3C; // Verde
      default:
        return 0xFF1B5E20; // Verde escuro
    }
  }

  /// Valida nome de usuário
  static String? validarNome(String? nome) {
    if (nome == null || nome.isEmpty) {
      return 'Nome é obrigatório';
    }

    if (nome.length < 3) {
      return 'Nome deve ter no mínimo 3 caracteres';
    }

    if (nome.length > 100) {
      return 'Nome não pode exceder 100 caracteres';
    }

    return null;
  }

  /// Valida nome de receita
  static String? validarNomeReceita(String? nome) {
    if (nome == null || nome.isEmpty) {
      return 'Nome da receita é obrigatório';
    }

    if (nome.length < 3) {
      return 'Nome deve ter no mínimo 3 caracteres';
    }

    if (nome.length > 200) {
      return 'Nome não pode exceder 200 caracteres';
    }

    return null;
  }

  /// Valida ingredientes
  static String? validarIngredientes(String? ingredientes) {
    if (ingredientes == null || ingredientes.isEmpty) {
      return 'Ingredientes são obrigatórios';
    }

    if (ingredientes.length < 10) {
      return 'Descreva os ingredientes com mais detalhes';
    }

    return null;
  }

  /// Valida modo de preparo
  static String? validarModoPreparo(String? modo) {
    if (modo == null || modo.isEmpty) {
      return 'Modo de preparo é obrigatório';
    }

    if (modo.length < 20) {
      return 'Descreva o modo de preparo com mais detalhes';
    }

    return null;
  }

  /// Valida tempo de preparo
  static String? validarTempoPreparo(String? tempo) {
    if (tempo == null || tempo.isEmpty) {
      return 'Tempo de preparo é obrigatório';
    }

    return null;
  }

  /// Valida se duas senhas são iguais
  static String? validarConfirmacaoSenha(
    String? senha,
    String? confirmacao,
  ) {
    if (senha != confirmacao) {
      return 'As senhas não conferem';
    }

    return null;
  }

  /// Valida entrada de URL
  static String? validarUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null; // URL é opcional
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );

    if (!urlRegex.hasMatch(url)) {
      return 'URL inválida';
    }

    return null;
  }

  /// Valida entrada de número
  static String? validarNumero(String? numero) {
    if (numero == null || numero.isEmpty) {
      return 'Campo obrigatório';
    }

    try {
      int.parse(numero);
      return null;
    } catch (e) {
      return 'Deve ser um número válido';
    }
  }

  /// Valida entrada de número positivo
  static String? validarNumeroPositivo(String? numero) {
    final validacao = validarNumero(numero);
    if (validacao != null) return validacao;

    if (int.parse(numero!) <= 0) {
      return 'Deve ser um número positivo';
    }

    return null;
  }

  /// Limpa e valida entrada de texto (remove espaços extras)
  static String limparTexto(String texto) {
    return texto.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
