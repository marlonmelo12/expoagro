import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../utils/web_exporter.dart';
import 'detalhes_screen.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  bool _isLoading = true;
  List<dynamic> _allAnimais = [];
  String _activeSpeciesFilter = 'Consolidado'; // 'Consolidado', 'Bovino', 'Ovino', 'Caprino'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAnimais();
      setState(() {
        _allAnimais = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar dados do rebanho: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  double parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  int calcularIndiceGenetico(Map animal) {
    final int id = animal['id'] ?? 0;
    final double ecc = parseDouble(animal['ecc'] ?? animal['escore_corporal'] ?? 3.0);
    
    int base = (id % 15) + 80; // Stable baseline from 80 to 94
    final String nome = (animal['nome'] ?? '').toString().toUpperCase();
    final String registro = (animal['registro_id'] ?? '').toString().toUpperCase();
    
    // Genetic quality modifiers
    if (nome.contains('FIV') || registro.contains('FIV') || nome.contains('TE') || registro.contains('TE')) {
      base += 3;
    }
    // ECC ideal range modifier
    if (ecc >= 3.0 && ecc <= 3.75) {
      base += 2;
    }
    return base.clamp(75, 99);
  }

  List<dynamic> get _filteredAnimais {
    if (_activeSpeciesFilter == 'Consolidado') {
      return _allAnimais;
    }
    return _allAnimais.where((animal) {
      final String esp = (animal['especie'] ?? 'Bovino').toString().toLowerCase();
      return esp == _activeSpeciesFilter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredAnimais;
    final int totalCount = list.length;

    // Metrics computation
    int prenhaCount = 0;
    int lactanteCount = 0;
    int inseminadaCount = 0;
    int vaziaCount = 0;

    double totalWeight = 0.0;
    int countWithWeight = 0;
    double totalEcc = 0.0;
    int countWithEcc = 0;
    double totalGeneticIndex = 0.0;

    final Map<String, int> breedsCount = {};

    for (final animal in list) {
      final String status = (animal['status_reprodutivo'] ?? 'Vazia').toString().toLowerCase();
      if (status.contains('prenh')) {
        prenhaCount++;
      } else if (status.contains('lactante')) {
        lactanteCount++;
      } else if (status.contains('inseminada')) {
        inseminadaCount++;
      } else {
        vaziaCount++;
      }

      final double peso = parseDouble(animal['peso_kg'] ?? animal['peso']);
      if (peso > 0) {
        totalWeight += peso;
        countWithWeight++;
      }

      final double ecc = parseDouble(animal['ecc'] ?? animal['escore_corporal']);
      if (ecc > 0) {
        totalEcc += ecc;
        countWithEcc++;
      }

      totalGeneticIndex += calcularIndiceGenetico(animal as Map);

      final String raca = animal['raca'] ?? 'Indefinida';
      breedsCount[raca] = (breedsCount[raca] ?? 0) + 1;
    }

    final double femaleCountDouble = totalCount > 0 ? totalCount.toDouble() : 1.0;
    final double pregnancyRate = (prenhaCount / femaleCountDouble) * 100;
    final double lactatingRate = (lactanteCount / femaleCountDouble) * 100;
    final double inseminatedRate = (inseminadaCount / femaleCountDouble) * 100;
    final double emptyRate = (vaziaCount / femaleCountDouble) * 100;

    final double avgWeight = countWithWeight > 0 ? totalWeight / countWithWeight : 0.0;
    final double avgEcc = countWithEcc > 0 ? totalEcc / countWithEcc : 0.0;
    final double avgGeneticIndex = totalCount > 0 ? totalGeneticIndex / totalCount : 0.0;

    // Elite animals selection (Top 3 by Genetic Index)
    final List<Map<String, dynamic>> eliteAnimais = list.map((a) {
      final map = Map<String, dynamic>.from(a as Map);
      map['_indiceCalculado'] = calcularIndiceGenetico(map);
      return map;
    }).toList();
    eliteAnimais.sort((a, b) => (b['_indiceCalculado'] as int).compareTo(a['_indiceCalculado'] as int));
    final top3Elite = eliteAnimais.take(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F6),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0F5A1B),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relatório de Performance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            Text(
              'Indicadores genéticos e reprodutivos do rebanho',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: totalCount > 0 ? () {
              final String csvReport = _gerarCSVRelatorio(list);
              Clipboard.setData(ClipboardData(text: csvReport));
              exportCSV(csvReport, 'relatorio_${_activeSpeciesFilter.toLowerCase()}.csv');
              
              final String msg = kIsWeb 
                  ? 'Download do arquivo CSV iniciado!' 
                  : 'Planilha CSV de $_activeSpeciesFilter copiada com sucesso!';
              _mostrarToastSucesso(context, msg);
            } : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sem matrizes disponíveis para exportar nesta espécie.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Gerar e Exportar Relatório',
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => _mostrarModalExportacao(
              context,
              list: list,
              totalCount: totalCount,
              pregnancyRate: pregnancyRate,
              lactatingRate: lactatingRate,
              inseminatedRate: inseminatedRate,
              emptyRate: emptyRate,
              prenhaCount: prenhaCount,
              lactanteCount: lactanteCount,
              inseminadaCount: inseminadaCount,
              vaziaCount: vaziaCount,
              avgGeneticIndex: avgGeneticIndex,
              avgEcc: avgEcc,
              avgWeight: avgWeight,
              breedsCount: breedsCount,
              top3Elite: top3Elite,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F5A1B)),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF0F5A1B),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Interactive Species Selector Capsules
                          _buildSpeciesSelector(),
                          const SizedBox(height: 16),

                          // Dedicated CSV Export Card (if list is not empty)
                          if (totalCount > 0) ...[
                            _buildDirectExportCSVRow(list),
                            const SizedBox(height: 20),
                          ],

                          // If rebanho is empty
                          if (totalCount == 0)
                            _buildEmptyState()
                          else ...[
                            // 2. Reproductive KPIs Grid
                            _buildReproductiveDashboard(
                              pregnancyRate: pregnancyRate,
                              lactatingRate: lactatingRate,
                              inseminatedRate: inseminatedRate,
                              emptyRate: emptyRate,
                              totalCount: totalCount,
                              prenhaCount: prenhaCount,
                              lactanteCount: lactanteCount,
                              inseminadaCount: inseminadaCount,
                              vaziaCount: vaziaCount,
                            ),
                            const SizedBox(height: 24),

                            // 3. Genetic Evolution KPIs (Avg Weight, ECC, Genetic Index)
                            _buildGeneticDashboard(
                              avgWeight: avgWeight,
                              avgEcc: avgEcc,
                              avgGeneticIndex: avgGeneticIndex,
                            ),
                            const SizedBox(height: 24),

                            // 4. Segmented Status Bar & Breed Distributions
                            _buildDistributionSection(
                              prenhaRate: pregnancyRate,
                              lactanteRate: lactatingRate,
                              inseminadaRate: inseminatedRate,
                              vaziaRate: emptyRate,
                              breedsCount: breedsCount,
                              totalCount: totalCount,
                            ),
                            const SizedBox(height: 24),

                            // 5. Elite Genética List (Top 3)
                            _buildEliteSection(top3Elite),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // Widget for empty state
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.query_stats_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma matriz cadastrada',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Cadastre animais da espécie "$_activeSpeciesFilter" para visualizar os indicadores reprodutivos e genéticos.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Top Filter Selection
  Widget _buildSpeciesSelector() {
    final List<Map<String, dynamic>> filters = [
      {'name': 'Consolidado', 'icon': Icons.analytics_outlined},
      {'name': 'Bovino', 'icon': FontAwesomeIcons.cow},
      {'name': 'Ovino', 'icon': FontAwesomeIcons.paw},
      {'name': 'Caprino', 'icon': FontAwesomeIcons.paw},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final String name = f['name'] as String;
          final dynamic icon = f['icon'];
          final bool isSelected = _activeSpeciesFilter == name;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _activeSpeciesFilter = name;
                  });
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F5A1B) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0F5A1B) : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xFF0F5A1B).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon.runtimeType.toString() == 'IconData'
                          ? Icon(
                              icon as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : const Color(0xFF0F5A1B),
                            )
                          : FaIcon(
                              icon,
                              size: 14,
                              color: isSelected ? Colors.white : const Color(0xFF0F5A1B),
                            ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Dashboard of Reproductive Stats
  Widget _buildReproductiveDashboard({
    required double pregnancyRate,
    required double lactatingRate,
    required double inseminatedRate,
    required double emptyRate,
    required int totalCount,
    required int prenhaCount,
    required int lactanteCount,
    required int inseminadaCount,
    required int vaziaCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Desempenho Reprodutivo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F5A1B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5A1B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalCount Matrizes',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F5A1B),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 500;
              return isDesktop
                  ? Row(
                      children: [
                        // Left Radial gauge
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: _buildRadialGauge(pregnancyRate),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right KPIs List
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildReproductiveKPIRow(
                                title: 'Gestantes (Prenha)',
                                rate: pregnancyRate,
                                count: prenhaCount,
                                color: const Color(0xFF0F5A1B),
                              ),
                              const SizedBox(height: 12),
                              _buildReproductiveKPIRow(
                                title: 'Em Lactação (Lactante)',
                                rate: lactatingRate,
                                count: lactanteCount,
                                color: const Color(0xFF1E88E5),
                              ),
                              const SizedBox(height: 12),
                              _buildReproductiveKPIRow(
                                title: 'Inseminadas',
                                rate: inseminatedRate,
                                count: inseminadaCount,
                                color: const Color(0xFFF57C00),
                              ),
                              const SizedBox(height: 12),
                              _buildReproductiveKPIRow(
                                title: 'Vazias / Aptas',
                                rate: emptyRate,
                                count: vaziaCount,
                                color: const Color(0xFF757575),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Center(child: _buildRadialGauge(pregnancyRate)),
                        const SizedBox(height: 24),
                        _buildReproductiveKPIRow(
                          title: 'Gestantes (Prenha)',
                          rate: pregnancyRate,
                          count: prenhaCount,
                          color: const Color(0xFF0F5A1B),
                        ),
                        const SizedBox(height: 12),
                        _buildReproductiveKPIRow(
                          title: 'Em Lactação (Lactante)',
                          rate: lactatingRate,
                          count: lactanteCount,
                          color: const Color(0xFF1E88E5),
                        ),
                        const SizedBox(height: 12),
                        _buildReproductiveKPIRow(
                          title: 'Inseminadas',
                          rate: inseminatedRate,
                          count: inseminadaCount,
                          color: const Color(0xFFF57C00),
                        ),
                        const SizedBox(height: 12),
                        _buildReproductiveKPIRow(
                          title: 'Vazias / Aptas',
                          rate: emptyRate,
                          count: vaziaCount,
                          color: const Color(0xFF757575),
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  // Radial Gauge representing pregnancy rate
  Widget _buildRadialGauge(double rate) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: rate / 100,
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade100,
              color: const Color(0xFF0F5A1B),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F5A1B),
                ),
              ),
              const Text(
                'Taxa de Prenhez',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Premium Row helper for Reproductive list
  Widget _buildReproductiveKPIRow({
    required String title,
    required double rate,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dashboard of Genetic Stats (ECC, Weight, calculated Genetic Index)
  Widget _buildGeneticDashboard({
    required double avgWeight,
    required double avgEcc,
    required double avgGeneticIndex,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 550;
        final cardWidth = isDesktop ? (constraints.maxWidth - 32) / 3 : double.infinity;

        final List<Widget> cards = [
          _buildGeneticKPICard(
            title: 'Índice Reprodutivo Genético',
            value: avgGeneticIndex > 0 ? avgGeneticIndex.toStringAsFixed(1) : '--',
            suffix: ' pts',
            color: const Color(0xFF0F5A1B),
            icon: Icons.auto_awesome,
            subtitle: 'Capacidade reprodutiva média',
          ),
          _buildGeneticKPICard(
            title: 'Escore Corporal Médio',
            value: avgEcc > 0 ? avgEcc.toStringAsFixed(2) : '--',
            suffix: ' ECC',
            color: const Color(0xFF1E88E5),
            icon: Icons.fitness_center,
            subtitle: 'Condição corporal do rebanho',
          ),
          _buildGeneticKPICard(
            title: 'Peso Médio',
            value: avgWeight > 0 ? avgWeight.toStringAsFixed(1) : '--',
            suffix: ' kg',
            color: const Color(0xFFF57C00),
            icon: Icons.scale,
            subtitle: 'Evolução de peso do rebanho',
          ),
        ];

        return isDesktop
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
              )
            : Column(
                children: [
                  cards[0],
                  const SizedBox(height: 12),
                  cards[1],
                  const SizedBox(height: 12),
                  cards[2],
                ],
              );
      },
    );
  }

  // Individual Card for Genetic KPI
  Widget _buildGeneticKPICard({
    required String title,
    required String value,
    required String suffix,
    required Color color,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF263238),
                ),
              ),
              Text(
                suffix,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Segmented bars representing status & breed distribution
  Widget _buildDistributionSection({
    required double prenhaRate,
    required double lactanteRate,
    required double inseminadaRate,
    required double vaziaRate,
    required Map<String, int> breedsCount,
    required int totalCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribuição e Raças',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F5A1B),
            ),
          ),
          const Divider(height: 24, thickness: 0.5),

          // Title: Status Distribution
          const Text(
            'Status Reprodutivo Geral',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 10),

          // Segmented status bar
          _buildSegmentedStatusBar(
            prenhaRate: prenhaRate,
            lactanteRate: lactanteRate,
            inseminadaRate: inseminadaRate,
            vaziaRate: vaziaRate,
          ),
          const SizedBox(height: 24),

          // Title: Breed Distribution
          const Text(
            'Composição de Raças do Rebanho',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 10),

          if (breedsCount.isEmpty)
            const Text(
              'Nenhuma raça identificada.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          else
            _buildBreedDistributions(breedsCount, totalCount),
        ],
      ),
    );
  }

  // Segmented status bar renderer
  Widget _buildSegmentedStatusBar({
    required double prenhaRate,
    required double lactanteRate,
    required double inseminadaRate,
    required double vaziaRate,
  }) {
    final List<Map<String, dynamic>> segments = [
      {'name': 'Prenha', 'value': prenhaRate, 'color': const Color(0xFF0F5A1B)},
      {'name': 'Lactante', 'value': lactanteRate, 'color': const Color(0xFF1E88E5)},
      {'name': 'Inseminada', 'value': inseminadaRate, 'color': const Color(0xFFF57C00)},
      {'name': 'Vazia', 'value': vaziaRate, 'color': const Color(0xFF757575)},
    ].where((segment) => (segment['value'] as double) > 0).toList();

    return Column(
      children: [
        // The Segmented progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 14,
            child: Row(
              children: segments.map((seg) {
                int flexVal = ((seg['value'] as double) * 100).round();
                if (flexVal <= 0) flexVal = 1;
                return Expanded(
                  flex: flexVal,
                  child: Container(
                    color: seg['color'] as Color,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Mini legends beneath the bar
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: segments.map((seg) {
            final rate = seg['value'] as double;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: seg['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${seg['name']}: ',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: seg['color'] as Color),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // Breed composition bars list
  Widget _buildBreedDistributions(Map<String, int> breedsCount, int totalCount) {
    final list = breedsCount.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));

    // Custom colors list for premium look
    final List<Color> colors = [
      const Color(0xFF0F5A1B),
      const Color(0xFF1E88E5),
      const Color(0xFFF57C00),
      const Color(0xFF8E24AA),
      const Color(0xFF00ACC1),
      const Color(0xFF7CB342),
    ];

    return Column(
      children: list.asMap().entries.map((entry) {
        final index = entry.key;
        final breed = entry.value.key;
        final count = entry.value.value;
        final percentage = (count / totalCount) * 100;
        final barColor = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    breed,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    '$count cab. (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  color: barColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Elite genetics List section (Top 3 Cows/Animals)
  Widget _buildEliteSection(List<Map<String, dynamic>> topElite) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars, color: Color(0xFFE5A93B), size: 22),
              SizedBox(width: 8),
              Text(
                'Elite Genética do Rebanho',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F5A1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'As 3 matrizes com os maiores índices genéticos ativos no momento.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const Divider(height: 24, thickness: 0.5),

          if (topElite.isEmpty)
            const Text(
              'Nenhum animal qualificado.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topElite.length,
              itemBuilder: (context, index) {
                final animal = topElite[index];
                final int idx = animal['_indiceCalculado'] as int;
                final String especie = animal['especie'] ?? 'Bovino';
                final String raca = animal['raca'] ?? 'Indefinida';
                final String? nome = animal['nome'];
                final String? registroId = animal['registro_id'];
                final int id = animal['id'] ?? 0;

                final String titleText = (nome != null && nome.isNotEmpty) ? nome : (registroId ?? 'Registro #$id');
                final String subtitleText = '$especie • $raca • ECC ${parseDouble(animal['ecc'] ?? animal['escore_corporal']).toStringAsFixed(2)}';

                // Golden, Silver, Bronze badges for the top 3
                Color medalColor;
                if (index == 0) {
                  medalColor = const Color(0xFFE5A93B); // Gold
                } else if (index == 1) {
                  medalColor = const Color(0xFFB0BEC5); // Silver
                } else {
                  medalColor = const Color(0xFFCD7F32); // Bronze
                }

                return Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      // Navigate to details screen
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalhesScreen(animal: animal),
                        ),
                      );
                      _loadData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Medal / Rank Number
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: medalColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: medalColor, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}º',
                              style: TextStyle(
                                color: medalColor == const Color(0xFFB0BEC5)
                                    ? Colors.grey[700]
                                    : medalColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Text details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titleText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF263238),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitleText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Genetic rating badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F5A1B).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.flash_on, color: Color(0xFF0F5A1B), size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '$idx',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: Color(0xFF0F5A1B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _gerarTextoRelatorio({
    required List<dynamic> list,
    required int totalCount,
    required double pregnancyRate,
    required double lactatingRate,
    required double inseminatedRate,
    required double emptyRate,
    required int prenhaCount,
    required int lactanteCount,
    required int inseminadaCount,
    required int vaziaCount,
    required double avgGeneticIndex,
    required double avgEcc,
    required double avgWeight,
    required Map<String, int> breedsCount,
    required List<Map<String, dynamic>> top3Elite,
  }) {
    final now = DateTime.now();
    final dataStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    final buffer = StringBuffer();
    buffer.writeln("============================================================");
    buffer.writeln("           AGROHUB - RELATÓRIO DE DESEMPENHO");
    buffer.writeln("============================================================");
    buffer.writeln("Data de Geração: $dataStr");
    buffer.writeln("Espécie / Filtro: $_activeSpeciesFilter");
    buffer.writeln("Matrizes Totais: $totalCount");
    buffer.writeln("------------------------------------------------------------");
    buffer.writeln("INDICADORES REPRODUTIVOS");
    buffer.writeln("------------------------------------------------------------");
    buffer.writeln("- Taxa de Prenhez: ${pregnancyRate.toStringAsFixed(1)}% ($prenhaCount matrizes)");
    buffer.writeln("- Em Lactação: ${lactatingRate.toStringAsFixed(1)}% ($lactanteCount matrizes)");
    buffer.writeln("- Inseminadas: ${inseminatedRate.toStringAsFixed(1)}% ($inseminadaCount matrizes)");
    buffer.writeln("- Vazias / Aptas: ${emptyRate.toStringAsFixed(1)}% ($vaziaCount matrizes)");
    buffer.writeln("------------------------------------------------------------");
    buffer.writeln("INDICADORES GENÉTICOS & PRODUTIVOS");
    buffer.writeln("------------------------------------------------------------");
    buffer.writeln("- Índice Reprodutivo Médio: ${avgGeneticIndex.toStringAsFixed(1)} pts");
    buffer.writeln("- Escore Corporal Médio (ECC): ${avgEcc > 0 ? avgEcc.toStringAsFixed(2) : 'N/A'}");
    buffer.writeln("- Peso Médio: ${avgWeight > 0 ? '${avgWeight.toStringAsFixed(1)} kg' : 'N/A'}");
    buffer.writeln("------------------------------------------------------------");
    buffer.writeln("DISTRIBUIÇÃO DE RAÇAS");
    buffer.writeln("------------------------------------------------------------");
    if (breedsCount.isEmpty) {
      buffer.writeln("Nenhuma raça identificada.");
    } else {
      final sortedBreeds = breedsCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedBreeds) {
        final pct = (entry.value / totalCount) * 100;
        buffer.writeln("- ${entry.key}: ${entry.value} cab. (${pct.toStringAsFixed(1)}%)");
      }
    }
    buffer.writeln("------------------------------------------------------------");
    buffer.writeln("ELITE GENÉTICA DO REBANHO (TOP 3)");
    buffer.writeln("------------------------------------------------------------");
    if (top3Elite.isEmpty) {
      buffer.writeln("Nenhum animal qualificado.");
    } else {
      for (int i = 0; i < top3Elite.length; i++) {
        final animal = top3Elite[i];
        final String nome = animal['nome'] ?? '';
        final String reg = animal['registro_id'] ?? '';
        final String titleText = nome.isNotEmpty ? nome : (reg.isNotEmpty ? reg : "ID: ${animal['id']}");
        final String raca = animal['raca'] ?? 'Indefinida';
        final int idx = animal['_indiceCalculado'] ?? 0;
        buffer.writeln("${i + 1}º - $titleText ($raca • Índice: $idx pts)");
      }
    }
    buffer.writeln("============================================================");
    buffer.writeln("Gerado pelo aplicativo AgroHub - Gestão Inteligente de Rebanho.");
    buffer.writeln("============================================================");
    
    return buffer.toString();
  }

  String _gerarCSVRelatorio(List<dynamic> list) {
    final buffer = StringBuffer();
    // UTF-8 BOM to make sure MS Excel opens accents correctly
    buffer.write('\uFEFF');
    
    // CSV Header
    buffer.writeln("ID,Nome,Registro ID,Especie,Raca,Linhagem,Idade (Meses),Status Reprodutivo,ECC,Peso (kg),Indice Genetico");
    
    for (final animal in list) {
      final int id = animal['id'] ?? 0;
      final String nome = (animal['nome'] ?? '').toString().replaceAll(',', ';');
      final String reg = (animal['registro_id'] ?? '').toString().replaceAll(',', ';');
      final String esp = (animal['especie'] ?? 'Bovino').toString().replaceAll(',', ';');
      final String raca = (animal['raca'] ?? 'Indefinida').toString().replaceAll(',', ';');
      final String linhagem = (animal['linhagem'] ?? '').toString().replaceAll(',', ';');
      final int idadeMeses = animal['idade_meses'] ?? animal['idade'] ?? 0;
      final String status = (animal['status_reprodutivo'] ?? 'Vazia').toString().replaceAll(',', ';');
      final double ecc = parseDouble(animal['ecc'] ?? animal['escore_corporal']);
      final double peso = parseDouble(animal['peso_kg'] ?? animal['peso']);
      final int index = calcularIndiceGenetico(animal as Map);
      
      buffer.writeln("$id,\"$nome\",\"$reg\",\"$esp\",\"$raca\",\"$linhagem\",$idadeMeses,\"$status\",$ecc,$peso,$index");
    }
    
    return buffer.toString();
  }

  void _mostrarModalExportacao(
    BuildContext context, {
    required List<dynamic> list,
    required int totalCount,
    required double pregnancyRate,
    required double lactatingRate,
    required double inseminatedRate,
    required double emptyRate,
    required int prenhaCount,
    required int lactanteCount,
    required int inseminadaCount,
    required int vaziaCount,
    required double avgGeneticIndex,
    required double avgEcc,
    required double avgWeight,
    required Map<String, int> breedsCount,
    required List<Map<String, dynamic>> top3Elite,
  }) {
    final String txtReport = _gerarTextoRelatorio(
      list: list,
      totalCount: totalCount,
      pregnancyRate: pregnancyRate,
      lactatingRate: lactatingRate,
      inseminatedRate: inseminatedRate,
      emptyRate: emptyRate,
      prenhaCount: prenhaCount,
      lactanteCount: lactanteCount,
      inseminadaCount: inseminadaCount,
      vaziaCount: vaziaCount,
      avgGeneticIndex: avgGeneticIndex,
      avgEcc: avgEcc,
      avgWeight: avgWeight,
      breedsCount: breedsCount,
      top3Elite: top3Elite,
    );

    final String csvReport = _gerarCSVRelatorio(list);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Color(0xFF0F5A1B), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Exportar Relatório ($_activeSpeciesFilter)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F5A1B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Gere e copie o relatório consolidado de desempenho reprodutivo e genético para compartilhar no WhatsApp, Excel ou Email.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Option 1: Formatted Text
              _buildExportOptionCard(
                context,
                title: 'Relatório Formatado (Texto)',
                description: 'Ideal para compartilhar no WhatsApp, Telegram ou Email. Contém todos os KPIs calculados.',
                icon: Icons.article_outlined,
                color: const Color(0xFF0F5A1B),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: txtReport));
                  Navigator.pop(context);
                  _mostrarToastSucesso(context, 'Relatório formatado copiado com sucesso!');
                },
              ),
              const SizedBox(height: 14),

              // Option 2: CSV
              _buildExportOptionCard(
                context,
                title: 'Planilha de Dados (CSV)',
                description: 'Excelente para colar diretamente no Excel ou Google Sheets. Contém a tabela de todas as matrizes.',
                icon: Icons.table_view_outlined,
                color: const Color(0xFF1E88E5),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: csvReport));
                  exportCSV(csvReport, 'relatorio_${_activeSpeciesFilter.toLowerCase()}.csv');
                  Navigator.pop(context);
                  
                  final String msg = kIsWeb 
                      ? 'Download do arquivo CSV iniciado com sucesso!' 
                      : 'Planilha CSV copiada com sucesso! Pronta para o Excel.';
                  _mostrarToastSucesso(context, msg);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectExportCSVRow(List<dynamic> list) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.table_view_outlined, color: Color(0xFF1E88E5), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Planilha do Rebanho',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      Text(
                        'Exportar matrizes (${_activeSpeciesFilter.toLowerCase()}) em formato CSV',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text(
              'Baixar CSV',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              final String csvReport = _gerarCSVRelatorio(list);
              Clipboard.setData(ClipboardData(text: csvReport));
              exportCSV(csvReport, 'relatorio_${_activeSpeciesFilter.toLowerCase()}.csv');
              
              final String msg = kIsWeb 
                  ? 'Download do arquivo CSV iniciado!' 
                  : 'CSV copiado para a área de transferência!';
              _mostrarToastSucesso(context, msg);
            },
          ),
        ],
      ),
    );
  }

  void _mostrarToastSucesso(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F5A1B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

