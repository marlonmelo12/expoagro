import 'package:flutter/material.dart';
import 'screens/simulador_screen.dart'; // Importando a tela da pasta screens

void main() {
  runApp(const SimuladorViabilidadeApp());
}

class SimuladorViabilidadeApp extends StatelessWidget {
  const SimuladorViabilidadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simulador de Viabilidade Reprodutiva',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const SimuladorScreen(),
    );
  }
}