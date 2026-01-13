import 'package:flutter/material.dart';
import 'package:million_dollar_way/models/ibkr_data.dart';

class StockDetailScreen extends StatefulWidget {
  final IBKRAsset asset;
  final List<IBKRTrade> trades;

  const StockDetailScreen({
    super.key,
    required this.asset,
    required this.trades,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  // Змінні для збереження готових розрахунків
  late List<IBKRTrade> _displayTrades;
  late double _currentPrice;
  late double _avgPrice;
  late double _totalInvested;
  late bool _isPos;
  late Color _mainColor;

  @override
  void initState() {
    super.initState();
    // РОБИМО ВСІ РОЗРАХУНКИ ТІЛЬКИ ОДИН РАЗ ТУТ
    _calculateData();
  }

  void _calculateData() {
    final asset = widget.asset;

    // 1. Кольори та ціни
    _isPos = asset.change >= 0;
    _mainColor = _isPos ? const Color(0xFF00C853) : const Color(0xFFFF3D00);

    _currentPrice = asset.quantity != 0 ? asset.value / asset.quantity : 0;
    _avgPrice = asset.quantity != 0
        ? (asset.value - asset.change) / asset.quantity
        : 0;
    _totalInvested = asset.value - asset.change;

    // 2. Обробка списку (найважча частина)
    // Фільтруємо
    final myTrades = widget.trades
        .where((t) => t.symbol == asset.symbol)
        .toList();

    // Сортуємо (швидке порівняння рядків)
    myTrades.sort((a, b) => b.date.compareTo(a.date));

    // Обмежуємо список (максимум 50 елементів), щоб UI не гальмував
    // Якщо у вас тисячі угод, це врятує додаток.
    _displayTrades = myTrades.take(50).toList();
  }

  // --- UI (Тут немає жодної логіки, тільки відображення) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          // ШАПКА
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F0F),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _mainColor.withOpacity(0.2),
                      const Color(0xFF0F0F0F),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    // Лого
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _mainColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _mainColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.asset.symbol.isNotEmpty
                              ? widget.asset.symbol.substring(0, 1)
                              : "?",
                          style: TextStyle(
                            color: _mainColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Ціна
                    Text(
                      "${widget.asset.value.toStringAsFixed(2)}\$",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    // Зміна
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _mainColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${_isPos ? '+' : ''}${widget.asset.change.toStringAsFixed(2)}\$",
                        style: TextStyle(
                          color: _mainColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // СТАТИСТИКА
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailBox(
                          "Кількість",
                          "${_formatQty(widget.asset.quantity)} шт",
                          Colors.white,
                          Icons.pie_chart,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailBox(
                          "Ціна ринку",
                          "${_currentPrice.toStringAsFixed(2)}\$",
                          Colors.blueAccent,
                          Icons.show_chart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailBox(
                          "Середня",
                          "${_avgPrice.toStringAsFixed(2)}\$",
                          Colors.orangeAccent,
                          Icons.price_check,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailBox(
                          "Вкладено",
                          "${_totalInvested.toStringAsFixed(0)}\$",
                          Colors.grey,
                          Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Останні операції",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Тут показуємо реальну кількість відображених угод
                      Text(
                        "${_displayTrades.length} ост.",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // СПИСОК УГОД
          _buildTradesList(),

          // Відступ для нижньої панелі навігації
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 50),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBox(
    String title,
    String value,
    Color valueColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradesList() {
    if (_displayTrades.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 100,
          alignment: Alignment.center,
          child: const Text(
            "Історія порожня",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Використовуємо SliverList з делегатом - це найшвидший спосіб для скролу
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final trade = _displayTrades[index];
        bool isBuy = trade.action.toUpperCase().contains('BUY');
        double totalAmount = trade.quantity * trade.price;
        Color tradeColor = isBuy
            ? const Color(0xFF00C853)
            : const Color(0xFFFF3D00);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tradeColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                color: tradeColor,
                size: 20,
              ),
            ),
            title: Text(
              isBuy ? "Купівля" : "Продаж",
              style: TextStyle(
                color: tradeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _simpleDate(trade.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  "${_formatQty(trade.quantity)} шт × ${trade.price.toStringAsFixed(2)}\$",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${totalAmount.toStringAsFixed(2)}\$",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (trade.commission != 0)
                  Text(
                    "Комісія: ${trade.commission.toStringAsFixed(2)}\$",
                    style: TextStyle(
                      color: Colors.redAccent.shade200,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        );
      }, childCount: _displayTrades.length),
    );
  }

  // --- Helpers ---
  String _simpleDate(String rawDate) {
    try {
      String s = rawDate.replaceAll(';', '').trim();
      if (s.length >= 8) {
        String year = s.substring(0, 4);
        String month = s.substring(4, 6);
        String day = s.substring(6, 8);
        return "$day.$month.$year";
      }
      return rawDate;
    } catch (e) {
      return rawDate;
    }
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toString();
  }
}
