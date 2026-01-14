import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ForecastExplanationDialog extends StatelessWidget {
  final double currentAmount;
  final double targetAmount;
  final double monthlyContribution;
  final double annualReturn;
  final int monthsToGoal;

  const ForecastExplanationDialog({
    super.key,
    required this.currentAmount,
    required this.targetAmount,
    required this.monthlyContribution,
    required this.annualReturn,
    required this.monthsToGoal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: colors.surfaceBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(Icons.calculate, color: colors.accentHighlight, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Як розраховано прогноз?',
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Формула
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.accentHighlight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.accentHighlight.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Формула складного відсотка:',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.accentHighlight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'FV = P×(1+r)^n + PMT×(((1+r)^n - 1)/r)',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.primaryText,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Пояснення параметрів
            _buildParameterExplanation(colors, textTheme),
            const SizedBox(height: 20),

            // Ваші дані
            _buildYourData(colors, textTheme),
            const SizedBox(height: 20),

            // Результат
            _buildResult(colors, textTheme),
            const SizedBox(height: 24),

            // Кнопка закриття
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Зрозуміло',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.accentHighlight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterExplanation(
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Що означають символи:',
          style: textTheme.titleMedium?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildParameterItem(
          'FV',
          'Майбутня вартість (цільова сума)',
          colors,
          textTheme,
        ),
        _buildParameterItem(
          'P',
          'Поточна сума (початковий капітал)',
          colors,
          textTheme,
        ),
        _buildParameterItem(
          'r',
          'Місячна дохідність (${(annualReturn / 12).toStringAsFixed(2)}%)',
          colors,
          textTheme,
        ),
        _buildParameterItem(
          'n',
          'Кількість місяців ($monthsToGoal)',
          colors,
          textTheme,
        ),
        _buildParameterItem(
          'PMT',
          'Щомісячний внесок (\$${monthlyContribution.toStringAsFixed(0)})',
          colors,
          textTheme,
        ),
      ],
    );
  }

  Widget _buildParameterItem(
    String symbol,
    String description,
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 24,
            decoration: BoxDecoration(
              color: colors.accentHighlight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                symbol,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.accentHighlight,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: textTheme.bodyMedium?.copyWith(color: colors.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourData(AppThemeExtension colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ваші поточні дані:',
          style: textTheme.titleMedium?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.dividerColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _buildDataRow(
                'Поточний капітал:',
                '\$${currentAmount.toStringAsFixed(0)}',
                colors,
                textTheme,
              ),
              _buildDataRow(
                'Цільова сума:',
                '\$${targetAmount.toStringAsFixed(0)}',
                colors,
                textTheme,
              ),
              _buildDataRow(
                'Середньомісячний внесок:',
                '\$${monthlyContribution.toStringAsFixed(0)}',
                colors,
                textTheme,
              ),
              _buildDataRow(
                'Очікувана дохідність:',
                '${annualReturn.toStringAsFixed(1)}% річних',
                colors,
                textTheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(
    String label,
    String value,
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(AppThemeExtension colors, TextTheme textTheme) {
    final years = (monthsToGoal / 12).floor();
    final remainingMonths = monthsToGoal % 12;

    String timeText;
    if (years > 0 && remainingMonths > 0) {
      timeText = '$years роки $remainingMonths місяців';
    } else if (years > 0) {
      timeText = '$years роки';
    } else {
      timeText = '$monthsToGoal місяців';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF43A047).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF43A047).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF43A047),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Прогнозований результат:',
                style: textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF43A047),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ми прогнозуємо досягнення мети через $timeText, враховуючи, що ви продовжите вносити \$${monthlyContribution.toStringAsFixed(0)}/міс, а ринок зростатиме на ${annualReturn.toStringAsFixed(1)}% на рік.',
            style: textTheme.bodyMedium?.copyWith(color: colors.primaryText),
          ),
          const SizedBox(height: 8),
          Text(
            'Розраховано на основі ваших середніх внесків (\$${monthlyContribution.toStringAsFixed(0)}/міс) та історичної дохідності ринку (${(annualReturn * 100).toStringAsFixed(1)}%).',
            style: textTheme.bodySmall?.copyWith(
              color: colors.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// Функція для показу діалогу
void showForecastExplanation({
  required BuildContext context,
  required double currentAmount,
  required double targetAmount,
  required double monthlyContribution,
  required double annualReturn,
  required int monthsToGoal,
}) {
  showDialog(
    context: context,
    builder: (context) => ForecastExplanationDialog(
      currentAmount: currentAmount,
      targetAmount: targetAmount,
      monthlyContribution: monthlyContribution,
      annualReturn: annualReturn,
      monthsToGoal: monthsToGoal,
    ),
  );
}
