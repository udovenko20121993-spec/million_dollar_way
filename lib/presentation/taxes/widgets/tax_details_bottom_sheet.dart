import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../services/tax_calculation_service.dart';

Future<void> showTaxDetailsBottomSheet(
  BuildContext context, {
  required String title,
  required List<FifoMatch> matches,
}) {
  final theme = Theme.of(context);
  final colors = theme.extension<AppThemeExtension>()!;

  String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  return showModalBottomSheet(
    context: context,
    backgroundColor: colors.surfaceBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'FIFO деталізація для обраних угод. Ці дані носять ознайомчий характер і можуть бути змінені після синхронізації з IBKR.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: DataTable(
                  headingTextStyle: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondaryText,
                    letterSpacing: 0.3,
                  ),
                  dataTextStyle: theme.textTheme.bodyMedium,
                  columns: const [
                    DataColumn(label: Text('Актив')),
                    DataColumn(label: Text('Купівля')),
                    DataColumn(label: Text('Продаж')),
                    DataColumn(label: Text('К-сть')),
                    DataColumn(label: Text('Профіт')),
                  ],
                  rows: matches.map((match) {
                    final profitColor = match.profitUah >= 0
                        ? colors.accentPositive
                        : colors.accentNegative;
                    final tax = match.profitUah > 0
                        ? match.profitUah * 0.23
                        : 0.0;
                    return DataRow(
                      cells: [
                        DataCell(Text(match.symbol)),
                        DataCell(
                          Text(
                            '${formatDate(match.buyDate)}\n${match.buyPriceUah.toStringAsFixed(2)} ₴',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${formatDate(match.sellDate)}\n${match.sellPriceUah.toStringAsFixed(2)} ₴',
                          ),
                        ),
                        DataCell(Text(match.quantity.toStringAsFixed(2))),
                        DataCell(
                          Text(
                            '${match.profitUah.toStringAsFixed(2)} ₴',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: profitColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Закрити'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
