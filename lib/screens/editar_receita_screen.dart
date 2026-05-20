import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/receita.dart';
import '../providers/receita_provider.dart';
import '../utils/app_colors.dart';

/// Tela de edição de receita.
class EditarReceitaScreen extends StatefulWidget {
  const EditarReceitaScreen({super.key});

  @override
  State<EditarReceitaScreen> createState() => _EditarReceitaScreenState();
}

class _EditarReceitaScreenState extends State<EditarReceitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final List<TextEditingController> _quantidadeControllers = [];
  final List<TextEditingController> _ingredienteControllers = [];
  final List<TextEditingController> _gramasControllers = [];
  final _modoPreparoController = TextEditingController();
  final List<TextEditingController> _passoControllers = [];
  final List<Uint8List> _imagens = [];
  final ImagePicker _picker = ImagePicker();
  AcessoReceita _acesso = AcessoReceita.privada;
  late String _receitaId;
  bool _dadosCarregados = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dadosCarregados) {
      _carregarDadosReceita();
      _dadosCarregados = true;
    }
  }

  bool get _cameraDisponivel {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  void _carregarDadosReceita() {
    _receitaId = ModalRoute.of(context)!.settings.arguments as String;
    final provider = context.read<ReceitaProvider>();
    final receita = provider.buscarPorId(_receitaId);

    if (receita != null) {
      _nomeController.text = receita.nome;
      _modoPreparoController.text = receita.modoPreparo;
      _imagens.addAll(receita.imagens);
      _acesso = receita.acesso;

      // Parse ingredientes
      final linhas = receita.ingredientes.split('\n');
      for (var linha in linhas) {
        if (linha.trim().isEmpty) continue;

        String qtde = '';
        String ingr = linha.trim();
        String gram = '';

        final partes = linha.split(' - ');
        if (partes.length == 3) {
          qtde = partes[0].trim();
          ingr = partes[1].trim();
          gram = partes[2].trim().replaceAll('g', '');
        } else if (partes.length == 2) {
          qtde = partes[0].trim();
          ingr = partes[1].trim();
        }

        _quantidadeControllers.add(TextEditingController(text: qtde));
        _ingredienteControllers.add(TextEditingController(text: ingr));
        _gramasControllers.add(TextEditingController(text: gram));
      }

      if (_quantidadeControllers.isEmpty) {
        _adicionarIngrediente();
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    for (var controller in _quantidadeControllers) {
      controller.dispose();
    }
    for (var controller in _ingredienteControllers) {
      controller.dispose();
    }
    for (var controller in _gramasControllers) {
      controller.dispose();
    }
    _modoPreparoController.dispose();
    super.dispose();
  }

  Future<void> _mostrarOpcoesImagem() async {
    final escolha = await showDialog<ImageSource>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecionar imagem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_cameraDisponivel)
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Câmera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              if (!_cameraDisponivel)
                const ListTile(
                  leading: Icon(Icons.camera_alt_outlined),
                  title: Text('Câmera indisponível neste dispositivo'),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (escolha != null) {
      await _selecionarImagem(escolha);
    }
  }

  Future<void> _selecionarImagem(ImageSource source) async {
    if (_imagens.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Limite máximo de 5 imagens atingido!'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    if (source == ImageSource.camera && !_cameraDisponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A câmera não está disponível neste dispositivo.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    try {
      final XFile? imagem = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (imagem != null) {
        final bytes = await imagem.readAsBytes();
        if (!mounted) return;
        setState(() {
          _imagens.add(bytes);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  void _removerImagem(int index) {
    setState(() {
      _imagens.removeAt(index);
    });
  }

  Future<void> _salvarEdicao() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<ReceitaProvider>();
      final receitaExistente = provider.buscarPorId(_receitaId);

      if (receitaExistente != null) {
        // Construir string de ingredientes
        final ingredientes = _quantidadeControllers
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final quantidade = entry.value.text.trim();
              final ingrediente = _ingredienteControllers[index].text.trim();
              final gramas = _gramasControllers[index].text.trim();

              if (quantidade.isNotEmpty && ingrediente.isNotEmpty) {
                if (gramas.isNotEmpty) {
                  return '$quantidade - $ingrediente - ${gramas}g';
                }
                return '$quantidade - $ingrediente';
              }
              return '';
            })
            .where((item) => item.isNotEmpty)
            .join('\n');

        // Construir string de modo de preparo
        final modoPreparo = _passoControllers
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final passo = entry.value.text.trim();

              if (passo.isNotEmpty) {
                return '${index + 1}. $passo';
              }
              return '';
            })
            .where((item) => item.isNotEmpty)
            .join('\n');

        final receitaEditada = receitaExistente.copiar(
          nome: _nomeController.text.trim(),
          imagens: List<Uint8List>.from(_imagens),
          ingredientes: ingredientes,
          modoPreparo: modoPreparo,
          acesso: _acesso,
        );

        await provider.editarReceita(receitaEditada);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receita atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Receita',
          style: TextStyle(
            color: AppColors.branco,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.preto,
        iconTheme: const IconThemeData(color: AppColors.branco),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.branco, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: _salvarEdicao,
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: AppColors.dourado,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
              // Nome
              _buildCampoTexto(
                controller: _nomeController,
                rotulo: 'Nome da Receita',
                dica: 'Ex: Bolo de Chocolate',
                icone: Icons.restaurant_menu,
                obrigatorio: true,
                maxLinhas: 1,
              ),
              const SizedBox(height: 20),

              // Acesso
              _buildSeletorAcesso(),
              const SizedBox(height: 20),

              // Imagens
              _buildSecaoImagens(),
              const SizedBox(height: 20),

              // Ingredientes
              _buildSecaoIngredientes(),
              const SizedBox(height: 20),

              // Modo de preparo
              _buildSecaoModoPreparo(),
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
                subtitle: const Text(
                  'Apenas você',
                  style: TextStyle(fontSize: 12),
                ),
                value: AcessoReceita.privada,
                // ignore: deprecated_member_use
                groupValue: _acesso,
                activeColor: AppColors.vermelho,
                contentPadding: EdgeInsets.zero,
                // ignore: deprecated_member_use
                onChanged: (valor) {
                  setState(() => _acesso = valor!);
                },
              ),
            ),
            Expanded(
              child: RadioListTile<AcessoReceita>(
                title: const Text('Pública'),
                subtitle: const Text(
                  'Todos podem ver',
                  style: TextStyle(fontSize: 12),
                ),
                value: AcessoReceita.publica,
                // ignore: deprecated_member_use
                groupValue: _acesso,
                activeColor: AppColors.vermelho,
                contentPadding: EdgeInsets.zero,
                // ignore: deprecated_member_use
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
              const Text(
                ' *',
                style: TextStyle(color: AppColors.vermelho, fontSize: 16),
              ),
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
      onTap: _mostrarOpcoesImagem,
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

  void _adicionarIngrediente() {
    setState(() {
      _quantidadeControllers.add(TextEditingController());
      _ingredienteControllers.add(TextEditingController());
      _gramasControllers.add(TextEditingController());
    });
  }

  void _removerIngrediente(int index) {
    if (_quantidadeControllers.length > 1) {
      setState(() {
        _quantidadeControllers[index].dispose();
        _ingredienteControllers[index].dispose();
        _gramasControllers[index].dispose();

        _quantidadeControllers.removeAt(index);
        _ingredienteControllers.removeAt(index);
        _gramasControllers.removeAt(index);
      });
    }
  }

  Widget _buildSecaoIngredientes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.shopping_basket, color: AppColors.dourado, size: 20),
            SizedBox(width: 8),
            Text(
              'Ingredientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: AppColors.vermelho, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._quantidadeControllers.asMap().entries.map((entry) {
          final index = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _quantidadeControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Qtde',
                      hintStyle: TextStyle(
                        color: AppColors.cinza.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cinza),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.dourado,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    validator: (valor) {
                      if (index == 0 &&
                          (valor == null || valor.trim().isEmpty)) {
                        return 'Pelo menos um ingrediente é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _ingredienteControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Ingrediente',
                      hintStyle: TextStyle(
                        color: AppColors.cinza.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cinza),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.dourado,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    validator: (valor) {
                      if (index == 0 &&
                          (valor == null || valor.trim().isEmpty)) {
                        return 'Pelo menos um ingrediente é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ..._gramasControllers.asMap().entries.map((gEntry) {
                  final gIndex = gEntry.key;
                  if (gIndex == index) {
                    return SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _gramasControllers[gIndex],
                        decoration: InputDecoration(
                          hintText: 'Gramas',
                          hintStyle: TextStyle(
                            color: AppColors.cinza.withValues(alpha: 0.6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.cinza,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.dourado,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                if (_quantidadeControllers.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle,
                      color: AppColors.vermelho,
                    ),
                    onPressed: () => _removerIngrediente(index),
                  ),
              ],
            ),
          );
        }),
        ElevatedButton.icon(
          onPressed: _adicionarIngrediente,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Ingrediente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dourado,
            foregroundColor: AppColors.branco,
          ),
        ),
      ],
    );
  }

  void _adicionarPasso() {
    setState(() {
      _passoControllers.add(TextEditingController());
    });
  }

  void _removerPasso(int index) {
    if (_passoControllers.length > 1) {
      setState(() {
        _passoControllers[index].dispose();
        _passoControllers.removeAt(index);
      });
    }
  }

  Widget _buildSecaoModoPreparo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.restaurant, color: AppColors.dourado, size: 20),
            SizedBox(width: 8),
            Text(
              'Modo de Preparo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: AppColors.vermelho, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._passoControllers.asMap().entries.map((entry) {
          final index = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.dourado,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.branco,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _passoControllers[index],
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Descrição do passo',
                      hintStyle: TextStyle(
                        color: AppColors.cinza.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cinza),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.dourado,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    validator: (valor) {
                      if (index == 0 &&
                          (valor == null || valor.trim().isEmpty)) {
                        return 'Pelo menos um passo é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
                if (_passoControllers.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle,
                      color: AppColors.vermelho,
                    ),
                    onPressed: () => _removerPasso(index),
                  ),
              ],
            ),
          );
        }),
        ElevatedButton.icon(
          onPressed: _adicionarPasso,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Passo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dourado,
            foregroundColor: AppColors.branco,
          ),
        ),
      ],
    );
  }
}
