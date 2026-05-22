import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'detalhes_screen.dart';

class SimuladorScreen extends StatefulWidget {
  final int indiceGeneticoReprodutor;
  final String especie;
  final String nomeReprodutor;

  const SimuladorScreen({
    super.key,
    required this.indiceGeneticoReprodutor,
    required this.especie,
    required this.nomeReprodutor,
  });

  @override
  State<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends State<SimuladorScreen> {
  String _estacao = 'Chuva';
  bool _isLoading = false;
  List<dynamic> _candidatas = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _buscarMelhoresMatrizes();
  }

  Future<void> _buscarMelhoresMatrizes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        "especie": widget.especie,
        "indice_genetico_reprodutor": widget.indiceGeneticoReprodutor,
        "estacao": _estacao,
      };

      final response = await ApiService.obterMelhoresCandidatas(payload);

      setState(() {
        _candidatas = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _getViabilityColor(double probability) {
    if (probability >= 70.0) return const Color(0xFF2E7D32); // Green
    if (probability >= 50.0) return const Color(0xFFF57C00); // Orange
    return const Color(0xFFD32F2F); // Red
  }

  Widget _buildBreederSummaryCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1B5E20),
              const Color(0xFF2E7D32).withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.biotech_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nomeReprodutor,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.especie} • Índice Genético: ${widget.indiceGeneticoReprodutor}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estação do Cruzamento',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'Chuva',
                  label: Text('Estação das Chuvas'),
                  icon: Icon(Icons.water_drop_rounded),
                ),
                ButtonSegment<String>(
                  value: 'Seca',
                  label: Text('Estação Seca'),
                  icon: Icon(Icons.wb_sunny_rounded),
                ),
              ],
              selected: {_estacao},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _estacao = newSelection.first;
                });
                _buscarMelhoresMatrizes();
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: const Color(0xFF2E7D32),
                selectedForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    String rankText = '#$rank';

    switch (rank) {
      case 1:
        badgeColor = const Color(0xFFFFC107); // Gold
        break;
      case 2:
        badgeColor = const Color(0xFFB0BEC5); // Silver
        break;
      case 3:
        badgeColor = const Color(0xFFFF8A65); // Bronze
        break;
      default:
        badgeColor = const Color(0xFF78909C); // Slate
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        rankText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _realizarInseminacao(Map<String, dynamic> candidata) async {
    final String cowName = candidata['nome'] ?? 'Matriz ID ${candidata['animal_id']}';
    final int cowId = candidata['animal_id'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.vaccines_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 10),
            Expanded(
              child: Text('Confirmar Inseminação'),
            ),
          ],
        ),
        content: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Deseja registrar a inseminação da matriz '),
              TextSpan(
                text: cowName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' com o reprodutor '),
              TextSpan(
                text: widget.nomeReprodutor,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final dados = {
        "data_inseminacao": DateTime.now().toIso8601String().split('T')[0],
        "ecc": (candidata['ecc'] as num).toDouble(),
        "tentativas_previas": 0,
        "indice_genetico_reprodutor": widget.indiceGeneticoReprodutor,
        "estacao": _estacao,
        "dias_pos_parto": 90,
      };

      await ApiService.registrarInseminacao(cowId, dados);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Inseminação de $cowName registrada com sucesso!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Fetch single animal complete profile & redirect to details page
      try {
        final rebanho = await ApiService.getAnimais();
        final animalCompleto = rebanho.firstWhere(
          (a) => a['id'] == cowId,
          orElse: () => null,
        );

        if (animalCompleto != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DetalhesScreen(animal: animalCompleto),
            ),
          );
        }
      } catch (e) {
        // Fail silently
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar inseminação: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildCowCard(Map<String, dynamic> candidata, int index) {
    final double probability = (candidata['probabilidade_sucesso'] as num).toDouble();
    final Color viabilityColor = _getViabilityColor(probability);
    final String cowName = candidata['nome'] ?? 'Matriz ID ${candidata['animal_id']}';
    final int cowId = candidata['animal_id'];
    final double ecc = (candidata['ecc'] as num).toDouble();
    final int idade = candidata['idade_meses'] as int;
    final String status = candidata['status'] ?? 'Indefinido';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildRankBadge(index + 1),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cowName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registro: #$cowId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildMetricPill('ECC', ecc.toStringAsFixed(1), Icons.fitness_center),
                          _buildMetricPill('Idade', '$idade m', Icons.calendar_today_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            value: probability / 100,
                            strokeWidth: 5.5,
                            backgroundColor: viabilityColor.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(viabilityColor),
                          ),
                        ),
                        Text(
                          '${probability.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: viabilityColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: viabilityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: viabilityColor.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: viabilityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _realizarInseminacao(candidata),
                icon: const Icon(Icons.vaccines_rounded, size: 18),
                label: const Text(
                  'Realizar Inseminação',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 60,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sentiment_dissatisfied_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma Matriz Disponível',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Não foram encontradas fêmeas da espécie "${widget.especie}" registradas no rebanho para cruzamento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[700]),
          const SizedBox(height: 16),
          Text(
            'Falha na Simulação',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Erro inesperado ao simular acasalamento.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.red[700]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _buscarMelhoresMatrizes,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar Novamente'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Limit to exactly 5 cows as requested
    final List<dynamic> top5Candidatas = _candidatas.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulador de Acasalamento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            Text(
              'Previsão de sucesso reprodutivo e acasalamento',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _buscarMelhoresMatrizes,
        color: const Color(0xFF2E7D32),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBreederSummaryCard(),
            const SizedBox(height: 16),
            _buildSeasonSelector(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top-5 Melhores Matrizes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                if (!_isLoading && _errorMessage == null && top5Candidatas.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Recomendado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              _buildSkeletonLoader()
            else if (_errorMessage != null)
              _buildErrorState()
            else if (top5Candidatas.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: top5Candidatas.length,
                itemBuilder: (context, index) {
                  final candidata = top5Candidatas[index] as Map<String, dynamic>;
                  return _buildCowCard(candidata, index);
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}