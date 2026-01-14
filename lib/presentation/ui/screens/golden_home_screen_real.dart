import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:million_dollar_way/providers/real_portfolio_provider.dart';
import 'package:million_dollar_way/domain/models/stock_models.dart';
import 'package:million_dollar_way/services/market_data_service.dart';
import 'package:million_dollar_way/services/demo_data_service.dart';

class GoldenHomeScreen extends ConsumerStatefulWidget {
  const GoldenHomeScreen({super.key});

  @override
  ConsumerState<GoldenHomeScreen> createState() => _GoldenHomeScreenState();
}

class _GoldenHomeScreenState extends ConsumerState<GoldenHomeScreen> {
  final TextEditingController _cashController = TextEditingController(
    text: '120.0',
  );
  final TextEditingController _tickerController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Автоматично оновлюємо ціни кожні 30 секунд
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        ref.read(realPortfolioProvider.notifier).updatePrices();
        _startAutoRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final portfolioState = ref.watch(realPortfolioProvider);
    final portfolioNotifier = ref.read(realPortfolioProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Million Dollar Way',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (portfolioState.hasData)
            IconButton(
              onPressed: portfolioState.isUpdatingPrices
                  ? null
                  : () {
                      portfolioNotifier.updatePrices();
                    },
              icon: portfolioState.isUpdatingPrices
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.amber),
            ),
          IconButton(
            onPressed: () => _showAddPositionDialog(),
            icon: const Icon(Icons.add, color: Colors.amber),
            tooltip: 'Додати позицію',
          ),
        ],
      ),
      body: Column(
        children: [
          // Demo Mode Banner
          if (portfolioState.isDemoMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.2),
                    Colors.amber.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚡ Ви в демо-режимі. Бачите, як працює стратегія DCA на 51 акції.',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Main Content
          Expanded(
            child: portfolioState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  )
                : !portfolioState.hasData
                ? _buildEmptyState(portfolioNotifier, portfolioState)
                : _buildPortfolioView(portfolioState, portfolioNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    RealPortfolioProvider portfolioNotifier,
    RealPortfolioState portfolioState,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.file_upload,
                size: 60,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '0.00',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'ЗАВАНТАЖТИ IBKR XML',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Будь ласка, завантажте звіт IBKR\nдля відображення реальних даних портфоліо',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => portfolioNotifier.loadFromIBKRFile(),
              icon: const Icon(Icons.file_upload),
              label: const Text('ЗАВАНТАЖТИ IBKR XML'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (portfolioState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  portfolioState.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioView(
    RealPortfolioState state,
    RealPortfolioProvider notifier,
  ) {
    final portfolio = state.portfolio;
    final availableCash = double.tryParse(_cashController.text) ?? 0.0;
    final priorityBuys = notifier.getPriorityBuyList(availableCash);
    final growthProjection = DemoDataService.instance.calculateGrowthProjection(
      portfolio,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortfolioHeader(portfolio, state.lastUpdate),
          const SizedBox(height: 24),
          _buildPortfolioMetrics(portfolio),
          const SizedBox(height: 24),

          // Шлях до Мільйона
          _buildMillionDollarPath(growthProjection),
          const SizedBox(height: 24),

          _buildCashInput(),
          const SizedBox(height: 24),

          if (priorityBuys.isNotEmpty) ...[
            _buildPriorityBuys(priorityBuys, availableCash),
            const SizedBox(height: 24),
          ],

          _buildPositionsList(portfolio.positions),
        ],
      ),
    );
  }

  Widget _buildPortfolioHeader(Portfolio portfolio, DateTime? lastUpdate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.amber.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Мій Портфоліо',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (lastUpdate != null)
                Text(
                  'Оновлено ${_formatTime(lastUpdate)}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            MarketDataService.formatPrice(portfolio.totalValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: portfolio.totalPnL >= 0
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  MarketDataService.formatPercentage(portfolio.totalPnLPercent),
                  style: TextStyle(
                    color: portfolio.totalPnL >= 0 ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                MarketDataService.formatPrice(portfolio.totalPnL),
                style: TextStyle(
                  color: portfolio.totalPnL >= 0 ? Colors.green : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMillionDollarPath(Map<String, dynamic> growthProjection) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.purple, size: 24),
              SizedBox(width: 8),
              Text(
                'Шлях до Мільйона',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Поточна вартість',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      MarketDataService.formatPrice(
                        growthProjection['currentValue'],
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Мета',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      MarketDataService.formatPrice(
                        growthProjection['targetValue'],
                      ),
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor:
                  growthProjection['currentValue'] /
                  growthProjection['targetValue'],
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Для досягнення мети за ${growthProjection['yearsToTarget']} років потрібно ${(growthProjection['requiredAnnualReturn'] as double).toStringAsFixed(1)}% річних',
            style: TextStyle(
              color: growthProjection['isRealistic']
                  ? Colors.green
                  : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioMetrics(Portfolio portfolio) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Позицій',
            portfolio.positions.length.toString(),
            Icons.pie_chart,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Середня ціна',
            MarketDataService.formatPrice(
              portfolio.totalCost / portfolio.positions.length,
            ),
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'P&L',
            MarketDataService.formatPercentage(portfolio.totalPnLPercent),
            Icons.trending_up,
            portfolio.totalPnL >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCashInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Доступний кеш',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cashController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Введіть суму',
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.amber.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.amber.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => setState(() {}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text('Оновити'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBuys(
    List<StockRecommendation> buys,
    double availableCash,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Пріоритетні покупки',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Кеш: ${MarketDataService.formatPrice(availableCash)}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...buys.take(5).map((buy) => _buildPriorityBuyItem(buy)),
        ],
      ),
    );
  }

  Widget _buildPriorityBuyItem(StockRecommendation buy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  buy.symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Розрив: ${MarketDataService.formatPrice(buy.gap)}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            MarketDataService.formatPrice(buy.recommendedAmount),
            style: const TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Всі позиції',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...positions.map((position) => _buildPositionItem(position)),
        ],
      ),
    );
  }

  Widget _buildPositionItem(StockPosition position) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${position.quantity.toStringAsFixed(2)} × ${MarketDataService.formatPrice(position.averagePrice)}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MarketDataService.formatPrice(position.currentValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                MarketDataService.formatPercentage(position.pnlPercent),
                style: TextStyle(
                  color: position.pnl >= 0 ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showAddPositionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Додати позицію',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tickerController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Тікер (напр. TSLA)',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Кількість',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Скасувати',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _addPosition();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Додати'),
            ),
          ],
        );
      },
    );
  }

  void _addPosition() {
    final ticker = _tickerController.text.toUpperCase().trim();
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;

    if (ticker.isEmpty || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Будь ласка, введіть правильний тікер та кількість'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Очищуємо поля
    _tickerController.clear();
    _quantityController.clear();

    // Показуємо повідомлення про успішне додавання
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Позицію $ticker додано!'),
        backgroundColor: Colors.green,
      ),
    );

    // Тут можна додати логіку для реального додавання позиції
    // Поки що просто показуємо повідомлення
  }
}
