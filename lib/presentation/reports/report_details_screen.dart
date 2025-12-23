import 'package:flutter/material.dart';
import 'package:million_dollar_way/models/ibkr_data.dart';

class IBKRReportDetailsScreen extends StatelessWidget {
  final IBKRReport report;

  const IBKRReportDetailsScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Три вкладки: Активи, Дивіденди, Угоди
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          title: Text(
            report.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFF00C853),
            labelColor: Color(0xFF00C853),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Активи"),
              Tab(text: "Дивіденди"),
              Tab(text: "Історія"),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildFinancialHeader(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAssetsList(),
                  _buildDividendsList(),
                  _buildTradesList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ВЕРХНЯ ЧАСТИНА: Загальний баланс та Кеш
  Widget _buildFinancialHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A1A1A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "NET LIQUIDITY",
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                "${report.lastBalance.toStringAsFixed(2)}\$",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(height: 40, width: 1, color: Colors.white10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "AVAILABLE CASH",
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                "${report.cashBalance.toStringAsFixed(2)}\$",
                style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ВКЛАДКА 1: Список Активів
  Widget _buildAssetsList() {
    if (report.assets.isEmpty) {
      return _buildEmptyState("Немає відкритих позицій");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: report.assets.length,
      itemBuilder: (context, index) {
        final asset = report.assets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              asset.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            // ВИПРАВЛЕННЯ ТУТ: Логіка для дробових акцій
            subtitle: Text(
              "${asset.quantity < 1 ? asset.quantity.toStringAsFixed(4) : asset.quantity.toStringAsFixed(1)} шт • ${asset.name}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${asset.value.toStringAsFixed(2)}\$",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${asset.change >= 0 ? '+' : ''}${asset.change.toStringAsFixed(2)}\$",
                  style: TextStyle(
                    color: asset.change >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ВКЛАДКА 2: Дивіденди
  Widget _buildDividendsList() {
    if (report.dividends.isEmpty) {
      return _buildEmptyState("Дивідендів ще не нараховано");
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Всього отримано: ${report.totalDividends.toStringAsFixed(2)}\$",
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: report.dividends.length,
            itemBuilder: (context, index) {
              final div = report.dividends[index];
              // Форматуємо дату, якщо вона є
              String dateStr = div.date;
              try {
                // IBKR іноді дає формат yyyyMMdd або yyyy-MM-dd
                if (div.date.length == 8) {
                  dateStr =
                      "${div.date.substring(6, 8)}.${div.date.substring(4, 6)}.${div.date.substring(0, 4)}";
                }
              } catch (_) {}

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: const Icon(
                      Icons.attach_money,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    div.symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    dateStr,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: Text(
                    "+${div.amount.toStringAsFixed(2)}\$",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ВКЛАДКА 3: Історія Торгів
  Widget _buildTradesList() {
    if (report.trades.isEmpty) {
      return _buildEmptyState("Історія торгів порожня");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: report.trades.length,
      itemBuilder: (context, index) {
        final trade = report.trades[index];
        final isBuy = trade.action.toUpperCase() == "BUY";

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isBuy
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                trade.action,
                style: TextStyle(
                  color: isBuy ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              trade.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${trade.quantity} шт @ ${trade.price.toStringAsFixed(2)}\$",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: Text(
              "${(trade.price * trade.quantity).toStringAsFixed(2)}\$",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }
}
