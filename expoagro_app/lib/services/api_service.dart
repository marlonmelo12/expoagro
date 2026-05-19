import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ATENÇÃO: Se estiver usando emulador Android, mantenha 10.0.2.2
  // Se for testar no navegador (Flutter Web) ou iOS, mude para 127.0.0.1 ou localhost
  static const String baseUrl = 'http://localhost:8000/api';

  static Future<Map<String, dynamic>> preverSucesso(Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predicao/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }
}