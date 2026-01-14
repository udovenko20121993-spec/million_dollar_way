import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:million_dollar_way/services/market_data_service.dart';
import 'package:million_dollar_way/services/market_digest_service.dart';
import 'package:million_dollar_way/services/notification_service.dart';

class MarketPulseWidget extends ConsumerStatefulWidget {
  const MarketPulseWidget({super.key});

  @override
  ConsumerState<MarketPulseWidget> createState() => _MarketPulseWidgetState();
}

class _MarketPulseWidgetState extends ConsumerState<MarketPulseWidget> {
  bool _isLoading = false;
  Map<String, double> _dailyChanges = {};
  MarketDigest? _lastDigest;

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Отримуємо щоденні зміни
      final changes = await MarketDataService.instance.getAllDailyChanges();

      // Генеруємо дайджест
      final digest = await MarketDigestService.instance.generateDailySummary();

      setState(() {
        _dailyChanges = changes;
        _lastDigest = digest;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading market data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAndNotify() async {
    await _loadMarketData();

    if (_lastDigest != null) {
      // Відправляємо сповіщення
      final notificationService = NotificationService();
      await notificationService.sendMarketDigestNotification(_lastDigest!);

      // Показуємо SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📊 Дайджест відправлено!'),
            backgroundColor: Color(0xFFEAB308),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFFEAB308), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Пульс ринку за сьогодні',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!_isLoading)
                IconButton(
                  onPressed: _refreshAndNotify,
                  icon: const Icon(Icons.refresh, color: Color(0xFFEAB308)),
                  tooltip: 'Refresh & Notify',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Статистика
          if (_lastDigest != null) ...[
            _buildDigestStats(_lastDigest!),
            const SizedBox(height: 16),
          ],

          // Завантаження
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEAB308)),
              ),
            ),

          // Список акцій
          if (!_isLoading && _dailyChanges.isNotEmpty) ...[
            _buildStocksList(),
            const SizedBox(height: 16),
          ],

          // Кнопка оновлення
          if (!_isLoading)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _refreshAndNotify,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Refresh & Notify'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAB308),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDigestStats(MarketDigest digest) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            digest.summary,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip('📈 ${digest.gainersCount}', Colors.green),
              const SizedBox(width: 8),
              _buildStatChip('📉 ${digest.losersCount}', Colors.red),
              const SizedBox(width: 8),
              _buildStatChip(
                MarketDigestService.formatChange(digest.averageChange),
                digest.averageChange >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStocksList() {
    final symbols = MarketDigestService.instance.getAllSymbols();

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: symbols.length,
        itemBuilder: (context, index) {
          final symbol = symbols[index];
          final change = _dailyChanges[symbol] ?? 0.0;
          final color = MarketDigestService.getChangeColor(change);

          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _parseColor(color),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  MarketDigestService.formatChange(change),
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _parseColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
