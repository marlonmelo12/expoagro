import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../utils/web_exporter.dart';
import 'editar_animal_screen.dart';
import 'registrar_cria_screen.dart';

class DetalhesScreen extends StatefulWidget {
  final Map<String, dynamic> animal;

  const DetalhesScreen({super.key, required this.animal});

  @override
  State<DetalhesScreen> createState() => _DetalhesScreenState();
}

class _DetalhesScreenState extends State<DetalhesScreen> {
  bool _isDeleting = false;
  List<dynamic> _eventos = [];
  bool _isLoadingEventos = true;
  bool _huboAlteracion = false;

  @override
  void initState() {
    super.initState();
    _fetchEventos();
  }

  Future<void> _fetchEventos() async {
    try {
      final eventos = await ApiService.listarEventos(widget.animal['id']);
      setState(() {
        _eventos = eventos;
        _isLoadingEventos = false;
      });
    } catch (e) {
      setState(() => _isLoadingEventos = false);
    }
  }

  void _showChangeStatus() {
    final statusOptions = [
      {'label': 'Vazia',      'icon': Icons.circle_outlined,  'color': Colors.grey},
      {'label': 'Inseminada', 'icon': Icons.vaccines,          'color': Colors.blue},
      {'label': 'Prenha',     'icon': Icons.pregnant_woman,    'color': Colors.purple},
      {'label': 'Lactante',   'icon': Icons.child_care,        'color': Colors.orange},
    ];

    final currentStatus = widget.animal['status_reprodutivo'] ?? 'Vazia';

    String mensagemConfirmacao(String novoStatus) {
      if (currentStatus == 'Prenha' && novoStatus == 'Lactante') {
        return 'Isso indica que esta matriz acabou de PARIR.\nO status será alterado de "Prenha" para "Lactante".\n\nConfirma?';
      }
      if (currentStatus == 'Inseminada' && novoStatus == 'Prenha') {
        return 'Confirma diagnóstico de PRENHEZ para esta matriz?\nO status mudará de "Inseminada" para "Prenha".';
      }
      if (novoStatus == 'Vazia') {
        return 'Tem certeza que deseja marcar esta matriz como VAZIA?\nO status atual "$currentStatus" será perdido.';
      }
      return 'Confirma a mudança de status de "$currentStatus" para "$novoStatus"?';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: Color(0xFF1976D2)),
            SizedBox(width: 10),
            Expanded(
              child: Text('Trocar Status Reprodutivo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusOptions.map((opt) {
            final label = opt['label'] as String;
            final icon  = opt['icon']  as IconData;
            final color = opt['color'] as MaterialColor;
            final isActive = label == currentStatus;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.shade50,
                child: Icon(icon, color: color.shade700, size: 20),
              ),
              title: Text(label,
                  style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
              trailing: isActive
                  ? Icon(Icons.check_circle, color: color.shade700)
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: () async {
                Navigator.pop(ctx);
                if (label == currentStatus) return;

                if (currentStatus == 'Prenha' && label == 'Lactante') {
                  final salvo = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrarCriaScreen(mae: widget.animal),
                    ),
                  );

                  if (salvo == true && mounted) {
                    setState(() {
                      widget.animal['status_reprodutivo'] = 'Lactante';
                      _huboAlteracion = true;
                    });
                    _fetchEventos();
                  }
                  return;
                }

                if (currentStatus == 'Vazia' && label == 'Inseminada') {
                  final animalEspecie = widget.animal['especie'] ?? 'Bovino';
                  final matchingGenetics = [
                    { "nome": "Rem Torixoréu FIV", "especie": "Bovino", "raca": "Nelore", "indice_genetico": 98 },
                    { "nome": "Fardo FIV F. Mutum", "especie": "Bovino", "raca": "Girolando", "indice_genetico": 85 },
                    { "nome": "Sertão TE 102", "especie": "Ovino", "raca": "Santa Inês", "indice_genetico": 88 },
                    { "nome": "Capitão Boer 44", "especie": "Caprino", "raca": "Boer", "indice_genetico": 94 },
                  ].where((g) => g['especie'].toString().toLowerCase() == animalEspecie.toString().toLowerCase()).toList();

                  if (matchingGenetics.isEmpty) {
                    matchingGenetics.add({ "nome": "Genética Geral (Sem registro)", "especie": animalEspecie, "raca": "Geral", "indice_genetico": 80 });
                  }

                  Map<String, dynamic>? selectedGenetics = matchingGenetics.first;

                  final confirmInseminacao = await showDialog<bool>(
                    context: context,
                    builder: (inseminacaoCtx) => StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(Icons.vaccines, color: Colors.blue),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('Registrar Inseminação', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A matriz ${widget.animal['nome'] ?? 'Registro ${widget.animal['registro_id']}'} será marcada como Inseminada.',
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Selecione a Genética / Reprodutor:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<Map<String, dynamic>>(
                                isExpanded: true,
                                initialValue: selectedGenetics,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: matchingGenetics.map((gen) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: gen,
                                    child: Text(
                                      '${gen['nome']} (${gen['raca']} - Índice: ${gen['indice_genetico']})',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setStateDialog(() {
                                    selectedGenetics = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(inseminacaoCtx, false),
                              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(inseminacaoCtx, true),
                              style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                              child: const Text('Confirmar Inseminação'),
                            ),
                          ],
                        );
                      }
                    ),
                  );

                  if (confirmInseminacao == true && selectedGenetics != null) {
                    try {
                      setState(() => _isLoadingEventos = true);
                      
                      final payload = {
                        "data_inseminacao": DateTime.now().toIso8601String().split('T')[0],
                        "ecc": widget.animal['ecc'] ?? 3.0,
                        "tentativas_previas": 0,
                        "indice_genetico_reprodutor": selectedGenetics!['indice_genetico'],
                        "estacao": "Estação de Monta",
                        "dias_pos_parto": 60,
                      };

                      await ApiService.registrarInseminacao(widget.animal['id'], payload);

                      if (!mounted) return;
                      setState(() {
                        widget.animal['status_reprodutivo'] = 'Inseminada';
                        _huboAlteracion = true;
                        _isLoadingEventos = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Inseminação registrada com sucesso usando ${selectedGenetics!['nome']}!'),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ));

                      _fetchEventos(); // recarrega a timeline
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _isLoadingEventos = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Erro ao registrar inseminação: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ));
                    }
                  }
                  return;
                }

                // Confirmação antes de aplicar para outros status
                final confirmado = await showDialog<bool>(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        Icon(Icons.help_outline_rounded,
                            color: color.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                            child: Text('Confirmar Mudança',
                                style: TextStyle(fontSize: 16))),
                      ],
                    ),
                    content: Text(
                      mensagemConfirmacao(label),
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx, false),
                        child: const Text('Cancelar',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(confirmCtx, true),
                        style: FilledButton.styleFrom(
                            backgroundColor: color.shade700),
                        child: Text('Confirmar "$label"'),
                      ),
                    ],
                  ),
                );

                if (confirmado != true) return;

                try {
                  await ApiService.atualizarStatusAnimal(
                      widget.animal['id'], label);
                  
                  // Registrar evento histórico correspondente
                  try {
                    await ApiService.criarEvento(widget.animal['id'], {
                      "categoria_evento": "Reprodutivo",
                      "titulo_evento": "Alteração de Status",
                      "data_evento": DateTime.now().toIso8601String().split('T')[0],
                      "detalhes": "Status reprodutivo alterado manualmente de '$currentStatus' para '$label'.",
                    });
                  } catch (e) {
                    // Ignora silenciosamente se falhar ao criar o evento, para não quebrar a transição principal
                  }

                  if (!mounted) return;
                  setState(() {
                    widget.animal['status_reprodutivo'] = label;
                    _huboAlteracion = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Status atualizado para "$label"!'),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                  _fetchEventos(); // recarrega a timeline
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro ao atualizar status: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }


  void _showEventOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Registrar Novo Evento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.vaccines, color: Colors.blue),
                title: const Text('Registrar Vacina'),
                onTap: () {
                  Navigator.pop(context);
                  _showEventForm('Sanitário', 'Vacinação');
                },
              ),
              ListTile(
                leading: const Icon(Icons.monitor_weight, color: Colors.orange),
                title: const Text('Registrar Pesagem'),
                onTap: () {
                  Navigator.pop(context);
                  _showEventForm('Manejo', 'Pesagem de Rotina');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEventForm(String categoria, String titulo) {
    final formKey = GlobalKey<FormState>();
    final detalhesCtrl = TextEditingController();
    final pesoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Novo Evento: $titulo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categoria == 'Manejo') ...[
                    TextFormField(
                      controller: pesoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Novo Peso (kg)', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: detalhesCtrl,
                    decoration: const InputDecoration(labelText: 'Detalhes / Observações', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext);
                  final novoPeso = pesoCtrl.text.isNotEmpty
                      ? double.tryParse(pesoCtrl.text)
                      : null;
                  try {
                    await ApiService.criarEvento(widget.animal['id'], {
                      "categoria_evento": categoria,
                      "titulo_evento": titulo,
                      "data_evento": DateTime.now().toIso8601String().split('T')[0],
                      "detalhes": detalhesCtrl.text,
                      "novo_peso": novoPeso,
                    });
                    // Atualiza o peso exibido localmente se foi pesagem
                    if (mounted) {
                      setState(() {
                        if (novoPeso != null) {
                          widget.animal['peso'] = novoPeso;
                        }
                        _huboAlteracion = true;
                      });
                    }
                    _fetchEventos(); // recarrega a timeline
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      }
    );
  }




  Future<void> _excluirRegistro() async {
    final int animalId = widget.animal['id'];
    final String nomeExclusao = widget.animal['nome'] ?? widget.animal['registro_id'] ?? 'Registro #$animalId';

    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Confirmar Exclusão'),
              ),
            ],
          ),
          content: Text('Tem certeza de que deseja remover permanentemente a matriz "$nomeExclusao" do banco de dados AgroHub? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await ApiService.deletarAnimal(animalId);
      setState(() => _isDeleting = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro "$nomeExclusao" excluído com sucesso!'),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
      Navigator.pop(context, true); // Retorna true para a lista recarregar
    } catch (e) {
      setState(() => _isDeleting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir registro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  double parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  int calcularIndiceGenetico(Map animal) {
    final int id = animal['id'] ?? 0;
    final double ecc = parseDouble(animal['ecc'] ?? animal['escore_corporal'] ?? 3.0);
    
    int base = (id % 15) + 80;
    final String nome = (animal['nome'] ?? '').toString().toUpperCase();
    final String registro = (animal['registro_id'] ?? '').toString().toUpperCase();
    
    if (nome.contains('FIV') || registro.contains('FIV') || nome.contains('TE') || registro.contains('TE')) {
      base += 3;
    }
    if (ecc >= 3.0 && ecc <= 3.75) {
      base += 2;
    }
    return base.clamp(75, 99);
  }

  String _gerarCSVIndividual() {
    final Map<String, dynamic> animal = widget.animal;
    final int id = animal['id'] ?? 0;
    final String nome = animal['nome'] ?? '';
    final String registro = animal['registro_id'] ?? '';
    final String especie = animal['especie'] ?? 'Bovino';
    final String raca = animal['raca'] ?? 'Nelore';
    final String linhagem = animal['linhagem'] ?? 'PO';
    final String sexo = animal['sexo'] ?? 'Fêmea';
    final int idade = animal['idade_meses'] ?? 0;
    final double peso = (animal['peso'] ?? 480.0).toDouble();
    final double ecc = (animal['ecc'] ?? 3.0).toDouble();
    final int idxGenetico = calcularIndiceGenetico(animal);
    
    final Map<String, dynamic>? mae = animal['mae'];
    final String? maeNome = mae?['nome'];
    final int? maeId = mae?['id'] ?? animal['mae_id'];
    String displayMae = 'Desconhecida';
    if (maeId != null) {
      if (maeNome != null && maeNome.isNotEmpty) {
        displayMae = '$maeNome (ID: #$maeId)';
      } else {
        displayMae = 'ID: #$maeId';
      }
    }
    final String pai = animal['origem_paterna'] ?? 'Desconhecida';
    final String status = animal['status_reprodutivo'] ?? 'Vazia';
    
    final StringBuffer csv = StringBuffer();
    csv.write('\uFEFF');
    csv.writeln('FICHA ZOOTÉCNICA INDIVIDUAL - AGROHUB');
    csv.writeln('Data de Exportacao: ${DateTime.now().toIso8601String().split('T')[0]}');
    csv.writeln();
    csv.writeln('Campo,Valor');
    csv.writeln('ID, #$id');
    csv.writeln('Nome, $nome');
    csv.writeln('Registro/Brinco, $registro');
    csv.writeln('Especie, $especie');
    csv.writeln('Raca, $raca');
    csv.writeln('Linhagem, $linhagem');
    csv.writeln('Sexo, $sexo');
    csv.writeln('Idade (Meses), $idade');
    csv.writeln('Peso (kg), ${peso.toStringAsFixed(1)}');
    csv.writeln('ECC (Escore Corporal), ${ecc.toStringAsFixed(2)}');
    csv.writeln('Status Reprodutivo, $status');
    csv.writeln('Mae, $displayMae');
    csv.writeln('Origem Paterna, $pai');
    csv.writeln('Indice Genetico, $idxGenetico%');
    csv.writeln();
    csv.writeln('HISTORICO DE ATIVIDADES');
    csv.writeln('Data,Categoria,Titulo,Detalhes,Novo Peso (kg)');
    if (_eventos.isEmpty) {
      csv.writeln('-, -, Nenhum evento registrado, -, -');
    } else {
      for (final ev in _eventos) {
        final String data = _formatDate(ev['data_evento'] ?? '');
        final String cat = ev['categoria_evento'] ?? '';
        final String tit = ev['titulo_evento'] ?? '';
        final String det = (ev['detalhes'] ?? '').toString().replaceAll(',', ';').replaceAll('\n', ' ');
        final String np = ev['novo_peso'] != null ? ev['novo_peso'].toString() : '';
        csv.writeln('$data, $cat, $tit, $det, $np');
      }
    }
    return csv.toString();
  }

  String _gerarTextoIndividual() {
    final Map<String, dynamic> animal = widget.animal;
    final int id = animal['id'] ?? 0;
    final String nome = animal['nome'] ?? '';
    final String registro = animal['registro_id'] ?? '';
    final String especie = animal['especie'] ?? 'Bovino';
    final String raca = animal['raca'] ?? 'Nelore';
    final String linhagem = animal['linhagem'] ?? 'PO';
    final String sexo = animal['sexo'] ?? 'Fêmea';
    final int idade = animal['idade_meses'] ?? 0;
    final double peso = (animal['peso'] ?? 480.0).toDouble();
    final double ecc = (animal['ecc'] ?? 3.0).toDouble();
    final int idxGenetico = calcularIndiceGenetico(animal);
    
    final Map<String, dynamic>? mae = animal['mae'];
    final String? maeNome = mae?['nome'];
    final int? maeId = mae?['id'] ?? animal['mae_id'];
    String displayMae = 'Desconhecida';
    if (maeId != null) {
      if (maeNome != null && maeNome.isNotEmpty) {
        displayMae = '$maeNome (ID: #$maeId)';
      } else {
        displayMae = 'ID: #$maeId';
      }
    }
    final String pai = animal['origem_paterna'] ?? 'Desconhecida';
    final String status = animal['status_reprodutivo'] ?? 'Vazia';
    
    String emojiStatus = '🟢';
    if (status.toLowerCase().contains('prenh')) {
      emojiStatus = '🤰';
    } else if (status.toLowerCase().contains('lact')) {
      emojiStatus = '🍼';
    } else if (status.toLowerCase().contains('insem')) {
      emojiStatus = '💉';
    }
    
    final StringBuffer txt = StringBuffer();
    txt.writeln('📋 *FICHA ZOOTÉCNICA - AGROHUB* 🌾');
    txt.writeln('----------------------------------');
    txt.writeln('*Matriz:* ${nome.isNotEmpty ? nome : "Registro #$id"}');
    if (registro.isNotEmpty) txt.writeln('*Registro/Brinco:* $registro');
    txt.writeln('*Espécie:* $especie');
    txt.writeln('*Raça:* $raca ($linhagem)');
    txt.writeln('*Sexo:* $sexo');
    txt.writeln('*Idade:* $idade meses');
    txt.writeln('*Peso:* ${peso.toStringAsFixed(0)} kg');
    txt.writeln('*ECC:* ${ecc.toStringAsFixed(2)} / 5.0');
    txt.writeln('*Status Reprodutivo:* $emojiStatus *$status*');
    txt.writeln('*Índice Genético:* 🧬 $idxGenetico%');
    txt.writeln();
    txt.writeln('*Genealogia:*');
    txt.writeln('• Mãe: $displayMae');
    txt.writeln('• Origem Paterna: $pai');
    txt.writeln();
    txt.writeln('*Histórico de Atividades:*');
    if (_eventos.isEmpty) {
      txt.writeln('• Nenhum evento registrado.');
    } else {
      final exibidos = _eventos.take(5).toList();
      for (final ev in exibidos) {
        final String data = _formatDate(ev['data_evento'] ?? '');
        final String tit = ev['titulo_evento'] ?? '';
        final String det = ev['detalhes'] ?? '';
        final String np = ev['novo_peso'] != null ? ' (${ev['novo_peso']} kg)' : '';
        txt.writeln('• $data - $tit$np: $det');
      }
      if (_eventos.length > 5) {
        txt.writeln('• E mais ${_eventos.length - 5} eventos no histórico completo...');
      }
    }
    txt.writeln('----------------------------------');
    txt.writeln('*AgroHub* - Gestão Inteligente de Rebanhos');
    return txt.toString();
  }

  void _showExportOptionsBottomSheet() {
    final String displayName = widget.animal['nome'] ?? widget.animal['registro_id'] ?? 'Matriz';
    final String fileName = 'ficha_${displayName.toLowerCase().replaceAll(' ', '_')}.csv';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Exportar Ficha Zootécnica',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Escolha o formato de exportação para a matriz $displayName:',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    final csvContent = _gerarCSVIndividual();
                    Clipboard.setData(ClipboardData(text: csvContent));
                    exportCSV(csvContent, fileName);
                    
                    final String msg = kIsWeb 
                        ? 'Download da Ficha CSV iniciado!' 
                        : 'Ficha CSV copiada para a área de transferência!';
                    _mostrarToastSucesso(this.context, msg);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.table_view_outlined, color: Color(0xFF1E88E5), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Planilha Excel / CSV',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E88E5)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ficha completa e histórico estruturados em formato de planilha (.csv)',
                                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF1E88E5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    final textSummary = _gerarTextoIndividual();
                    Clipboard.setData(ClipboardData(text: textSummary));
                    _mostrarToastSucesso(this.context, 'Relatório de texto copiado! Pronto para colar no WhatsApp.');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.share_outlined, color: Color(0xFF2E7D32), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Texto Formatado (WhatsApp / Redes)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Resumo estético com emojis pronto para copiar e enviar aos contatos',
                                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF2E7D32)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> animal = widget.animal;
    final int id = animal['id'] ?? 0;
    final String especie = animal['especie'] ?? 'Bovino';
    final String raca = animal['raca'] ?? 'Nelore';
    final String linhagem = animal['linhagem'] ?? 'PO';
    final int idade = animal['idade_meses'] ?? 0;
    final double peso = (animal['peso'] ?? 480.0).toDouble();
    final double ecc = (animal['ecc'] ?? 3.0).toDouble();
    final String? nome = animal['nome'];
    final String? registroId = animal['registro_id'];
    final String? fotoUrl = animal['foto_url'];

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    final String displayName = (nome != null && nome.isNotEmpty) ? nome : (registroId ?? 'Registro #$id');

    final Map<String, dynamic>? mae = animal['mae'];
    final String? maeNome = mae?['nome'];
    final int? maeId = mae?['id'] ?? animal['mae_id'];
    String displayMae = 'Desconhecida';
    if (maeId != null) {
      if (maeNome != null && maeNome.isNotEmpty) {
        displayMae = '$maeNome (ID: #$maeId)';
      } else {
        displayMae = 'ID: #$maeId';
      }
    }

    final dynamic especieIcon = especie.toLowerCase() == 'ovino'
        ? FontAwesomeIcons.paw
        : (especie.toLowerCase() == 'caprino'
            ? FontAwesomeIcons.paw
            : FontAwesomeIcons.cow);


    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _huboAlteracion),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ficha Zootécnica',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              displayName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Exportar Relatório',
            onPressed: _showExportOptionsBottomSheet,
          ),
        ],
      ),
      floatingActionButton: null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // 1. Header animal card (centered, narrower, square photo)
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Centered Animal Image
                          Center(
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Photo or fallback species icon
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: (fotoUrl != null && fotoUrl.isNotEmpty)
                                          ? Image.network(
                                              fotoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: const Color(0xFFE8F5E9),
                                                child: Center(
                                                  child: FaIcon(especieIcon, color: const Color(0xFF2E7D32), size: 44),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: Center(
                                                child: FaIcon(especieIcon, color: Colors.white, size: 48),
                                              ),
                                            ),
                                    ),
                                  ),
                                  // Float Active badge bottom right
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 3,
                                            offset: Offset(0, 1.5),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle_outline, color: Colors.white, size: 13),
                                          SizedBox(width: 4),
                                          Text(
                                            'Ativo',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Subtitle
                          const Text(
                            'IDENTIFICAÇÃO DO ANIMAL',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Main animal name/id
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2E1A),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Pill Badges (Age and Weight)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Age Pill (Blue)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCE6F8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, color: Color(0xFF1976D2), size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$idade Meses',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D47A1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Weight Pill (Green)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD3E3D3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.monitor_weight_outlined, color: Color(0xFF2E7D32), size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${peso.toStringAsFixed(0)} kg',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Informações Básicas Table
                  Container(
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.feed_outlined, color: Color(0xFF2E7D32)),
                            SizedBox(width: 8),
                            Text(
                              'Dados Zootécnicos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        _buildFichaRow('Nome do Animal', nome ?? 'Não Definido'),
                        _buildFichaRow('Registro / Brinco', registroId ?? 'Sem Registro'),
                        _buildFichaRow('Espécie', especie),
                        _buildFichaRow('Raça', raca),
                        _buildFichaRow('Linhagem', linhagem),
                        _buildFichaRow('Sexo', animal['sexo'] ?? 'Fêmea'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3.5. Dados Detalhados (Genealogia)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(Icons.family_restroom, color: Color(0xFF2E7D32)),
                        title: const Text('Genealogia', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                            child: Column(
                              children: [
                                _buildFichaRow('Mãe', displayMae),
                                _buildFichaRow('Origem Paterna', animal['origem_paterna'] ?? 'Desconhecida'),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Status de Saúde
                  Row(
                    children: [
                      Expanded(
                        child: Container(
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PESO ATUAL',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${peso.toStringAsFixed(1)} kg',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CONDIÇÃO CORPORAL',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ecc.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. Histórico Recente (Timeline)
                  Container(
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.timeline, color: Color(0xFF2E7D32)),
                            SizedBox(width: 8),
                            Text(
                              'Histórico de Atividades',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        if (_isLoadingEventos)
                          const Center(child: CircularProgressIndicator())
                        else if (_eventos.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Nenhum evento registrado.', style: TextStyle(color: Colors.grey)),
                          )
                        else
                          ..._eventos.asMap().entries.map((entry) {
                            final index = entry.key;
                            final ev = entry.value;
                            return _buildTimelineItem(
                              title: ev['titulo_evento'] ?? '',
                              date: _formatDate(ev['data_evento'] ?? ''),
                              subtitle: ev['detalhes'] ?? '',
                              categoria: ev['categoria_evento'] ?? '',
                              isFirst: index == 0,
                              isLast: index == _eventos.length - 1,
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Painel de Controle e Ações
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.dashboard_customize_outlined, color: Color(0xFF2E7D32)),
                            SizedBox(width: 8),
                            Text(
                              'Painel de Controle e Ações',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        GridView.count(
                          crossAxisCount: isDesktop ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: isDesktop ? 2.5 : 1.35,
                          children: [
                            _buildActionButton(
                              icon: Icons.swap_horiz_rounded,
                              color: const Color(0xFF1976D2),
                              label: 'Trocar\nStatus',
                              onTap: _showChangeStatus,
                              isDesktop: isDesktop,
                            ),
                            _buildActionButton(
                              icon: Icons.add_circle_outline_rounded,
                              color: const Color(0xFF2E7D32),
                              label: 'Registrar\nEvento',
                              onTap: _showEventOptions,
                              isDesktop: isDesktop,
                            ),
                            _buildActionButton(
                              icon: Icons.edit_note_rounded,
                              color: Colors.orange.shade800,
                              label: 'Editar\nCadastro',
                              onTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditarAnimalScreen(animal: widget.animal),
                                  ),
                                );
                                if (updated != null && mounted) {
                                  setState(() {
                                    (updated as Map<String, dynamic>).forEach((k, v) {
                                      widget.animal[k] = v;
                                    });
                                    _huboAlteracion = true;
                                  });
                                }
                              },
                              isDesktop: isDesktop,
                            ),
                            _buildActionButton(
                              icon: Icons.share_outlined,
                              color: const Color(0xFF007A87),
                              label: 'Exportar\nRelatório',
                              onTap: _showExportOptionsBottomSheet,
                              isDesktop: isDesktop,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton.icon(
                            onPressed: _isDeleting ? null : _excluirRegistro,
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F), size: 20),
                            label: const Text(
                              'Excluir Matriz do Sistema',
                              style: TextStyle(
                                color: Color(0xFFD32F2F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFFFEBEE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
              if (_isDeleting)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.red),
                            SizedBox(height: 20),
                            Text(
                              'Removendo registro do AgroHub...',
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
        ),
      ),
    );
  }

  String _formatDate(String input) {
    if (input.isEmpty) return '';
    try {
      final datePart = input.contains('T') ? input.split('T')[0] : input;
      final parts = datePart.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = parts[1];
        final day = parts[2];
        return '$day/$month/$year';
      }
    } catch (_) {}
    return input;
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    required bool isDesktop,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        padding: isDesktop
            ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12)
            : const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: isDesktop
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label.replaceAll('\n', ' '),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFichaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String date,
    required String subtitle,
    String categoria = '',
    bool isFirst = false,
    bool isLast = false,
  }) {
    IconData icone = Icons.event;
    Color corIcone = const Color(0xFF2E7D32);
    if (categoria == 'Sanitário') {
      icone = Icons.vaccines;
      corIcone = Colors.blue;
    } else if (categoria == 'Manejo') {
      icone = Icons.monitor_weight;
      corIcone = Colors.orange;
    } else if (categoria == 'Reprodutivo') {
      icone = Icons.child_friendly;
      corIcone = Colors.purple;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: corIcone.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 14, color: corIcone),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A)),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
