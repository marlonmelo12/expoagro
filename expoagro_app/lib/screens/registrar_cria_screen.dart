import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';

class RegistrarCriaScreen extends StatefulWidget {
  final Map<String, dynamic> mae;

  const RegistrarCriaScreen({super.key, required this.mae});

  @override
  State<RegistrarCriaScreen> createState() => _RegistrarCriaScreenState();
}

class _RegistrarCriaScreenState extends State<RegistrarCriaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _registroIdController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _racaController = TextEditingController();
  final TextEditingController _linhagemController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _detalhesController = TextEditingController();

  String _sexoSelecionado = 'Fêmea'; // Fêmea ou Macho
  double _eccInicial = 3.0;

  @override
  void initState() {
    super.initState();
    // Sugere a raça e linhagem da mãe para a cria
    _racaController.text = widget.mae['raca'] ?? '';
    _linhagemController.text = widget.mae['linhagem'] ?? '';
    _detalhesController.text = 'Parto normal, cria saudável.';
  }

  @override
  void dispose() {
    _registroIdController.dispose();
    _nomeController.dispose();
    _racaController.dispose();
    _linhagemController.dispose();
    _pesoController.dispose();
    _detalhesController.dispose();
    super.dispose();
  }

  String _getEccStatus(double value) {
    if (value < 2.0) return 'CAQUÉTICO';
    if (value < 2.75) return 'MAGRO';
    if (value < 3.75) return 'IDEAL';
    if (value < 4.5) return 'GORDO';
    return 'OBESO';
  }

  Color _getEccColor(double value) {
    if (value < 2.0) return Colors.red.shade700;
    if (value < 2.75) return Colors.amber.shade700;
    if (value < 3.75) return const Color(0xFF2E7D32);
    if (value < 4.5) return Colors.blue.shade700;
    return Colors.purple.shade700;
  }

  Color _getEccBgColor(double value) {
    if (value < 2.0) return Colors.red.shade50;
    if (value < 2.75) return Colors.amber.shade50;
    if (value < 3.75) return const Color(0xFFE8F5E9);
    if (value < 4.5) return Colors.blue.shade50;
    return Colors.purple.shade50;
  }

  Future<void> _salvarParto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final hoje = DateTime.now().toIso8601String().split('T')[0];

    try {
      final payload = {
        "data_parto": hoje,
        "detalhes": _detalhesController.text,
        "cria": {
          "registro_id": _registroIdController.text.isNotEmpty ? _registroIdController.text : null,
          "nome": _nomeController.text.isNotEmpty ? _nomeController.text : null,
          "especie": widget.mae['especie'] ?? 'Bovino',
          "raca": _racaController.text,
          "linhagem": _linhagemController.text.isNotEmpty ? _linhagemController.text : null,
          "data_nascimento": hoje,
          "status_reprodutivo": "Vazia",
          "peso": _pesoController.text.isNotEmpty ? double.parse(_pesoController.text) : null,
          "ecc": _eccInicial,
          "fazenda": widget.mae['fazenda'] ?? "Fazenda Única", // herda a fazenda obrigatoriamente
          "sexo": _sexoSelecionado,
          "foto_url": null,
        }
      };

      // Dispara a criação da cria e mudança de status da mãe no backend
      await ApiService.registrarParto(widget.mae['id'], payload);

      setState(() => _isLoading = false);

      if (mounted) {
        // Exibe tela de confirmação premium customizada
        _mostrarConfirmacaoSucesso();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar parto e cria: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _mostrarConfirmacaoSucesso() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final criaBrinco = _registroIdController.text.isNotEmpty ? _registroIdController.text : 'Sem brinco';
        final criaNome = _nomeController.text.isNotEmpty ? _nomeController.text : 'Cria sem nome';
        final especie = widget.mae['especie'] ?? 'Bovino';

        dynamic animalIcon = FontAwesomeIcons.cow;
        if (especie.toLowerCase() == 'ovino') animalIcon = FontAwesomeIcons.paw;
        if (especie.toLowerCase() == 'caprino') animalIcon = FontAwesomeIcons.paw;


        return BackdropFilter(
          filter: ColorFilter.mode(Colors.black.withValues(alpha: 0.1), BlendMode.dstOver),
          child: ScaleTransition(
            scale: anim1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E7D32),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Parto Registrado!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A matriz "${widget.mae['nome'] ?? widget.mae['registro_id']}" agora está com o status Lactante.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Certificado visual da cria
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FaIcon(animalIcon, size: 18, color: const Color(0xFF2E7D32)),
                            const SizedBox(width: 8),
                            const Text(
                              'FICHA DA CRIA CADASTRADA',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _buildDialogRow('Identificação', criaBrinco),
                        _buildDialogRow('Nome / Apelido', criaNome),
                        _buildDialogRow('Sexo da Cria', _sexoSelecionado),
                        _buildDialogRow('Raça', _racaController.text),
                        if (_pesoController.text.isNotEmpty)
                          _buildDialogRow('Peso ao Nascer', '${_pesoController.text} kg'),
                        _buildDialogRow('Data de Nasc.', DateTime.now().toIso8601String().split('T')[0]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        // Fecha o dialog de sucesso
                        Navigator.pop(context);
                        // Fecha a tela de cadastro retornando true para recarregar a tela de detalhes da mãe
                        Navigator.pop(context, true);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Voltar ao Perfil da Matriz',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final especie = widget.mae['especie'] ?? 'Bovino';
    dynamic maeIcon = FontAwesomeIcons.cow;
    if (especie.toLowerCase() == 'ovino') maeIcon = FontAwesomeIcons.paw;
    if (especie.toLowerCase() == 'caprino') maeIcon = FontAwesomeIcons.paw;


    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar Parto e Cria',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Nascimento e cadastro de filhote no rebanho',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Card da Mãe (Matriz)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(maeIcon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MATRIZ / MÃE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.mae['nome'] ?? 'Brinco: ${widget.mae['registro_id']}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            if (widget.mae['nome'] != null)
                              Text(
                                'Identificação: ${widget.mae['registro_id']}',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card de Detalhes do Parto
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: Color(0xFF2E7D32)),
                          SizedBox(width: 8),
                          Text(
                            'Informações do Parto',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.5),

                      // Data do Parto (Travada no dia de hoje)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data do Parto (Nascimento da Cria)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available, color: Colors.grey),
                                const SizedBox(width: 12),
                                Text(
                                  DateTime.now().toLocal().toString().split(' ')[0].split('-').reversed.join('/'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'HOJE',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Detalhes do Parto
                      _buildTextField(
                        controller: _detalhesController,
                        label: 'Observações sobre o Parto',
                        hint: 'Ex: Parto fácil, simples, sem auxílio veterinário.',
                        prefixIcon: Icons.description_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card de Identificação da Cria
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.child_care, color: Color(0xFF2E7D32)),
                          SizedBox(width: 8),
                          Text(
                            'Dados da Cria (Filhote)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.5),

                      // Brinco da Cria (Obrigatório)
                      _buildTextField(
                        controller: _registroIdController,
                        label: 'Identificador / Brinco da Cria (Obrigatório)',
                        hint: 'Ex: CRI-${widget.mae['registro_id']}-01',
                        prefixIcon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O brinco da cria é obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Nome da Cria
                      _buildTextField(
                        controller: _nomeController,
                        label: 'Nome da Cria (Apelido - Opcional)',
                        hint: 'Ex: Mimosinho, Estrelinha',
                        prefixIcon: Icons.pets_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Sexo da Cria (Chips Selecionáveis)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sexo da Cria',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: ['Fêmea', 'Macho'].map((sexo) {
                              final isSelected = _sexoSelecionado == sexo;
                              final icon = sexo == 'Fêmea' ? Icons.female : Icons.male;
                              final color = sexo == 'Fêmea' ? Colors.pink : Colors.blue;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ChoiceChip(
                                    label: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(icon, size: 18, color: isSelected ? Colors.white : color),
                                        const SizedBox(width: 8),
                                        Text(sexo),
                                      ],
                                    ),
                                    selected: isSelected,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    selectedColor: color,
                                    backgroundColor: Colors.grey[100],
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _sexoSelecionado = sexo);
                                      }
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          // Raça
                          Expanded(
                            child: _buildTextField(
                              controller: _racaController,
                              label: 'Raça da Cria',
                              hint: 'Nelore',
                              validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Linhagem
                          Expanded(
                            child: _buildTextField(
                              controller: _linhagemController,
                              label: 'Linhagem (Opcional)',
                              hint: 'PO',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Peso ao Nascer
                      _buildTextField(
                        controller: _pesoController,
                        label: 'Peso ao Nascer (Opcional)',
                        hint: 'Ex: 35',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        suffixText: 'kg',
                        prefixIcon: Icons.fitness_center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Slider de ECC inicial da cria
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.assessment_outlined, color: Color(0xFF2E7D32)),
                              SizedBox(width: 8),
                              Text(
                                'ECC Inicial da Cria',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getEccBgColor(_eccInicial),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getEccColor(_eccInicial).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${_eccInicial.toStringAsFixed(2)} - ${_getEccStatus(_eccInicial)}',
                              style: TextStyle(color: _getEccColor(_eccInicial), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.5),
                      Slider(
                        value: _eccInicial,
                        min: 1.0,
                        max: 5.0,
                        divisions: 16,
                        activeColor: _getEccColor(_eccInicial),
                        inactiveColor: _getEccColor(_eccInicial).withValues(alpha: 0.2),
                        label: _eccInicial.toStringAsFixed(2),
                        onChanged: (newValue) {
                          setState(() {
                            _eccInicial = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Ações de Salvar e Cancelar
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
                          label: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _salvarParto,
                          icon: const Icon(Icons.save_outlined),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          label: const Text(
                            'Salvar Parto',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2E7D32)),
                        SizedBox(height: 20),
                        Text(
                          'Salvando Parto e Cria no AgroHub...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    String? suffixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF2E7D32), size: 20) : null,
            suffixText: suffixText,
            suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
