import 'package:flutter/material.dart';
// Імпортуємо твій існуючий дашборд IBKR
import 'package:million_dollar_way/presentation/dashboard/screen/dashboard_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Кількість вкладок: IBKR, Універ, Приват, ICU, Inzhur
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            "Мій Портфель",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable:
                true, // Дозволяє гортати назви вкладок, якщо вони не влазять
            indicatorColor: Color(0xFF00C853),
            labelColor: Color(0xFF00C853),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "IBKR"),
              Tab(text: "Фонд Універ"),
              Tab(text: "Приват Фонд"),
              Tab(text: "ICU"),
              Tab(text: "Inzhur"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 1. Вкладка IBKR (використовуємо твій готовий дашборд)
            IBKRDashboard(),

            // Заглушки для інших фондів (потім наповнимо)
            Center(
              child: Text(
                "Дані Фонд Універ",
                style: TextStyle(color: Colors.white),
              ),
            ),
            Center(
              child: Text(
                "Дані Приват Фонд",
                style: TextStyle(color: Colors.white),
              ),
            ),
            Center(
              child: Text("Дані ICU", style: TextStyle(color: Colors.white)),
            ),
            Center(
              child: Text("Дані Inzhur", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
