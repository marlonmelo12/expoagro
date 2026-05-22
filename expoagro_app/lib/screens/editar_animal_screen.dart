import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditarAnimalScreen extends StatefulWidget {
  final Map<String, dynamic> animal;

  const EditarAnimalScreen({super.key, required this.animal});

  @override
  State<EditarAnimalScreen> createState() => _EditarAnimalScreenState();
}

class _EditarAnimalScreenState extends State<EditarAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nomeController;
  late final TextEditingController _registroIdController;
  late final TextEditingController _racaController;
  late final TextEditingController _linhagemController;
  late final TextEditingController _pesoController;
  late final TextEditingController _origemPaternaController;
  late String _especieSelecionada;
  late String _sexoSelecionado;
  late double _eccValue;

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    _nomeController = TextEditingController(text: a['nome'] ?? '');
    _registroIdController = TextEditingController(text: a['registro_id'] ?? '');
    _racaController = TextEditingController(text: a['raca'] ?? '');
    _linhagemController = TextEditingController(text: a['linhagem'] ?? '');
    _pesoController = TextEditingController(
        text: a['peso'] != null ? (a['peso'] as num).toStringAsFixed(1) : '');
    _origemPaternaController =
        TextEditingController(text: a['origem_paterna'] ?? '');
    _especieSelecionada = a['especie'] ?? 'Bovino';
    _sexoSelecionado = a['sexo'] ?? 'Fêmea';
    _eccValue = (a['ecc'] ?? 3.0).toDouble().clamp(1.0, 5.0);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _registroIdController.dispose();
    _racaController.dispose();
    _linhagemController.dispose();
    _pesoController.dispose();
    _origemPaternaController.dispose();
    super.dispose();
  }

  String _getEccStatus(double v) {
    if (v < 2.0) return 'CAQUÉTICO';
    if (v < 2.75) return 'MAGRO';
    if (v < 3.75) return 'IDEAL';
    if (v < 4.5) return 'GORDO';
    return 'OBESO';
  }

  Color _getEccColor(double v) {
    if (v < 2.0) return Colors.red.shade700;
    if (v < 2.75) return Colors.amber.shade700;
    if (v < 3.75) return const Color(0xFF2E7D32);
    if (v < 4.5) return Colors.blue.shade700;
    return Colors.purple.shade700;
  }

  Color _getEccBgColor(double v) {
    if (v < 2.0) return Colors.red.shade50;
    if (v < 2.75) return Colors.amber.shade50;
    if (v < 3.75) return const Color(0xFFE8F5E9);
    if (v < 4.5) return Colors.blue.shade50;
    return Colors.purple.shade50;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final dados = <String, dynamic>{};
    if (_nomeController.text.trim().isNotEmpty) dados['nome'] = _nomeController.text.trim();
    if (_registroIdController.text.trim().isNotEmpty) dados['registro_id'] = _registroIdController.text.trim();
    dados['especie'] = _especieSelecionada;
    dados['sexo'] = _sexoSelecionado;
    dados['raca'] = _racaController.text.trim();
    if (_linhagemController.text.trim().isNotEmpty) dados['linhagem'] = _linhagemController.text.trim();
    if (_pesoController.text.trim().isNotEmpty) dados['peso'] = double.tryParse(_pesoController.text.trim());
    dados['ecc'] = _eccValue;
    if (_origemPaternaController.text.trim().isNotEmpty) dados['origem_paterna'] = _origemPaternaController.text.trim();

    try {
      final updated = await ApiService.editarAnimal(widget.animal['id'], dados);
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Animal atualizado com sucesso!'),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context, updated);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF2E7D32), size: 20)
                : null,
            suffixText: suffixText,
            suffixStyle:
                const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar Matriz',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              widget.animal['nome'] ??
                  widget.animal['registro_id'] ??
                  'ID #${widget.animal['id']}',
              style:
                  const TextStyle(fontSize: 12, color: Colors.white70),
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
                // ── Identificação ────────────────────────────
                _sectionCard(
                  icon: Icons.assignment_ind_outlined,
                  title: 'Identificação',
                  children: [
                    _buildField(
                      controller: _nomeController,
                      label: 'Nome / Apelido',
                      hint: 'Ex: Mimosa',
                      icon: Icons.pets_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _registroIdController,
                      label: 'Registro / Brinco',
                      hint: 'Ex: ANM-0042',
                      icon: Icons.badge_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    // Espécie dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Espécie',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _especieSelecionada,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2E7D32), width: 2)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          items: ['Bovino', 'Ovino', 'Caprino']
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _especieSelecionada = v!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Sexo dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sexo',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _sexoSelecionado,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2E7D32), width: 2)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          items: ['Fêmea', 'Macho']
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _sexoSelecionado = v!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _racaController,
                      label: 'Raça',
                      hint: 'Ex: Nelore, Guzérá',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _linhagemController,
                      label: 'Linhagem (Opcional)',
                      hint: 'Ex: PO, POI, Mestiça',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Zootecnia ────────────────────────────────
                _sectionCard(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Dados Zootécnicos',
                  children: [
                    _buildField(
                      controller: _pesoController,
                      label: 'Peso Atual',
                      hint: 'Ex: 480',
                      icon: Icons.scale_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'kg',
                    ),
                    const SizedBox(height: 16),
                    // ECC slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Escore Corporal (ECC)',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getEccBgColor(_eccValue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_eccValue.toStringAsFixed(2)} — ${_getEccStatus(_eccValue)}',
                            style: TextStyle(
                                color: _getEccColor(_eccValue),
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _eccValue,
                      min: 1.0,
                      max: 5.0,
                      divisions: 16,
                      activeColor: _getEccColor(_eccValue),
                      inactiveColor: _getEccColor(_eccValue).withValues(alpha: 0.2),
                      label: _eccValue.toStringAsFixed(2),
                      onChanged: (v) => setState(() => _eccValue = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Genealogia ───────────────────────────────
                _sectionCard(
                  icon: Icons.family_restroom,
                  title: 'Genealogia',
                  children: [
                    _buildField(
                      controller: _origemPaternaController,
                      label: 'Origem Paterna',
                      hint: 'Ex: Genética 9872',
                      icon: Icons.male,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Botões ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancelar',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _salvar,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Salvar',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
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
              color: Colors.black38,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2E7D32)),
                        SizedBox(height: 16),
                        Text('Salvando alterações...',
                            style: TextStyle(fontWeight: FontWeight.w500)),
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

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32))),
          ]),
          const Divider(height: 20, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }
}
