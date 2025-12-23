import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'midas_data.dart'; // Дані
import 'stock_detail_screen.dart'; // Екран деталей

class MidasScreen extends StatefulWidget {
  const MidasScreen({super.key});

  @override
  State<MidasScreen> createState() => _MidasScreenState();
}

class _MidasScreenState extends State<MidasScreen> {
  // --- СТАН ---
  bool _isAnalyticsMode = false;
  bool _useBotStrategy = true;
  int _years = 20;
  double _weeklyPerStock = 1.0;

  late TextEditingController _yearsController;
  late TextEditingController _amountController;
  SortType _currentSort = SortType.profitDesc;

  late List<Map<String, dynamic>> _analyticsPortfolio;
  final int _stockCount = tickersList.length;

  @override
  void initState() {
    super.initState();
    _yearsController = TextEditingController(text: _years.toString());
    _amountController = TextEditingController(text: _weeklyPerStock.toString());
    _regenerateAnalyticsData();
  }

  @override
  void dispose() {
    _yearsController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // --- ЛОГІКА РОЗРАХУНКУ ---
  void _regenerateAnalyticsData() {
    int totalMonths = _years * 12;

    _analyticsPortfolio = tickersList.map((ticker) {
      final profile = getStockProfile(ticker);
      double currentPrice = profile['price']!;
      double annualGrowth = profile['growth']!;

      double botBonus = _useBotStrategy ? 0.08 : 0.0;
      double totalEffectiveGrowth = annualGrowth + botBonus;

      double growthFactor = math
          .pow(1 + totalEffectiveGrowth, _years * 0.85)
          .toDouble();
      double myAvgPrice = currentPrice / growthFactor;

      double totalInvestedInStock = (_weeklyPerStock * 52 / 12) * totalMonths;
      double qty = totalInvestedInStock / myAvgPrice;

      return {
        "symbol": ticker,
        "name": getStockName(ticker),
        "qty": qty,
        "avgPrice": myAvgPrice,
        "currentPrice": currentPrice,
        "profitPercent": ((currentPrice - myAvgPrice) / myAvgPrice) * 100,
        "totalValue": qty * currentPrice,
      };
    }).toList();

    // Сортування
    switch (_currentSort) {
      case SortType.profitDesc:
        _analyticsPortfolio.sort(
          (a, b) => b['profitPercent'].compareTo(a['profitPercent']),
        );
        break;
      case SortType.profitAsc:
        _analyticsPortfolio.sort(
          (a, b) => a['profitPercent'].compareTo(b['profitPercent']),
        );
        break;
      case SortType.nameAsc:
        _analyticsPortfolio.sort((a, b) => a['symbol'].compareTo(b['symbol']));
        break;
      case SortType.valueDesc:
        _analyticsPortfolio.sort(
          (a, b) => b['totalValue'].compareTo(a['totalValue']),
        );
        break;
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          // bottom: false тут немає, тому кнопки телефону не закриють контент
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: _isAnalyticsMode
                    ? _buildAnalyticsBody()
                    : _buildSimulatorBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 70,
      backgroundColor: const Color(0xFF0F0F0F),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAnalyticsMode ? "АНАЛІТИКА" : "СИМУЛЯТОР",
                style: TextStyle(
                  color: _isAnalyticsMode
                      ? const Color(0xFF00C853)
                      : const Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                "Million Dollar Way",
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          Switch(
            value: _isAnalyticsMode,
            activeColor: const Color(0xFF00C853),
            inactiveTrackColor: Colors.white10,
            onChanged: (val) => setState(() => _isAnalyticsMode = val),
          ),
        ],
      ),
    );
  }

  // --- UI БЛОКИ ---
  Widget _buildDescriptionBox(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsBlock({bool showBotSwitch = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "НАЛАШТУВАННЯ",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Період (років):",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _yearsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    suffixText: "р",
                    suffixStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  onChanged: (val) {
                    setState(() {
                      int? y = int.tryParse(val);
                      if (y != null) {
                        _years = y;
                        _regenerateAnalyticsData();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  "В 1 акцію (тиждень):",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    suffixText: "\$",
                    suffixStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  onChanged: (val) {
                    setState(() {
                      double? v = double.tryParse(val.replaceAll(',', '.'));
                      if (v != null) {
                        _weeklyPerStock = v;
                        _regenerateAnalyticsData();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          if (showBotSwitch) ...[
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Використовувати Бота?",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Switch(
                  value: _useBotStrategy,
                  activeColor: const Color(0xFF00C853),
                  onChanged: (val) => setState(() => _useBotStrategy = val),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- АНАЛІТИКА ---
  Widget _buildAnalyticsBody() {
    double totalValue = 0;
    double totalInvested = 0;
    for (var s in _analyticsPortfolio) {
      totalValue += s['totalValue'];
      totalInvested += s['qty'] * s['avgPrice'];
    }
    double totalProfit = totalValue - totalInvested;

    return Column(
      children: [
        _buildDescriptionBox(
          "Історичний аналіз",
          "Подивіться, скільки б ви заробили, якби почали інвестувати в минулому.",
        ),
        _buildAnalyticsHeader(totalValue, totalInvested, totalProfit),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: "Якби ви вкладали по "),
                TextSpan(
                  text: "${_weeklyPerStock.toStringAsFixed(2)}\$",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const TextSpan(text: " в кожну акцію щотижня рівно "),
                TextSpan(
                  text: "$_years р",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const TextSpan(
                  text: " тому, то сьогодні ваш капітал виглядав би так:",
                ),
              ],
            ),
          ),
        ),
        _buildSettingsBlock(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSortButton(),
              Row(
                children: [
                  Text(
                    "Бот",
                    style: TextStyle(
                      color: _useBotStrategy
                          ? const Color(0xFF00C853)
                          : Colors.grey,
                    ),
                  ),
                  Switch(
                    value: _useBotStrategy,
                    activeColor: const Color(0xFF00C853),
                    onChanged: (val) => setState(() {
                      _useBotStrategy = val;
                      _regenerateAnalyticsData();
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Використовуємо ListView з shrinkWrap і вимикаємо власний скрол
        ListView.builder(
          primary: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _analyticsPortfolio.length,
          itemBuilder: (ctx, i) => _buildAnalyticsCard(_analyticsPortfolio[i]),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  // --- СИМУЛЯТОР ---
  Widget _buildSimulatorBody() {
    double monthlyTotal = (_stockCount * _weeklyPerStock * 52) / 12;
    int totalMonths = _years * 12;
    double totalInvested = (monthlyTotal) * totalMonths;
    double annualRate = _useBotStrategy ? 0.20 : 0.10;
    double monthlyRate = annualRate / 12;
    double estimatedValue =
        totalInvested * math.pow(1 + monthlyRate, totalMonths);
    double profit = estimatedValue - totalInvested;

    return Column(
      children: [
        _buildDescriptionBox(
          "Прогноз майбутнього",
          "Математична модель складного відсотка. Увімкніть 'Бота', щоб побачити ефект стратегії.",
        ),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFF1A1A1A)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ВАШ ПЛАН:",
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _useBotStrategy
                          ? "🚀 Ефективність: ~20%/рік"
                          : "🐌 Ринок: ~10%/рік",
                      style: TextStyle(
                        color: _useBotStrategy
                            ? const Color(0xFF00C853)
                            : Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: "Вкладаючи по "),
                    TextSpan(
                      text: "${monthlyTotal.toStringAsFixed(0)}\$ в місяць",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(text: " протягом "),
                    TextSpan(
                      text: "$_years р",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const TextSpan(text: ", ви отримаєте:"),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  "${formatMoney(estimatedValue)} \$",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Внески",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        Text(
                          "${formatMoney(totalInvested)} \$",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text("+", style: TextStyle(color: Colors.white30)),
                    Column(
                      children: [
                        const Text(
                          "Відсотки",
                          style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          "${formatMoney(profit)} \$",
                          style: const TextStyle(
                            color: Color(0xFF00C853),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildSettingsBlock(showBotSwitch: true),
        const SizedBox(height: 50),
      ],
    );
  }

  // --- КОМПОНЕНТИ ---
  Widget _buildAnalyticsHeader(double value, double invested, double profit) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00C853).withOpacity(0.2),
            const Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "${formatMoney(value)} \$",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn(
                "Вкладено",
                "${formatMoney(invested)} \$",
                Colors.white70,
              ),
              _statColumn(
                "Прибуток",
                "+${formatMoney(profit)} \$",
                const Color(0xFF00C853),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailScreen(
              stock: item,
              useBot: _useBotStrategy,
              yearsTotal: _years, // Передаємо вибрані роки
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                item['symbol'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ринок: ${item['currentPrice'].toStringAsFixed(0)}\$",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    "Вхід: ${item['avgPrice'].toStringAsFixed(2)}\$",
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${formatMoney(item['totalValue'])} \$",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${item['profitPercent'].toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Color(0xFF00C853),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<SortType>(
      color: const Color(0xFF1A1A1A),
      onSelected: (SortType result) {
        setState(() {
          _currentSort = result;
          _regenerateAnalyticsData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.sort, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              _getSortName(_currentSort),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SortType>>[
        const PopupMenuItem<SortType>(
          value: SortType.profitDesc,
          child: Text(
            '🔥 Прибуток (Найкращі)',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const PopupMenuItem<SortType>(
          value: SortType.profitAsc,
          child: Text(
            '📉 Прибуток (Найгірші)',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const PopupMenuItem<SortType>(
          value: SortType.valueDesc,
          child: Text(
            '💰 Баланс (Найбільші)',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const PopupMenuItem<SortType>(
          value: SortType.nameAsc,
          child: Text('🔤 Назва (A-Z)', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  String _getSortName(SortType type) {
    switch (type) {
      case SortType.profitDesc:
        return "Топ прибутку";
      case SortType.profitAsc:
        return "Аутсайдери";
      case SortType.valueDesc:
        return "Найбільші позиції";
      case SortType.nameAsc:
        return "За назвою";
    }
  }

  Widget _statColumn(String label, String value, Color color) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ],
  );
}
