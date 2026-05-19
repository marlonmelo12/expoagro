import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Importando nosso serviço

class SimuladorScreen extends StatefulWidget {
  const SimuladorScreen({super.key});

  @override
  State<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends State<SimuladorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _especieSelecionada = 'Bovino';
  final TextEditingController _idadeController = TextEditingController();
  double _ecc = 3.0;
  int _tentativasPrevias = 0;
  final TextEditingController _indiceGeneticoController = TextEditingController();
  String _estacao = 'Chuva';
  final TextEditingController _diasPosParto = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _resultado;

  @override
  void dispose() {
    _idadeController.dispose();
    _indiceGeneticoController.dispose();
    _diasPosParto.dispose();
    super.dispose();
  }

  // --- AQUI ACONTECE A INTEGRAÇÃO REAL COM A API ---
  Future<void> _analisarViabilidade() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _resultado = null;
    });

    try {
      // 1. Monta os dados para o FastAPI
      Map<String, dynamic> dadosInput = {
        "especie": _especieSelecionada,
        "idade_meses": int.parse(_idadeController.text),
        "ecc": _ecc,
        "tentativas_previas": _tentativasPrevias,
        "indice_genetico_reprodutor": int.parse(_indiceGeneticoController.text),
        "estacao": _estacao,
        "dias_pos_parto": int.parse(_diasPosParto.text),
        "fazenda": "Fazenda_Expoagro"
      };

      // 2. Chama a IA
      final response = await ApiService.preverSucesso(dadosInput);

      // 3. Processa a resposta
      String probString = response['predicao']['probabilidade_sucesso'].toString().replaceAll('%', '');
      double probabilidadeFinal = double.parse(probString);

      setState(() {
        _isLoading = false;
        _resultado = {
          'probabilidade': probabilidadeFinal,
          'status': response['predicao']['classificacao'],
          'cor': probabilidadeFinal >= 70 ? Colors.green : 
                 probabilidadeFinal >= 50 ? Colors.orange : Colors.red,
          'recomendacao': response['predicao']['recomendacao'],
        };
      });

      _mostrarResultado();

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao conectar com a IA: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarResultado() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              _resultado!['probabilidade'] >= 70 
                  ? Icons.check_circle_outline 
                  : _resultado!['probabilidade'] >= 50
                  ? Icons.warning_amber_outlined
                  : Icons.cancel_outlined,
              size: 64,
              color: _resultado!['cor'],
            ),
            const SizedBox(height: 16),
            Text(
              _resultado!['status'],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _resultado!['cor'],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _resultado!['cor'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${_resultado!['probabilidade'].toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: _resultado!['cor'],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Probabilidade de Sucesso',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _resultado!['recomendacao'],
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E7D32),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulador de Viabilidade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Análise com Inteligência Artificial',
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
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Dados do Animal'),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Espécie',
                        value: _especieSelecionada,
                        items: ['Bovino', 'Ovino', 'Caprino'],
                        onChanged: (value) => setState(() => _especieSelecionada = value!),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _idadeController,
                        label: 'Idade (meses)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo obrigatório';
                          if (int.tryParse(value) == null) return 'Digite um número válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Escore de Condição Corporal (ECC)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('1.0', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Expanded(
                            child: Slider(
                              value: _ecc,
                              min: 1.0,
                              max: 5.0,
                              divisions: 40,
                              label: _ecc.toStringAsFixed(1),
                              onChanged: (value) => setState(() => _ecc = value),
                            ),
                          ),
                          Text('5.0', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ECC: ${_ecc.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown(
                        label: 'Tentativas Prévias de Inseminação',
                        value: _tentativasPrevias.toString(),
                        items: ['0', '1', '2', '3'],
                        onChanged: (value) => setState(() => 
                          _tentativasPrevias = int.parse(value!)),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _diasPosParto,
                        label: 'Dias Pós-Parto',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo obrigatório';
                          if (int.tryParse(value) == null) return 'Digite um número válido';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Dados do Sêmen'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _indiceGeneticoController,
                        label: 'Índice Genético (0 a 100)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo obrigatório';
                          final numero = int.tryParse(value);
                          if (numero == null || numero < 0 || numero > 100) return 'Digite um valor entre 0 e 100';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Condições Ambientais'),
                      const SizedBox(height: 16),
                      Text(
                        'Estação',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Seca',
                            label: Text('Seca'),
                            icon: Icon(Icons.wb_sunny_outlined),
                          ),
                          ButtonSegment(
                            value: 'Chuva',
                            label: Text('Chuva'),
                            icon: Icon(Icons.water_drop_outlined),
                          ),
                        ],
                        selected: {_estacao},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() => _estacao = newSelection.first);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _analisarViabilidade,
                    icon: const Icon(Icons.auto_awesome, size: 24),
                    label: const Text(
                      'Analisar Viabilidade com IA',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
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
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          'Analisando dados com IA...',
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

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
        ),
      ],
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
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}