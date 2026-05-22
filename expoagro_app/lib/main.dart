import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart'; // Importando a tela de navegação principal

void main() {
  runApp(const SimuladorViabilidadeApp());
}

class SimuladorViabilidadeApp extends StatelessWidget {
  const SimuladorViabilidadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroHub - Simulador & Gestão',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const MainNavigationScreen(),
    );
  }
}