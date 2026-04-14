import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/receita.dart';
import '../providers/auth_provider.dart';
import '../providers/receita_provider.dart';
import '../utils/app_colors.dart';

/// Tela de cadastro de nova receita.
class CadastroReceitaScreen extends StatefulWidget {
  const CadastroReceitaScreen({super.key});

  @override
  State<CadastroReceitaScreen> createState() => _CadastroReceitaScreenState();
}

class _CadastroReceitaScreenState extends State<CadastroReceitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _ingredientesController = TextEditingController();
  final _modoPreparoController = TextEditingController();
  final List<Uint8List> _imagens = [];
  final ImagePicker _picker = ImagePicker();
  AcessoReceita _acesso = AcessoReceita.privada;

  @override
  void dispose() {
    _nomeController.dispose();
    _ingredientesController.dispose();
    _modoPreparoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    if (_imagens.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Limite máximo de 5 imagens atingido!'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    final XFile? imagem = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (imagem != null) {
      final bytes = await imagem.readAsBytes();
      setState(() {
        _imagens.add(bytes);
      });
    }
  }

  void _removerImagem(int index) {
    setState(() {
      _imagens.removeAt(index);
    });
  }

  Future<void> _salvarReceita() async {
    if (_formKey.currentState!.validate()) {
      final usuario = context.read<AuthProvider>().usuarioLogado;
      if (usuario == null) return;

      final novaReceita = Receita(
        nome: _nomeController.text.trim(),
        imagens: List<Uint8List>.from(_imagens),
        ingredientes: _ingredientesController.text.trim(),
        modoPreparo: _modoPreparoController.text.trim(),
        acesso: _acesso,
        proprietarioId: usuario.id,
      );

      await context.read<ReceitaProvider>().adicionarReceita(novaReceita);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receita cadastrada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nova Receita',
          style: TextStyle(
            color: AppColors.branco,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.preto,
        iconTheme: const IconThemeData(color: AppColors.branco),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.branco, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: _salvarReceita,
            child: const Text(
              'Salvar',
              style: TextStyle(color: AppColors.dourado, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome da receita
              _buildCampoTexto(
                controller: _nomeController,
                rotulo: 'Nome da Receita',
                dica: 'Ex: Bolo de Chocolate',
                icone: Icons.restaurant_menu,
                obrigatorio: true,
                maxLinhas: 1,
              ),
              const SizedBox(height: 20),

              // Acesso (pública ou privada)
              _buildSeletorAcesso(),
              const SizedBox(height: 20),

              // Imagens
              _buildSecaoImagens(),
              const SizedBox(height: 20),

              // Ingredientes
              _buildCampoTexto(
                controller: _ingredientesController,
                rotulo: 'Ingredientes',
                dica: 'Ex:\n- 2 xícaras de farinha\n- 3 ovos\n- 1 xícara de açúcar',
                icone: Icons.shopping_basket,
                obrigatorio: true,
                maxLinhas: 8,
              ),
              const SizedBox(height: 20),

              // Modo de preparo
              _buildCampoTexto(
                controller: _modoPreparoController,
                rotulo: 'Modo de Preparo',
                dica: 'Ex:\n1. Misture os ingredientes secos\n2. Adicione os ovos\n3. Leve ao forno',
                icone: Icons.restaurant,
                obrigatorio: true,
                maxLinhas: 10,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Seletor de acesso (pública/privada)
  Widget _buildSeletorAcesso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lock_open, color: AppColors.dourado, size: 20),
            SizedBox(width: 8),
            Text(
              'Acesso',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<AcessoReceita>(
                title: const Text('Privada'),
                subtitle: const Text('Apenas você', style: TextStyle(fontSize: 12)),
                value: AcessoReceita.privada,
                groupValue: _acesso,
                activeColor: AppColors.vermelho,
                contentPadding: EdgeInsets.zero,
                onChanged: (valor) {
                  setState(() => _acesso = valor!);
                },
              ),
            ),
            Expanded(
              child: RadioListTile<AcessoReceita>(
                title: const Text('Pública'),
                subtitle: const Text('Todos podem ver', style: TextStyle(fontSize: 12)),
                value: AcessoReceita.publica,
                groupValue: _acesso,
                activeColor: AppColors.vermelho,
                contentPadding: EdgeInsets.zero,
                onChanged: (valor) {
                  setState(() => _acesso = valor!);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String rotulo,
    required String dica,
    required IconData icone,
    required bool obrigatorio,
    int maxLinhas = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, color: AppColors.dourado, size: 20),
            const SizedBox(width: 8),
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
            if (obrigatorio)
              const Text(' *', style: TextStyle(color: AppColors.vermelho, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLinhas,
          decoration: InputDecoration(
            hintText: dica,
            hintStyle: TextStyle(color: AppColors.cinza.withValues(alpha: 0.6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cinza),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.dourado, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.vermelho),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: obrigatorio
              ? (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Este campo é obrigatório';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSecaoImagens() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.photo_library, color: AppColors.dourado, size: 20),
            SizedBox(width: 8),
            Text(
              'Imagens',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
            Text(
              ' (opcional, máx. 5)',
              style: TextStyle(fontSize: 14, color: AppColors.cinza),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._imagens.asMap().entries.map((entry) {
              return _buildImagemSelecionada(entry.key, entry.value);
            }),
            if (_imagens.length < 5) _buildBotaoAdicionarImagem(),
          ],
        ),
      ],
    );
  }

  Widget _buildImagemSelecionada(int index, Uint8List bytesImagem) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytesImagem,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removerImagem(index),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.vermelho,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: AppColors.branco, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoAdicionarImagem() {
    return GestureDetector(
      onTap: _selecionarImagem,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.douradoClaro,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dourado, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: AppColors.dourado, size: 32),
            SizedBox(height: 4),
            Text(
              'Adicionar',
              style: TextStyle(fontSize: 12, color: AppColors.dourado),
            ),
          ],
        ),
      ),
    );
  }
}
