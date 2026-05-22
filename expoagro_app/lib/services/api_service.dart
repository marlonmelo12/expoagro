import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    } else {
      return 'http://localhost:8000/api';
    }
  }

  static Future<Map<String, dynamic>> preverSucesso(Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predicao/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  static Future<List<dynamic>> obterMelhoresCandidatas(Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predicao/melhores-candidatas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }


  static Future<Map<String, dynamic>> getDashboardKpis() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/kpis'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  static Future<List<dynamic>> getAnimais({String? especie, String? status}) async {
    String url = '$baseUrl/animais';
    final params = <String, String>{};
    if (especie != null && especie.isNotEmpty) params['especie'] = especie;
    if (status != null && status.isNotEmpty) params['status_reprodutivo'] = status;
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> criarAnimal(Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animais'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> registrarInseminacao(int animalId, Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animais/$animalId/inseminacoes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> deletarAnimal(int animalId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/animais/$animalId'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> atualizarStatusAnimal(int animalId, String novoStatus) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/animais/$animalId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status_reprodutivo': novoStatus}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> editarAnimal(int animalId, Map<String, dynamic> dados) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/animais/$animalId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  static Future<List<dynamic>> listarEventos(int animalId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/animais/$animalId/eventos'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> criarEvento(int animalId, Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animais/$animalId/eventos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> registrarParto(int animalId, Map<String, dynamic> dadosParto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animais/$animalId/partos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dadosParto),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }
}