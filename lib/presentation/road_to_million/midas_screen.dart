import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'midas_data.dart';
import 'stock_detail_screen.dart';
import '../../models/midas_settings.dart';
import '../../services/midas_service.dart';

class MidasScreen extends StatefulWidget {
  const MidasScreen({super.key});

  @override
  State<MidasScreen> createState() => _MidasScreenState();
}

class _MidasScreenState extends State<MidasScreen> with SingleTickerProviderStateMixin {
  // --- СТАН ---
  final String userId = "user_test_1";
  late MidasService _midasService;
  
  bool _isAnalyticsMode = false;
  bool _useBotStrategy = true;
  int _years = 20;
  double _weeklyPerStock = 1.0;
  double _targetAmount = 1000000;

  late TextEditingController _yearsController;
  late TextEditingController _amountController;
  SortType _currentSort = SortType.profitDesc;

  late List<Map<String, dynamic>> _analyticsPortfolio;
  final int _stockCount = tickersList.length;
  
  // Milestones
  List<MidasMilestone> _milestones = getDefaultMilestones();
  
  // IBKR порівняння
  IBKRComparison? _ibkrComparison;
  bool _isLoadingIBKR = false;

  // Анімація
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _midasService = MidasService(userId: userId);
    _yearsController = TextEditingController(text: _years.toString());
    _amountController = TextEditingController(text: _weeklyPerStock.toString());
    
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeOutCubic),
    );
    
    _loadSettings();
    _regenerateAnalyticsData();
  }

  Future<void> _loadSettings() async {
    final settings = await _midasService.getSettings();
    setState(() {
      _years = settings.years;
      _weeklyPerStock = settings.weeklyPerStock;
      _useBotStrategy = settings.useBotStrategy;
      _targetAmount = settings.targetAmount;
      _milestones = settings.achievedMilestones.isEmpty 
          ? getDefaultMilestones() 
          : settings.achievedMilestones;
      
      _yearsController.text = _years.toString();
      _amountController.text = _weeklyPerStock.toString();
    });
    _regenerateAnalyticsData();
    _progressAnimationController.forward();
    _loadIBKRComparison();
  }

  Future<void> _saveSettings() async {
    await _midasService.saveSettings(MidasSettings(
      years: _years,
      weeklyPerStock: _weeklyPerStock,
      useBotStrategy: _useBotStrategy,
      targetAmount: _targetAmount,
      achievedMilestones: _milestones,
    ));
  }

  Future<void> _loadIBKRComparison() async {
    setState(() => _isLoadingIBKR = true);
    final comparison = await _midasService.getIBKRComparison();
    setState(() {
      _ibkrComparison = comparison;
      _isLoadingIBKR = false;
    });
  }

  @override
  void dispose() {
    _yearsController.dispose();
    _amountController.dispose();
    _progressAnimationController.dispose();
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

      double growthFactor = math.pow(1 + totalEffectiveGrowth, _years * 0.85).toDouble();
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
        _analyticsPortfolio.sort((a, b) => b['profitPercent'].compareTo(a['profitPercent']));
        break;
      case SortType.profitAsc:
        _analyticsPortfolio.sort((a, b) => a['profitPercent'].compareTo(b['profitPercent']));
        break;
      case SortType.nameAsc:
        _analyticsPortfolio.sort((a, b) => a['symbol'].compareTo(b['symbol']));
        break;
      case SortType.valueDesc:
        _analyticsPortfolio.sort((a, b) => b['totalValue'].compareTo(a['totalValue']));
        break;
    }
  }

  SimulationResult _getSimulationResult() {
    return _midasService.calculateSimulation(
      years: _years,
      weeklyPerStock: _weeklyPerStock,
      stockCount: _stockCount,
      useBot: _useBotStrategy,
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: _isAnalyticsMode ? _buildAnalyticsBody() : _buildSimulatorBody(),
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
                  color: _isAnalyticsMode ? const Color(0xFF00C853) : const Color(0xFFD4AF37),
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
          Row(
            children: [
              // Кнопка збереження
              IconButton(
                icon: const Icon(Icons.save_outlined, color: Colors.grey, size: 20),
                onPressed: () {
                  _saveSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Налаштування збережено'),
                      backgroundColor: Color(0xFF00C853),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              Switch(
                value: _isAnalyticsMode,
                activeColor: const Color(0xFF00C853),
                inactiveTrackColor: Colors.white10,
                onChanged: (val) => setState(() => _isAnalyticsMode = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === СИМУЛЯТОР ===
  Widget _buildSimulatorBody() {
    final result = _getSimulationResult();
    final progress = _midasService.calculateProgress(
      currentValue: result.estimatedValue,
      targetAmount: _targetAmount,
      monthlyContribution: result.monthlyContribution,
      annualRate: result.annualRate,
    );

    return Column(
      children: [
        _buildDescriptionBox(
          "Прогноз майбутнього",
          "Математична модель складного відсотка. Увімкніть 'Бота', щоб побачити ефект стратегії.",
        ),
        
        // === ГОЛОВНА КАРТКА ===
        _buildMainCard(result),
        
        // === ПРОГРЕС ДО МІЛЬЙОНА ===
        _buildProgressCard(progress, result),
        
        // === ГРАФІК ===
        _buildChartCard(result),
        
        // === MILESTONES ===
        _buildMilestonesCard(result.estimatedValue),
        
        // === IBKR ПОРІВНЯННЯ ===
        if (_ibkrComparison != null) _buildIBKRComparisonCard(),
        
        // === НАЛАШТУВАННЯ ===
        _buildSettingsBlock(showBotSwitch: true),
        
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildMainCard(SimulationResult result) {
    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _useBotStrategy ? "🚀 ~20%/рік" : "🐌 ~10%/рік",
                  style: TextStyle(
                    color: _useBotStrategy ? const Color(0xFF00C853) : Colors.white70,
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
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
              children: [
                const TextSpan(text: "Вкладаючи по "),
                TextSpan(
                  text: "${result.monthlyContribution.toStringAsFixed(0)}\$ в місяць",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const TextSpan(text: " протягом "),
                TextSpan(
                  text: "$_years р",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const TextSpan(text: ", ви отримаєте:"),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  "${formatMoney(result.estimatedValue * _progressAnimation.value)} \$",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                );
              },
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
                    const Text("Внески", style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text(
                      "${formatMoney(result.totalInvested)} \$",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Text("+", style: TextStyle(color: Colors.white30)),
                Column(
                  children: [
                    const Text("Відсотки", style: TextStyle(color: Color(0xFF00C853), fontSize: 10)),
                    Text(
                      "${formatMoney(result.profit)} \$",
                      style: const TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ProgressToGoal progress, SimulationResult result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🎯 ПРОГРЕС ДО МІЛЬЙОНА",
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                "${progress.progressPercent.toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Прогрес-бар
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (progress.progressPercent / 100) * _progressAnimation.value,
                  minHeight: 12,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress.progressPercent >= 100 
                        ? const Color(0xFF00C853) 
                        : const Color(0xFFD4AF37),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "💰 ${formatMoney(result.estimatedValue)} \$",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "/ ${formatMoney(_targetAmount)} \$",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          if (result.yearToMillion != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag, color: Color(0xFF00C853), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "Мільйон у ${result.yearToMillion} році!",
                    style: const TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartCard(SimulationResult result) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📈 ПРОГНОЗ КАПІТАЛУ",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _targetAmount / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '\$${(value / 1000).toStringAsFixed(0)}K',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= result.progressPoints.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          "'${result.progressPoints[index].year.toString().substring(2)}",
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: result.progressPoints.length - 1,
                minY: 0,
                maxY: math.max(result.estimatedValue, _targetAmount) * 1.1,
                lineBarsData: [
                  // Лінія цілі (мільйон)
                  LineChartBarData(
                    spots: List.generate(
                      result.progressPoints.length,
                      (i) => FlSpot(i.toDouble(), _targetAmount),
                    ),
                    isCurved: false,
                    color: Colors.white24,
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                  // Вкладено
                  LineChartBarData(
                    spots: result.progressPoints
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.invested))
                        .toList(),
                    isCurved: true,
                    color: Colors.white38,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  // Капітал
                  LineChartBarData(
                    spots: result.progressPoints
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                        .toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFF00C853)],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        if (index == result.progressPoints.length - 1) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: const Color(0xFF00C853),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD4AF37).withOpacity(0.3),
                          const Color(0xFF00C853).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Капітал", const Color(0xFF00C853)),
              const SizedBox(width: 20),
              _buildLegendItem("Вкладено", Colors.white38),
              const SizedBox(width: 20),
              _buildLegendItem("Ціль", Colors.white24, isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            border: isDashed ? Border.all(color: color, width: 1) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildMilestonesCard(double currentValue) {
    // Оновлюємо статус віх
    final updatedMilestones = _milestones.map((m) {
      if (!m.isAchieved && currentValue >= m.amount) {
        return m.copyWith(isAchieved: true, achievedAt: DateTime.now());
      }
      return m;
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🏆 ВІХИ НА ШЛЯХУ",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: updatedMilestones.map((m) {
              final isAchieved = currentValue >= m.amount;
              final progress = (currentValue / m.amount * 100).clamp(0, 100);
              
              return Container(
                width: (MediaQuery.of(context).size.width - 64) / 2 - 4,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAchieved 
                      ? const Color(0xFF00C853).withOpacity(0.1)
                      : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAchieved 
                        ? const Color(0xFF00C853).withOpacity(0.5)
                        : Colors.white10,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(m.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            m.title,
                            style: TextStyle(
                              color: isAchieved ? const Color(0xFF00C853) : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAchieved)
                          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 14),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "\$${formatMoney(m.amount)}",
                      style: TextStyle(
                        color: isAchieved ? const Color(0xFF00C853) : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    if (!isAchieved) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 3,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIBKRComparisonCard() {
    final comparison = _ibkrComparison!;
    final isAhead = comparison.isAheadOfPlan;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAhead 
            ? const Color(0xFF00C853).withOpacity(0.1)
            : Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAhead 
              ? const Color(0xFF00C853).withOpacity(0.3)
              : Colors.orangeAccent.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAhead ? Icons.trending_up : Icons.trending_down,
                color: isAhead ? const Color(0xFF00C853) : Colors.orangeAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "ПОРІВНЯННЯ З IBKR",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Реальність", style: TextStyle(color: Colors.grey, fontSize: 10)),
                  Text(
                    "\$${formatMoney(comparison.realBalance)}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    isAhead ? "випереджаєте" : "відстаєте",
                    style: TextStyle(
                      color: isAhead ? const Color(0xFF00C853) : Colors.orangeAccent,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    "${comparison.differencePercent >= 0 ? '+' : ''}${comparison.differencePercent.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: isAhead ? const Color(0xFF00C853) : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Симуляція", style: TextStyle(color: Colors.grey, fontSize: 10)),
                  Text(
                    "\$${formatMoney(comparison.simulatedBalance)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === АНАЛІТИКА ===
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
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              children: [
                const TextSpan(text: "Якби ви вкладали по "),
                TextSpan(
                  text: "${_weeklyPerStock.toStringAsFixed(2)}\$",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                ),
                const TextSpan(text: " в кожну акцію щотижня рівно "),
                TextSpan(
                  text: "$_years р",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                ),
                const TextSpan(text: " тому, то сьогодні ваш капітал виглядав би так:"),
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
                      color: _useBotStrategy ? const Color(0xFF00C853) : Colors.grey,
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

  // === КОМПОНЕНТИ ===
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
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
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
            style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.0),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text("Період (років):", style: TextStyle(color: Colors.white, fontSize: 16)),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    suffixText: "р",
                    suffixStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  onChanged: (val) {
                    int? y = int.tryParse(val);
                    if (y != null) {
                      setState(() {
                        _years = y;
                        _regenerateAnalyticsData();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Row(
            children: [
              const Expanded(
                child: Text("В 1 акцію (тиждень):", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    suffixText: "\$",
                    suffixStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  onChanged: (val) {
                    double? v = double.tryParse(val.replaceAll(',', '.'));
                    if (v != null) {
                      setState(() {
                        _weeklyPerStock = v;
                        _regenerateAnalyticsData();
                      });
                    }
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
                const Text("Використовувати Бота?", style: TextStyle(color: Colors.white, fontSize: 16)),
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
        ],
      ),
    );
  }

  Widget _buildAnalyticsHeader(double value, double invested, double profit) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00C853).withOpacity(0.2), const Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "${formatMoney(value)} \$",
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn("Вкладено", "${formatMoney(invested)} \$", Colors.white70),
              _statColumn("Прибуток", "+${formatMoney(profit)} \$", const Color(0xFF00C853)),
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
              yearsTotal: _years,
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${formatMoney(item['totalValue'])} \$",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${item['profitPercent'].toStringAsFixed(0)}%",
                  style: const TextStyle(color: Color(0xFF00C853), fontSize: 10),
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
            Text(_getSortName(_currentSort), style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SortType>>[
        const PopupMenuItem<SortType>(
          value: SortType.profitDesc,
          child: Text('🔥 Прибуток (Найкращі)', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem<SortType>(
          value: SortType.profitAsc,
          child: Text('📉 Прибуток (Найгірші)', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem<SortType>(
          value: SortType.valueDesc,
          child: Text('💰 Баланс (Найбільші)', style: TextStyle(color: Colors.white)),
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
      case SortType.profitDesc: return "Топ прибутку";
      case SortType.profitAsc: return "Аутсайдери";
      case SortType.valueDesc: return "Найбільші позиції";
      case SortType.nameAsc: return "За назвою";
    }
  }

  Widget _statColumn(String label, String value, Color color) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ],
  );
}
