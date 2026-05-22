import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CadastroAnimalScreen extends StatefulWidget {
  const CadastroAnimalScreen({super.key});

  @override
  State<CadastroAnimalScreen> createState() => _CadastroAnimalScreenState();
}

class _CadastroAnimalScreenState extends State<CadastroAnimalScreen> {
  final _formKey = GlobalKey<FormState>();

  String _especieSelecionada = 'Bovino';
  String? _fotoUrl;
  double _eccValue = 3.0;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _registroIdController = TextEditingController();
  final TextEditingController _racaController = TextEditingController();
  final TextEditingController _linhagemController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _registroIdController.dispose();
    _racaController.dispose();
    _linhagemController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
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

  void _mostrarSeletorFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecionar Foto da Matriz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                  ),
                  title: const Text('Simular Câmera'),
                  subtitle: const Text('Tirar foto em tempo real no campo'),
                  onTap: () {
                    Navigator.pop(context);
                    _simularFoto('câmera');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
                  ),
                  title: const Text('Simular Galeria'),
                  subtitle: const Text('Escolher foto da galeria local'),
                  onTap: () {
                    Navigator.pop(context);
                    _simularFoto('galeria');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _simularFoto(String origem) {
    String url = 'https://images.unsplash.com/photo-1546445317-29f4545e6d51?q=80&w=800'; // bovino nelore
    if (_especieSelecionada.toLowerCase() == 'ovino') {
      url = 'https://images.unsplash.com/photo-1484557985045-edf25e08da73?q=80&w=800'; // ovino
    } else if (_especieSelecionada.toLowerCase() == 'caprino') {
      url = 'https://images.unsplash.com/photo-1524024973431-2ad916746881?q=80&w=800'; // caprino
    }

    setState(() {
      _fotoUrl = url;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Foto simulada com sucesso a partir da $origem!'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _salvarAnimal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> dadosInput = {
        'especie': _especieSelecionada,
        'raca': _racaController.text,
        'linhagem': _linhagemController.text.isNotEmpty ? _linhagemController.text : null,
        'idade_meses': int.parse(_idadeController.text),
        'nome': _nomeController.text.isNotEmpty ? _nomeController.text : null,
        'registro_id': _registroIdController.text.isNotEmpty ? _registroIdController.text : null,
        'peso': _pesoController.text.isNotEmpty ? double.parse(_pesoController.text) : null,
        'ecc': _eccValue,
        'foto_url': _fotoUrl,
      };

      await ApiService.criarAnimal(dadosInput);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Animal cadastrado com sucesso no AgroHub!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar animal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Cadastrar Matriz',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Fêmeas para controle reprodutivo',
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
                // 1. Dashed Image Box Simulation - Compact height for web/desktop
                GestureDetector(
                  onTap: _mostrarSeletorFoto,
                  child: SizedBox(
                    height: 150,
                    child: Stack(
                      children: [
                        if (_fotoUrl == null)
                          CustomPaint(
                            size: Size.infinite,
                            painter: DashedRectPainter(
                              color: const Color(0xFFB0BEC5),
                              strokeWidth: 1.5,
                              dashWidth: 6.0,
                              dashSpace: 4.0,
                              borderRadius: 16.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 40,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Adicionar Foto do Animal',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Toque para simular câmera ou galeria',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Image.network(
                                  _fotoUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.pets,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.7),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Alterar Foto da Matriz',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Identification and Zootécnico Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.assignment_ind_outlined, color: Color(0xFF2E7D32)),
                          SizedBox(width: 8),
                          Text(
                            'Ficha de Identificação',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.5),

                      // Nome da Matriz
                      _buildTextField(
                        controller: _nomeController,
                        label: 'Nome da Matriz',
                        hint: 'Ex: Mimosa, Estrela, Branca',
                        prefixIcon: Icons.pets_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Registro ID / Brinco
                      _buildTextField(
                        controller: _registroIdController,
                        label: 'Identificador / Brinco (Obrigatório)',
                        hint: 'Ex: ANM-0042, BR-7789',
                        prefixIcon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O identificador oficial/brinco é obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Espécie
                      _buildDropdown(
                        label: 'Espécie',
                        value: _especieSelecionada,
                        items: ['Bovino', 'Ovino', 'Caprino'],
                        onChanged: (value) {
                          setState(() {
                            _especieSelecionada = value!;
                            if (_fotoUrl != null) {
                              _simularFoto('atualização de espécie');
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Raça
                      _buildTextField(
                        controller: _racaController,
                        label: 'Raça',
                        hint: 'Ex: Nelore, Guzérá, Santa Inês',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Linhagem
                      _buildTextField(
                        controller: _linhagemController,
                        label: 'Linhagem (Opcional)',
                        hint: 'Ex: PO, POI, Mestiça',
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _idadeController,
                              label: 'Idade',
                              hint: 'Ex: 24',
                              keyboardType: TextInputType.number,
                              suffixText: 'meses',
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Obrigatório';
                                if (int.tryParse(value) == null) return 'Inválido';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _pesoController,
                              label: 'Peso Atual',
                              hint: 'Ex: 480',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              suffixText: 'kg',
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Obrigatório';
                                if (double.tryParse(value) == null) return 'Inválido';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Reative ECC visual card and slider
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
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
                                'Escore Corporal (ECC)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          // Reative ECC Status Badge
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getEccBgColor(_eccValue),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getEccColor(_eccValue).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${_eccValue.toStringAsFixed(2)} - ${_getEccStatus(_eccValue)}',
                              style: TextStyle(
                                color: _getEccColor(_eccValue),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.5),
                      const Text(
                        'Deslize para selecionar o status zootécnico corporal atual:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _eccValue,
                        min: 1.0,
                        max: 5.0,
                        divisions: 16,
                        activeColor: _getEccColor(_eccValue),
                        inactiveColor: _getEccColor(_eccValue).withValues(alpha: 0.2),
                        label: _eccValue.toStringAsFixed(2),
                        onChanged: (newValue) {
                          setState(() {
                            _eccValue = newValue;
                          });
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Caquético\n(1.0)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Ideal\n(3.5)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Obeso\n(5.0)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 4. Save and Cancel actions
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _salvarAnimal,
                          icon: const Icon(Icons.save_outlined),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          label: const Text(
                            'Salvar',
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
                          'Salvando dados no AgroHub...',
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ],
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

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
  }
}
