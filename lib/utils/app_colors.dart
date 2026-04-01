import 'package:flutter/material.dart';

/// Classe utilitária que centraliza todas as cores usadas no aplicativo.
/// As cores seguem o padrão: vermelho, preto, branco e dourado.
class AppColors {
  // Cor vermelha principal do app
  static const Color vermelho = Color(0xFFC62828);

  // Vermelho mais escuro para variações (hover, pressed, etc.)
  static const Color vermelhoEscuro = Color(0xFF8E0000);

  // Cor preta usada em textos e fundos escuros
  static const Color preto = Color(0xFF212121);

  // Cor branca usada em fundos claros e textos sobre fundos escuros
  static const Color branco = Color(0xFFFFFFFF);

  // Cor dourada usada como destaque e acentos
  static const Color dourado = Color(0xFFDAA520);

  // Dourado claro para fundos sutis
  static const Color douradoClaro = Color(0xFFF5E6B8);

  // Cinza claro para divisores e fundos secundários
  static const Color cinzaClaro = Color(0xFFF5F5F5);

  // Cinza para textos secundários
  static const Color cinza = Color(0xFF757575);
}
