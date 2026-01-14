import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/mdw_engine.dart';
import '../widgets/market_pulse_widget.dart';

class GoldenDashboardScreen extends ConsumerStatefulWidget {
  const GoldenDashboardScreen({super.key});

  @override
  ConsumerState<GoldenDashboardScreen> createState() =>
      _GoldenDashboardScreenState();
}

class _GoldenDashboardScreenState extends ConsumerState<GoldenDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final mdwEngine = MDWEngine.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildAppBar(),
      body: _buildMainContent(mdwEngine),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.trending_up, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'MDW Dashboard',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showTaxCalculator(),
          icon: const Icon(Icons.calculate, color: Color(0xFFD4AF37)),
        ),
      ],
    );
  }

  Widget _buildMainContent(MDWEngine mdwEngine) {
    // Створюємо демонстраційні позиції
    final demoPositions = _createDemoPositions();
    final portfolioStats = mdwEngine.calculatePortfolioStats(
      demoPositions,
      150.0,
    );
    final allocations = mdwEngine.distributeCash(demoPositions, 150.0);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(portfolioStats),
            const SizedBox(height: 24),

            const MarketPulseWidget(),
            const SizedBox(height: 24),

            _buildPortfolioStats(portfolioStats),
            const SizedBox(height: 24),

            _buildL32Recommendations(allocations),
            const SizedBox(height: 24),

            _buildPositionsList(demoPositions),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(PortfolioStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ласкаво просимо до MDW',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ваш капітал',
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                    Text(
                      '\$${stats.netCapital.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (stats.totalPnL != 0)
                      Text(
                        '${stats.totalPnL >= 0 ? '+' : ''}${stats.totalPnL.toStringAsFixed(2)} (${stats.totalPnLPercent.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: stats.totalPnL >= 0
                              ? Colors.black87
                              : Colors.red.shade900,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${stats.totalPositions} акцій',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioStats(PortfolioStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Статистика портфоліо',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Акції',
                  '\$${stats.totalValue.toStringAsFixed(2)}',
                  Icons.show_chart,
                  stats.totalPnL >= 0 ? const Color(0xFF10B981) : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Кеш',
                  '\$${stats.cashAmount.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  const Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildL32Recommendations(List<StockAllocation> allocations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤖 L32 Рекомендації',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (allocations.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Всі акції відповідають L32 цілям',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...allocations.map(
              (allocation) => _buildAllocationCard(allocation),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllocationCard(StockAllocation allocation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Купити ${allocation.ticker}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Сума: \$${allocation.amount.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            'Акцій: ~${allocation.estimatedShares.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            'Відставання: \$${allocation.deviation.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionsList(List<StockPosition> positions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Позиції',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...positions.take(10).map((position) => _buildPositionCard(position)),
        ],
      ),
    );
  }

  Widget _buildPositionCard(StockPosition position) {
    final pnlColor = position.unrealizedPnL >= 0
        ? const Color(0xFF10B981)
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.ticker,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${position.quantity} шт',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${position.currentValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${position.currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${position.unrealizedPnL >= 0 ? '+' : ''}${position.unrealizedPnL.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${position.unrealizedPnLPercent >= 0 ? '+' : ''}${position.unrealizedPnLPercent.toStringAsFixed(1)}%',
                  style: TextStyle(color: pnlColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<StockPosition> _createDemoPositions() {
    // Створюємо демонстраційні позиції для топ 10 акцій
    final topTickers = [
      'AAPL',
      'MSFT',
      'GOOGL',
      'AMZN',
      'META',
      'TSLA',
      'NVDA',
      'JPM',
      'JNJ',
      'V',
    ];

    return topTickers.map((ticker) {
      final price = 100.0 + (ticker.hashCode % 200); // Демонстраційна ціна
      final quantity = (150 / price).floor(); // Розподіляємо $150 на акції
      final costBasis = price * 0.95; // Припустимо, що купили на 5% дешевше

      return StockPosition(
        ticker: ticker,
        quantity: quantity,
        costBasis: costBasis,
        currentPrice: price,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );
    }).toList();
  }

  void _showTaxCalculator() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => _buildTaxCalculatorSheet(),
    );
  }

  Widget _buildTaxCalculatorSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🧾 Податковий калькулятор',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildTaxProfileOption('Цивільний', '18% + 5%'),
          _buildTaxProfileOption('Військовий', '18% + 0%'),
          _buildTaxProfileOption('ФОП 3 група', '5% + 1%'),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Податковий калькулятор у розробці'),
                    backgroundColor: Color(0xFFD4AF37),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Розрахувати податки'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxProfileOption(String title, String rates) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Radio<String>(
            value: title,
            groupValue: 'Цивільний', // Demo value
            onChanged: (value) {},
            activeColor: const Color(0xFFD4AF37),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  rates,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
