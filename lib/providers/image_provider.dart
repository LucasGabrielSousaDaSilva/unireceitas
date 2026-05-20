import 'package:flutter/material.dart';
import 'dart:io';
import '../services/image_service.dart';
// import '../services/image_service.dart' show ImageInfo;
  import 'package:unireceitas/services/image_service.dart' as image_service;

/// ImageProvider - Controller de Imagens
/// Gerencia estado de seleção de imagens
class ImageProvider extends ChangeNotifier {
  final ImageService _imageService = ImageService();

  final List<File> _imagensSelecionadas = [];
  bool _carregando = false;
  String? _erro;

  // ===================== GETTERS =====================

  /// Lista de imagens selecionadas
  List<File> get imagensSelecionadas => List.unmodifiable(_imagensSelecionadas);

  /// Número de imagens selecionadas
  int get totalImagens => _imagensSelecionadas.length;

  /// Verifica se está carregando
  bool get carregando => _carregando;

  /// Última mensagem de erro
  String? get erro => _erro;

  /// Tem algum erro?
  bool get temErro => _erro != null;

  // ===================== OPERAÇÕES COM CÂMERA =====================

  /// Captura foto com câmera
  Future<void> capturarFoto() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final foto = await _imageService.capturarFoto();
      if (foto != null) {
        _imagensSelecionadas.add(foto);
        notifyListeners();
      }
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Seleciona imagem da galeria
  Future<void> selecionarDaGaleria() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final imagem = await _imageService.selecionarDaGaleria();
      if (imagem != null) {
        if (ImageService.validarImagem(imagem)) {
          if (ImageService.validarTamanho(imagem)) {
            _imagensSelecionadas.add(imagem);
            notifyListeners();
          } else {
            _erro = 'Imagem muito grande (máximo 10 MB)';
            notifyListeners();
          }
        } else {
          _erro = 'Arquivo inválido';
          notifyListeners();
        }
      }
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Seleciona múltiplas imagens
  Future<void> selecionarMultiplas() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final imagens = await _imageService.selecionarMultiplas();
      for (final imagem in imagens) {
        if (ImageService.validarImagem(imagem) &&
            ImageService.validarTamanho(imagem)) {
          _imagensSelecionadas.add(imagem);
        }
      }
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Remove uma imagem por índice
  Future<void> removerImagem(int index) async {
    if (index < 0 || index >= _imagensSelecionadas.length) {
      return;
    }

    try {
      await ImageService.excluir(_imagensSelecionadas[index]);
      _imagensSelecionadas.removeAt(index);
      notifyListeners();
    } catch (e) {
      _erro = 'Erro ao remover imagem: $e';
      notifyListeners();
    }
  }

  /// Remove todas as imagens
  Future<void> limparTodas() async {
    _carregando = true;
    notifyListeners();

    try {
      for (final imagem in _imagensSelecionadas) {
        await ImageService.excluir(imagem);
      }
      _imagensSelecionadas.clear();
      _erro = null;
      notifyListeners();
    } catch (e) {
      _erro = 'Erro ao limpar imagens: $e';
      notifyListeners();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Limpa mensagem de erro
  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  /// Obtém informações de uma imagem
  // Future<ImageInfo?> obterInfo(int index) async {
  //   if (index < 0 || index >= _imagensSelecionadas.length) {
  //     return null;
  //   }

  //   return ImageService.obterInfo(_imagensSelecionadas[index]);
  // }
  
  Future<image_service.ImageInfo?> obterInfo(int index) async {
    if (index < 0 || index >= _imagensSelecionadas.length) {
      return null;
    }
    return image_service.ImageService.obterInfo(_imagensSelecionadas[index]);
  }
}

// Importar ImageInfo

