import 'package:flutter/material.dart';
import '../../../services/midas_calculation_service.dart';
import '../../../domain/models/midas_models.dart';

class MathBreakdownSheet extends StatelessWidget {
  final DCARecommendation recommendation;
  final double availableCash;
  final int weeksSinceStart;
  final MidasCalculationService service;

  const MathBreakdownSheet({
    super.key,
    required this.recommendation,
    required this.availableCash,
    required this.weeksSinceStart,
    MidasCalculationService? service,
  }) : service = service ?? const MidasCalculationService();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calculate,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Чому саме ця сума?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${recommendation.symbol} - ${recommendation.action}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Math Breakdown Cards
            _buildMathCard(
              '📅 Ідеальний план за $weeksSinceStart тижнів',
              '$weeksSinceStart тижнів × \$1/тиждень = ${service.formatCurrency(recommendation.targetValue)}',
              'Цільова вартість згідно з Excel L32 формулою',
              Colors.blue,
            ),

            const SizedBox(height: 12),

            _buildMathCard(
              '💰 Поточна вартість активу',
              '${recommendation.currentValue.toStringAsFixed(2)} × ${recommendation.symbol}',
              'Ціна × Кількість акцій',
              Colors.green,
            ),

            const SizedBox(height: 12),

            _buildMathCard(
              '📊 Загальний розрив (Gap)',
              '${service.formatCurrency(recommendation.targetValue)} - ${service.formatCurrency(recommendation.currentValue)} = ${service.formatCurrency(recommendation.deviation)}',
              recommendation.deviation > 0
                  ? 'Потрібно докупити для досягнення цілі'
                  : 'Актив перевиконує план',
              recommendation.deviation > 0 ? Colors.orange : Colors.purple,
            ),

            // Budget Correction Section
            if (recommendation.isCashAdjusted) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.1),
                      Colors.orange.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.amber,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Коригування на бюджет',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Твій розрив ${service.formatCurrency(recommendation.amount)}, але ми купуємо на ${service.formatCurrency(recommendation.adjustedAmount)}, щоб збалансувати інші акції.',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Доступно: ${service.formatCurrency(availableCash)} | Ідеальна потреба: ${service.formatCurrency(recommendation.amount)}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // DCA Strategy Explanation
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📈 Як працює DCA стратегія',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DCA (Dollar Cost Averaging) — це усереднення вартості. '
                    'Коли акція дешевшає за план, ми купуємо більше. '
                    'Коли дорожча — менше. Це знижує ризик та стабілізує портфель.',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Закрити'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Зрозуміло',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMathCard(
    String title,
    String formula,
    String explanation,
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
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              formula,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
