import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// ImageService - Gerencia captura e seleção de imagens
class ImageService {
  final ImagePicker _picker = ImagePicker();

  bool get _cameraDisponivel {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  /// Captura foto com câmera
  Future<File?> capturarFoto() async {
    if (!_cameraDisponivel) {
      throw Exception('A câmera não está disponível neste dispositivo.');
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao capturar foto: $e');
    }
  }

  /// Seleciona imagem da galeria
  Future<File?> selecionarDaGaleria() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  /// Seleciona múltiplas imagens
  Future<List<File>> selecionarMultiplas() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      return images.map((img) => File(img.path)).toList();
    } catch (e) {
      throw Exception('Erro ao selecionar múltiplas imagens: $e');
    }
  }

  /// Permite escolher entre câmera e galeria
  Future<File?> selecionarImagem() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  /// Verifica se a imagem é válida
  static bool validarImagem(File arquivo) {
    // Verifica se arquivo existe
    if (!arquivo.existsSync()) {
      return false;
    }

    // Verifica extensão
    final extensao = arquivo.path.split('.').last.toLowerCase();
    final extensoesValidas = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!extensoesValidas.contains(extensao)) {
      return false;
    }

    return true;
  }

  /// Obtém tamanho do arquivo em MB
  static double obterTamanoMB(File arquivo) {
    final bytes = arquivo.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Verifica se tamanho está dentro do limite (em MB)
  static bool validarTamanho(File arquivo, {double limiteeMB = 10}) {
    return obterTamanoMB(arquivo) <= limiteeMB;
  }

  /// Obtém informações da imagem
  static Future<ImageInfo?> obterInfo(File arquivo) async {
    try {
      if (!validarImagem(arquivo)) {
        return null;
      }

      final bytes = arquivo.lengthSync();
      final extensao = arquivo.path.split('.').last.toLowerCase();

      return ImageInfo(
        caminho: arquivo.path,
        tamanhoBytes: bytes,
        tamanhoMB: obterTamanoMB(arquivo),
        extensao: extensao,
        nomeArquivo: arquivo.path.split('/').last,
      );
    } catch (e) {
      return null;
    }
  }

  /// Exclui arquivo de imagem
  static Future<bool> excluir(File arquivo) async {
    try {
      if (arquivo.existsSync()) {
        await arquivo.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Copia imagem para novo local
  static Future<File?> copiar(File arquivo, String novoLocal) async {
    try {
      if (!validarImagem(arquivo)) {
        return null;
      }

      final copia = await arquivo.copy(novoLocal);
      return copia;
    } catch (e) {
      return null;
    }
  }
}

/// Informações sobre imagem
class ImageInfo {
  final String caminho;
  final int tamanhoBytes;
  final double tamanhoMB;
  final String extensao;
  final String nomeArquivo;

  ImageInfo({
    required this.caminho,
    required this.tamanhoBytes,
    required this.tamanhoMB,
    required this.extensao,
    required this.nomeArquivo,
  });

  @override
  String toString() {
    return 'ImageInfo: $nomeArquivo (${tamanhoMB.toStringAsFixed(2)} MB)';
  }
}
