import 'package:flutter/material.dart';
import 'package:expoagro_app/screens/simulador_screen.dart';

class CatalogoGeneticoScreen extends StatelessWidget {
  const CatalogoGeneticoScreen({super.key});

  final List<Map<String, dynamic>> catalogo = const [
    { "id_catalogo": 1, "nome": "Rem Torixoréu FIV", "especie": "Bovino", "raca": "Nelore", "aptidao": "Corte", "metricas": "Top 0.1% iABCZ | PE-365: +1.85cm", "indice_genetico": 98, "descricao": "Nelore PO. Excelente ganho de peso e perímetro escrotal." },
    { "id_catalogo": 2, "nome": "Fardo FIV F. Mutum", "especie": "Bovino", "raca": "Girolando", "aptidao": "Leite", "metricas": "PTA Leite: +850kg | Sexado de Fêmea", "indice_genetico": 85, "descricao": "Girolando. Sêmen sexado, ideal para reposição leiteira." },
    { "id_catalogo": 3, "nome": "Sertão TE 102", "especie": "Ovino", "raca": "Santa Inês", "aptidao": "Carne e Rusticidade", "metricas": "Prolificidade: +15% | PD: +2.4kg", "indice_genetico": 88, "descricao": "Santa Inês PO. Aumenta taxa de partos duplos e resistência." },
    { "id_catalogo": 4, "nome": "Capitão Boer 44", "especie": "Caprino", "raca": "Boer", "aptidao": "Corte Premium", "metricas": "GPD: +280g/dia | Rendimento Carcaça: Top 5%", "indice_genetico": 94, "descricao": "Boer Puro. Genética importada para ganho de peso explosivo." }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      backgroundColor: Colors.grey[100],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: catalogo.length,
            itemBuilder: (context, index) {
              final item = catalogo[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['nome'],
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Índice: ${item['indice_genetico']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item['especie']} • ${item['raca']} • ${item['aptidao']}',
                        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['descricao'],
                        style: TextStyle(color: Colors.grey[800], height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          item['metricas'],
                          style: TextStyle(color: Colors.grey[800], fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.bolt_rounded),
                          label: const Text('Gerar Simulação'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            // Navega para a tela de resultados do simulador passando os dados do reprodutor
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SimuladorScreen(
                                  indiceGeneticoReprodutor: item['indice_genetico'] as int,
                                  especie: item['especie'] as String,
                                  nomeReprodutor: item['nome'] as String,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
