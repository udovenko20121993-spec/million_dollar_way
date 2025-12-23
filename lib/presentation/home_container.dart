import 'package:flutter/material.dart';

// Імпортуємо екрани
import 'package:million_dollar_way/presentation/home/home_screen.dart';
import 'package:million_dollar_way/presentation/portfolio/portfolio_screen.dart';
// Імпортуємо екран Мідас (шлях має відповідати тому, де ви створили файл)
import 'package:million_dollar_way/presentation/road_to_million/midas_screen.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _selectedIndex = 0;

  // Список головних сторінок
  final List<Widget> _screens = [
    const HomeScreen(), // 0: Головна (Звітність)
    const PortfolioScreen(), // 1: Портфель (IBKR, Універ)
    const MidasScreen(), // 2: Мідас (Калькулятор багатства)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack зберігає стан сторінок (не перезавантажує їх при перемиканні)
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(
          0xFF00C853,
        ), // Зелений колір активної вкладки
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Додому',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Портфель',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph), // Іконка графіка для стратегії
            label: 'Midas',
          ),
        ],
      ),
    );
  }
}
