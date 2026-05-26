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

class _EditarReceitaScreenState extends State<EditarReceitaScreen>
    with TickerProviderStateMixin {
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

  late final AnimationController _entradaController;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _entradaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entradaController.forward();
    });
  }

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
    _entradaController.dispose();
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
    final escolha = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cinza.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Selecionar imagem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.preto,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Escolha de onde deseja carregar a foto',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.cinza.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 20),
              _OpcaoImagem(
                icone: Icons.photo_camera_rounded,
                titulo: 'Câmera',
                subtitulo: _cameraDisponivel
                    ? 'Tirar uma nova foto agora'
                    : 'Câmera indisponível neste dispositivo',
                habilitado: _cameraDisponivel,
                onTap: _cameraDisponivel
                    ? () => Navigator.pop(context, ImageSource.camera)
                    : null,
              ),
              const SizedBox(height: 10),
              _OpcaoImagem(
                icone: Icons.photo_library_rounded,
                titulo: 'Galeria',
                subtitulo: 'Selecionar uma imagem existente',
                habilitado: true,
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.cinza,
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
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
        _buildSnack('Limite máximo de 5 imagens atingido!',
            cor: AppColors.vermelho),
      );
      return;
    }

    if (source == ImageSource.camera && !_cameraDisponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnack('A câmera não está disponível neste dispositivo.',
            cor: AppColors.vermelho),
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
        _buildSnack('Erro ao selecionar imagem: $e', cor: AppColors.vermelho),
      );
    }
  }

  SnackBar _buildSnack(String mensagem, {required Color cor}) {
    return SnackBar(
      content: Text(mensagem),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
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
        setState(() => _salvando = true);

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
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnack('Receita atualizada com sucesso!', cor: AppColors.verde),
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 720;
    final horizontalPadding = isWide ? 32.0 : 16.0;
    final maxContentWidth = isWide ? 880.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.preto,
                Color(0xFF2E1B1B),
                AppColors.vermelhoEscuro,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            title: const Text(
              'Editar Receita',
              style: TextStyle(
                color: AppColors.branco,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.branco),
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: _salvando ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.branco, fontSize: 15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: TextButton(
                  onPressed: _salvando ? null : _salvarEdicao,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.dourado,
                    foregroundColor: AppColors.preto,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.preto,
                            ),
                          ),
                        )
                      : const Text(
                          'Salvar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.dourado.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.vermelho.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    32,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroHeader(),
                        const SizedBox(height: 20),
                        _animar(0, _buildCard(child: _buildCampoNome())),
                        const SizedBox(height: 16),
                        _animar(1, _buildCard(child: _buildSeletorAcesso())),
                        const SizedBox(height: 16),
                        _animar(2, _buildCard(child: _buildSecaoImagens())),
                        const SizedBox(height: 16),
                        _animar(
                          3,
                          _buildCard(
                            child: _buildSecaoIngredientes(isWide: isWide),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _animar(
                          4,
                          _buildCard(child: _buildSecaoModoPreparo()),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animar(int index, Widget child) {
    final start = (index * 0.08).clamp(0.0, 0.9);
    final end = (start + 0.5).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _entradaController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 18),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.preto,
            Color(0xFF3A2222),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.preto.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.dourado, Color(0xFFB8860B)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dourado.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.branco,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar receita',
                  style: TextStyle(
                    color: AppColors.branco,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Atualize as informações da sua receita',
                  style: TextStyle(
                    color: AppColors.branco.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.cinza.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.preto.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required IconData icone,
    required String titulo,
    String? sufixo,
    bool obrigatorio = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.dourado.withValues(alpha: 0.18),
                AppColors.douradoClaro.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: AppColors.dourado, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (obrigatorio)
                const Padding(
                  padding: EdgeInsets.only(left: 2, bottom: 2),
                  child: Text(
                    '*',
                    style: TextStyle(
                      color: AppColors.vermelho,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (sufixo != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 2),
                  child: Text(
                    sufixo,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.cinza.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCampoNome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icone: Icons.restaurant_menu_rounded,
          titulo: 'Nome da Receita',
          obrigatorio: true,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _nomeController,
          maxLines: 1,
          style: const TextStyle(fontSize: 15, color: AppColors.preto),
          decoration: _inputDecoration(
            dica: 'Ex: Bolo de Chocolate',
            prefix: const Icon(
              Icons.edit_outlined,
              color: AppColors.dourado,
              size: 20,
            ),
          ),
          validator: (valor) {
            if (valor == null || valor.trim().isEmpty) {
              return 'Este campo é obrigatório';
            }
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String dica,
    Widget? prefix,
    EdgeInsetsGeometry? padding,
  }) {
    return InputDecoration(
      hintText: dica,
      hintStyle: TextStyle(
        color: AppColors.cinza.withValues(alpha: 0.55),
        fontSize: 14,
      ),
      prefixIcon: prefix,
      filled: true,
      fillColor: const Color(0xFFFAF8F3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: AppColors.cinza.withValues(alpha: 0.25), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: AppColors.cinza.withValues(alpha: 0.2), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.dourado, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.vermelho, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.vermelho, width: 2),
      ),
      contentPadding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSeletorAcesso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icone: Icons.shield_outlined,
          titulo: 'Visibilidade',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final children = [
              Expanded(
                child: _AcessoOpcao(
                  selecionado: _acesso == AcessoReceita.privada,
                  icone: Icons.lock_outline_rounded,
                  titulo: 'Privada',
                  subtitulo: 'Apenas você',
                  onTap: () =>
                      setState(() => _acesso = AcessoReceita.privada),
                ),
              ),
              SizedBox(width: isNarrow ? 0 : 12, height: isNarrow ? 12 : 0),
              Expanded(
                child: _AcessoOpcao(
                  selecionado: _acesso == AcessoReceita.publica,
                  icone: Icons.public_rounded,
                  titulo: 'Pública',
                  subtitulo: 'Todos podem ver',
                  onTap: () =>
                      setState(() => _acesso = AcessoReceita.publica),
                ),
              ),
            ];
            return isNarrow
                ? Column(children: children)
                : Row(children: children);
          },
        ),
      ],
    );
  }

  Widget _buildSecaoIngredientes({required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icone: Icons.shopping_basket_rounded,
          titulo: 'Ingredientes',
          obrigatorio: true,
        ),
        const SizedBox(height: 14),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              ..._quantidadeControllers.asMap().entries.map((entry) {
                final index = entry.key;
                return Padding(
                  key: ValueKey('ingrediente_$index'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildIngredienteRow(index, isWide: isWide),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _buildBotaoAdicionar(
          rotulo: 'Adicionar Ingrediente',
          onPressed: _adicionarIngrediente,
        ),
      ],
    );
  }

  Widget _buildIngredienteRow(int index, {required bool isWide}) {
    final removivel = _quantidadeControllers.length > 1;

    final qtde = TextFormField(
      controller: _quantidadeControllers[index],
      style: const TextStyle(fontSize: 14, color: AppColors.preto),
      decoration: _inputDecoration(
        dica: 'Qtde',
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      ),
      validator: (valor) {
        if (index == 0 && (valor == null || valor.trim().isEmpty)) {
          return 'Obrigatório';
        }
        return null;
      },
    );

    final ingrediente = TextFormField(
      controller: _ingredienteControllers[index],
      style: const TextStyle(fontSize: 14, color: AppColors.preto),
      decoration: _inputDecoration(
        dica: 'Ingrediente',
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (valor) {
        if (index == 0 && (valor == null || valor.trim().isEmpty)) {
          return 'Obrigatório';
        }
        return null;
      },
    );

    final gramas = TextFormField(
      controller: _gramasControllers[index],
      style: const TextStyle(fontSize: 14, color: AppColors.preto),
      decoration: _inputDecoration(
        dica: 'Gramas',
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      ),
    );

    final botaoRemover = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: removivel ? 1 : 0,
      child: IgnorePointer(
        ignoring: !removivel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _removerIngrediente(index),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.vermelho.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.vermelho,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: qtde),
          const SizedBox(width: 8),
          Expanded(child: ingrediente),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: gramas),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: botaoRemover,
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F3).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cinza.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.dourado.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dourado,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: ingrediente),
              const SizedBox(width: 6),
              botaoRemover,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 34),
              Expanded(child: qtde),
              const SizedBox(width: 8),
              Expanded(child: gramas),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoModoPreparo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icone: Icons.menu_book_rounded,
          titulo: 'Modo de Preparo',
          obrigatorio: true,
        ),
        const SizedBox(height: 14),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              ..._passoControllers.asMap().entries.map((entry) {
                final index = entry.key;
                return Padding(
                  key: ValueKey('passo_$index'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPassoRow(index),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _buildBotaoAdicionar(
          rotulo: 'Adicionar Passo',
          onPressed: _adicionarPasso,
        ),
      ],
    );
  }

  Widget _buildPassoRow(int index) {
    final removivel = _passoControllers.length > 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.dourado, Color(0xFFB8860B)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.dourado.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.branco,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _passoControllers[index],
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.preto,
              height: 1.4,
            ),
            decoration: _inputDecoration(
              dica: 'Descreva este passo do preparo...',
            ),
            validator: (valor) {
              if (index == 0 && (valor == null || valor.trim().isEmpty)) {
                return 'Pelo menos um passo é obrigatório';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 6),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: removivel ? 1 : 0,
          child: IgnorePointer(
            ignoring: !removivel,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _removerPasso(index),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.vermelho.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.vermelho,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoAdicionar({
    required String rotulo,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.dourado.withValues(alpha: 0.12),
                AppColors.douradoClaro.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.dourado.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.dourado,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                rotulo,
                style: const TextStyle(
                  color: Color(0xFFB8860B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecaoImagens() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icone: Icons.photo_library_rounded,
          titulo: 'Imagens',
          sufixo: '(opcional, máx. 5)',
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Text(
            '${_imagens.length}/5 imagens adicionadas',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.cinza.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.preto.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              bytesImagem,
              width: 104,
              height: 104,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _removerImagem(index),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.vermelho,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.vermelho.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.branco,
                  size: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoAdicionarImagem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _mostrarOpcoesImagem,
        child: Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.douradoClaro.withValues(alpha: 0.5),
                AppColors.dourado.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.dourado.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_rounded,
                color: AppColors.dourado,
                size: 32,
              ),
              SizedBox(height: 6),
              Text(
                'Adicionar',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB8860B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
}

class _AcessoOpcao extends StatelessWidget {
  final bool selecionado;
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _AcessoOpcao({
    required this.selecionado,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            gradient: selecionado
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.vermelho,
                      AppColors.vermelhoEscuro,
                    ],
                  )
                : null,
            color: selecionado ? null : const Color(0xFFFAF8F3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selecionado
                  ? AppColors.vermelho
                  : AppColors.cinza.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: selecionado
                ? [
                    BoxShadow(
                      color: AppColors.vermelho.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selecionado
                      ? AppColors.branco.withValues(alpha: 0.18)
                      : AppColors.dourado.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icone,
                  color:
                      selecionado ? AppColors.branco : AppColors.dourado,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: selecionado
                            ? AppColors.branco
                            : AppColors.preto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: selecionado
                            ? AppColors.branco.withValues(alpha: 0.85)
                            : AppColors.cinza,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selecionado
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(selecionado),
                  color: selecionado
                      ? AppColors.branco
                      : AppColors.cinza.withValues(alpha: 0.45),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcaoImagem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final bool habilitado;
  final VoidCallback? onTap;

  const _OpcaoImagem({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Opacity(
          opacity: habilitado ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cinza.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.dourado.withValues(alpha: 0.2),
                        AppColors.douradoClaro.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: AppColors.dourado, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.preto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.cinza.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (habilitado)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.dourado,
                    size: 14,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
