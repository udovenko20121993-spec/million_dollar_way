import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/market_hours_service.dart';

/// Віджет для відображення статусу ринку США
class MarketStatusWidget extends ConsumerStatefulWidget {
  const MarketStatusWidget({super.key});

  @override
  ConsumerState<MarketStatusWidget> createState() => _MarketStatusWidgetState();
}

class _MarketStatusWidgetState extends ConsumerState<MarketStatusWidget> {
  MarketInfo? _marketInfo;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateMarketInfo();

    // Оновлюємо кожну хвилину для точного часу
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateMarketInfo();
    });
  }

  void _updateMarketInfo() {
    setState(() {
      _marketInfo = MarketHoursService.getCurrentMarketInfo();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_marketInfo == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _marketInfo!.status.getColor(), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _marketInfo!.status.getIcon(),
                  size: 20,
                  color: _marketInfo!.status.getColor(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _marketInfo!.status.getDescription(),
                    style: TextStyle(
                      color: _marketInfo!.status.getColor(),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _marketInfo!.status.getColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _marketInfo!.nyTime,
                    style: TextStyle(
                      color: _marketInfo!.status.getColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Поточний час у Нью-Йорку та локація
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF757575),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Поточний час у Нью-Йорку: ${_marketInfo!.nyTime}',
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            const Row(
              children: [
                Icon(Icons.location_city, color: Color(0xFF757575), size: 16),
                SizedBox(width: 8),
                Text(
                  'NYSE & NASDAQ (New York)',
                  style: TextStyle(color: Color(0xFF757575), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Тип сесії
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFFD4AF37), size: 16),
                const SizedBox(width: 8),
                Text(
                  _getSessionType(_marketInfo!.kyivTime),
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Час до події
            if (_marketInfo!.status == MarketStatus.preMarket ||
                _marketInfo!.status == MarketStatus.closed)
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: Color(0xFFD4AF37),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _marketInfo!.timeToOpen ?? 'Невідомо',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

            if (_marketInfo!.status == MarketStatus.open)
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF4CAF50),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _marketInfo!.timeToClose ?? 'Невідомо',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

            if (_marketInfo!.status == MarketStatus.afterHours)
              Row(
                children: [
                  Icon(
                    Icons.nightlight,
                    color: _marketInfo!.status.getColor(),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Після закриття ринку',
                    style: TextStyle(
                      color: _marketInfo!.status.getColor(),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Час у Києві
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF757575),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Київ: ${_marketInfo!.kyivTime}',
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Визначення типу сесії за київським часом
  String _getSessionType(String kyivTime) {
    try {
      final now = DateTime.now();
      final kyivHour = now.hour; // Час у Києві

      if (kyivHour >= 11 && kyivHour < 16) {
        return 'Пре-маркет (11:00-16:30 Київ)';
      } else if (kyivHour >= 16 && kyivHour < 23) {
        return 'Основна сесія (16:30-23:00 Київ)';
      } else if (kyivHour >= 23 || kyivHour < 3) {
        return 'Пост-маркет (23:00-03:00 Київ)';
      } else {
        return 'Закрито (03:00-11:00 Київ)';
      }
    } catch (e) {
      return 'Невідомо';
    }
  }
}

/// Спеціалізований віджет для статусу синхронізації IBKR
class IbkrSyncStatusWidget extends StatelessWidget {
  final String status;
  final VoidCallback? onRefresh;

  const IbkrSyncStatusWidget({super.key, required this.status, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    if (status.contains('актуальні')) {
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle;
    } else if (status.contains('Помилка')) {
      statusColor = const Color(0xFFE53935);
      statusIcon = Icons.error;
    } else {
      statusColor = const Color(0xFFFB8C00);
      statusIcon = Icons.info;
    }

    return Card(
      color: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1F1F1F), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Статус даних',
                    style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onRefresh != null)
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Color(0xFF1E88E5)),
                tooltip: 'Оновити дані',
              ),
          ],
        ),
      ),
    );
  }
}
