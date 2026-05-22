import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'rebanho_screen.dart';
import 'catalogo_genetico_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const RebanhoScreen(),
    const CatalogoGeneticoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          backgroundColor: const Color(0xFFF5F5F5),
          indicatorColor: const Color(0xFF64B5F6).withValues(alpha: 0.3),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded, color: Colors.grey),
              selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF1E88E5)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_rounded, color: Colors.grey),
              selectedIcon: Icon(Icons.pets_rounded, color: Color(0xFF1E88E5)),
              label: 'Rebanho',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_books, color: Colors.grey),
              selectedIcon: Icon(Icons.library_books, color: Color(0xFF1E88E5)),
              label: 'Catálogo',
            ),
          ],
        ),
      ),
    );
  }
}

