import 'package:flutter/material.dart';

class GlobalStrategyInfo extends StatelessWidget {
  const GlobalStrategyInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Як працює мій портфель?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Strategy Explanation
          const Text(
            'Твій капітал росте не тільки від твоїх внесків, а й від росту цін активів. '
            'Midas AI використовує стратегію DCA (усереднення вартості), щоб зробити '
            'інвестування стабільнішим та прибутковішим.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 16),

          // Key Principles
          _buildPrincipleCard(
            '📈 Якщо акція росте швидше за план',
            'Midas AI рекомендує купувати її менше або чекати. '
                'Це захищає від переплати за актив.',
            Colors.green,
          ),

          const SizedBox(height: 8),

          _buildPrincipleCard(
            '📉 Якщо акція падає або відстає',
            'Midas AI рекомендує купувати більше. '
                'Це дозволяє купувати акції за зниженою ціною.',
            Colors.orange,
          ),

          const SizedBox(height: 8),

          _buildPrincipleCard(
            '⚖️ Автоматичний баланс',
            'Система постійно підтримує баланс між 51 активом, '
                'розподіляючи кошти пріоритетно на найбільші розриви.',
            Colors.purple,
          ),

          const SizedBox(height: 16),

          // Excel Formula Reference
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🧮 Формула Excel L32',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Target = WeeksSinceStart × \$1/week',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Кожна долар, рекомендована ботом, простежується до цієї формули.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Transparency Note
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Немає "чорних скриньок" - кожна рекомендація повністю прозора.',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipleCard(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
