import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import 'cadastro_animal_screen.dart';
import 'detalhes_screen.dart';


class RebanhoScreen extends StatefulWidget {
  const RebanhoScreen({super.key});

  @override
  State<RebanhoScreen> createState() => _RebanhoScreenState();
}

class _RebanhoScreenState extends State<RebanhoScreen> {
  bool _isLoading = true;
  List<dynamic> _animais = [];
  String _filtroEspecie = 'Todos';
  String _filtroStatus = 'Todos';
  String _filtroCategoria = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRebanho();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRebanho() async {
    setState(() => _isLoading = true);
    try {
      final especieFiltro = _filtroEspecie == 'Todos' ? null : _filtroEspecie;
      final statusFiltro = _filtroStatus == 'Todos' ? null : _filtroStatus;
      final rebanho = await ApiService.getAnimais(especie: especieFiltro, status: statusFiltro);
      setState(() {
        _animais = rebanho;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao sincronizar rebanho: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredAnimais {
    final query = _searchController.text.toLowerCase().trim();
    
    Iterable<dynamic> list = _animais;
    if (query.isNotEmpty) {
      list = list.where((animal) {
        final nome = (animal['nome'] ?? '').toString().toLowerCase();
        final registroId = (animal['registro_id'] ?? '').toString().toLowerCase();
        final raca = (animal['raca'] ?? '').toString().toLowerCase();
        final id = (animal['id'] ?? '').toString().toLowerCase();
        return nome.contains(query) ||
            registroId.contains(query) ||
            raca.contains(query) ||
            id.contains(query);
      });
    }

    if (_filtroCategoria != 'Todos') {
      list = list.where((animal) {
        final especie = (animal['especie'] ?? 'Bovino').toString().toLowerCase();
        final idade = animal['idade_meses'] ?? 0;
        
        bool isAdulto;
        if (especie == 'bovino') {
          isAdulto = idade >= 18;
        } else if (especie == 'ovino' || especie == 'caprino') {
          isAdulto = idade >= 10;
        } else {
          isAdulto = idade >= 12;
        }
        
        if (_filtroCategoria == 'Adultos') {
          return isAdulto;
        } else {
          return !isAdulto;
        }
      });
    }

    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = _filteredAnimais;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 1.5),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AgroHub',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Olá, Produtor',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nenhuma notificação nova.')),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // 1. Premium Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar animal por ID, nome ou raça...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                  ),
                ),
              ),

              // 2. Dropdown Filters
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDropdownFilter(
                        label: 'Espécie',
                        value: _filtroEspecie,
                        items: const ['Todos', 'Bovino', 'Ovino', 'Caprino'],
                        icon: FontAwesomeIcons.cow,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _filtroEspecie = val);
                            _fetchRebanho();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdownFilter(
                        label: 'Status',
                        value: _filtroStatus,
                        items: const ['Todos', 'Vazia', 'Prenha', 'Lactante', 'Inseminada'],
                        icon: Icons.pregnant_woman,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _filtroStatus = val);
                            _fetchRebanho();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdownFilter(
                        label: 'Categoria',
                        value: _filtroCategoria,
                        items: const ['Todos', 'Adultos', 'Crias'],
                        icon: Icons.pets_outlined,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _filtroCategoria = val);
                            _fetchRebanho();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

              // 3. Matrizes List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                    : listToShow.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetchRebanho,
                            color: const Color(0xFF2E7D32),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: listToShow.length,
                              itemBuilder: (context, index) {
                                final animal = listToShow[index];
                                return _buildAnimalCard(animal);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastroAnimalScreen()),
          );
          if (result == true) {
            _fetchRebanho();
          }
        },
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum animal cadastrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Nenhum resultado corresponde à sua busca.'
                  : 'Toque no botão "+" no canto inferior para cadastrar a primeira matriz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    final String especie = animal['especie'] ?? 'Bovino';
    final String raca = animal['raca'] ?? 'Indefinida';
    final int idade = animal['idade_meses'] ?? 0;
    final int id = animal['id'] ?? 0;
    final String? registroId = animal['registro_id'];
    final String? nome = animal['nome'];
    final String? fotoUrl = animal['foto_url'];

    // Friendly fallback titles
    final String titleText = (nome != null && nome.isNotEmpty) ? nome : (registroId ?? 'Registro #$id');
    final String subtitleIdText = (nome != null && nome.isNotEmpty) ? (registroId ?? 'Registro #$id') : 'Sem Brinco ID';

    Color badgeBg;
    Color badgeText;
    dynamic especieIcon;

    switch (especie.toLowerCase()) {
      case 'bovino':
        badgeBg = const Color(0xFFE8F5E9);
        badgeText = const Color(0xFF2E7D32);
        especieIcon = FontAwesomeIcons.cow;
        break;
      case 'ovino':
        badgeBg = const Color(0xFFE3F2FD);
        badgeText = const Color(0xFF1976D2);
        especieIcon = FontAwesomeIcons.paw;
        break;
      case 'caprino':
        badgeBg = const Color(0xFFEFEBE9);
        badgeText = const Color(0xFF5D4037);
        especieIcon = FontAwesomeIcons.paw;
        break;
      default:
        badgeBg = Colors.grey[100]!;
        badgeText = Colors.grey[700]!;
        especieIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalhesScreen(animal: animal),
            ),
          );
          if (result == true) {
            _fetchRebanho();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animal Image or species placeholder (Perfectly Centered Inside Container)
                  if (fotoUrl != null && fotoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        fotoUrl,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 68,
                            height: 68,
                            color: badgeBg.withValues(alpha: 0.5),
                            child: Center(
                              child: _buildEspecieIcon(especieIcon, badgeText, 28),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: badgeBg.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _buildEspecieIcon(especieIcon, badgeText, 28),
                      ),
                    ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                titleText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A2E1A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge da espécie
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    especie,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: badgeText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Badge do Status Reprodutivo
                                _buildStatusBadge(animal['status_reprodutivo'] ?? 'Vazia'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$subtitleIdText  •  $raca',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        // Removed ECC status badge! Just displaying Age and Weight
                        Text(
                          '$idade Meses  •  ${animal['peso'] ?? 'N/A'} kg',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      FaIcon(
                        (animal['sexo'] ?? 'Fêmea') == 'Fêmea'
                            ? FontAwesomeIcons.venus
                            : FontAwesomeIcons.mars,
                        size: 13,
                        color: (animal['sexo'] ?? 'Fêmea') == 'Fêmea'
                            ? Colors.pink
                            : Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        animal['sexo'] ?? 'Fêmea',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: (animal['sexo'] ?? 'Fêmea') == 'Fêmea'
                              ? Colors.pink
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'Ver Ficha Completa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required dynamic icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null)
                icon.runtimeType.toString() == 'IconData'
                    ? Icon(icon as IconData, size: 9, color: const Color(0xFF2E7D32))
                    : FaIcon(icon, size: 9, color: const Color(0xFF2E7D32)),
              if (icon != null) const SizedBox(width: 3),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          DropdownButtonHideUnderline(
            child: SizedBox(
              height: 24,
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32), size: 14),
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                dropdownColor: Colors.white,
                items: items.map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label = status;

    final statusLower = status.trim().toLowerCase();
    if (statusLower == 'prenha' || statusLower == 'prenhe') {
      label = 'Prenha';
    }

    switch (statusLower) {
      case 'prenha':
      case 'prenhe':
        bg = const Color(0xFFF3E5F5); // Light purple
        text = const Color(0xFF7B1FA2); // Purple
        break;
      case 'inseminada':
        bg = const Color(0xFFE3F2FD); // Light blue
        text = const Color(0xFF1565C0); // Blue
        break;
      case 'lactante':
        bg = const Color(0xFFFFF3E0); // Light orange
        text = const Color(0xFFE65100); // Orange
        break;
      case 'vazia':
      default:
        bg = const Color(0xFFECEFF1); // Light grey
        text = const Color(0xFF455A64); // Dark grey
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  Widget _buildEspecieIcon(dynamic icon, Color color, double size) {
    if (icon == Icons.help_outline) {
      return Icon(icon, color: color, size: size);
    }
    return FaIcon(icon, color: color, size: size);
  }
}
