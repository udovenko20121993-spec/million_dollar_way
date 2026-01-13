import 'package:flutter/material.dart';
import '../../models/import_preview.dart';

class ImportPreviewDialog extends StatelessWidget {
  final ImportPreview preview;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ImportPreviewDialog({
    super.key,
    required this.preview,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === ЗАГОЛОВОК ===
            _buildHeader(),
            const SizedBox(height: 16),
            
            // === ПОМИЛКА (якщо є) ===
            if (!preview.isValid) ...[
              _buildErrorCard(),
            ] else ...[
              // === ПЕРІОД ===
              _buildPeriodCard(),
              const SizedBox(height: 12),
              
              // === ФІНАНСИ ===
              _buildFinanceCard(),
              const SizedBox(height: 12),
              
              // === ЗАПИСИ ===
              _buildRecordsCard(),
              const SizedBox(height: 12),
              
              // === ДУБЛІКАТИ (якщо є) ===
              if (preview.hasDuplicates) ...[
                _buildDuplicatesWarning(),
                const SizedBox(height: 12),
              ],
            ],
            
            const SizedBox(height: 8),
            
            // === КНОПКИ ===
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: preview.isValid 
                ? const Color(0xFF00C853).withOpacity(0.2)
                : Colors.redAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            preview.isValid ? Icons.preview : Icons.error_outline,
            color: preview.isValid ? const Color(0xFF00C853) : Colors.redAccent,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Попередній перегляд',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                preview.fileName,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            preview.errorMessage ?? 'Невідома помилка',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Період звіту',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Text(
                preview.periodString,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (preview.accountId.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                preview.accountId,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00C853).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Баланс
          if (preview.balance > 0)
            _buildFinanceRow(
              '💰 Баланс',
              '\$${preview.balance.toStringAsFixed(2)}',
              const Color(0xFF00C853),
            ),
          
          // Кеш
          if (preview.cashBalance > 0)
            _buildFinanceRow(
              '💵 Кеш',
              '\$${preview.cashBalance.toStringAsFixed(2)}',
              Colors.blueAccent,
            ),
          
          // Дивіденди
          if (preview.totalDividends != 0)
            _buildFinanceRow(
              '📈 Дивіденди',
              '+\$${preview.totalDividends.toStringAsFixed(2)}',
              Colors.orangeAccent,
            ),
          
          // Депозити
          if (preview.totalDeposits > 0)
            _buildFinanceRow(
              '⬆️ Депозити',
              '+\$${preview.totalDeposits.toStringAsFixed(2)}',
              Colors.greenAccent,
            ),
          
          // Виведення
          if (preview.totalWithdrawals > 0)
            _buildFinanceRow(
              '⬇️ Виведення',
              '-\$${preview.totalWithdrawals.toStringAsFixed(2)}',
              Colors.orangeAccent,
            ),
          
          // Комісії
          if (preview.totalCommissions > 0)
            _buildFinanceRow(
              '💸 Комісії',
              '-\$${preview.totalCommissions.toStringAsFixed(2)}',
              Colors.redAccent,
            ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Записи у файлі:',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (preview.tradesCount > 0)
                _buildRecordChip('📊 ${preview.tradesCount} угод', Colors.blueAccent),
              if (preview.dividendsCount > 0)
                _buildRecordChip('💰 ${preview.dividendsCount} дивід.', Colors.orangeAccent),
              if (preview.assetsCount > 0)
                _buildRecordChip('📁 ${preview.assetsCount} активів', const Color(0xFF00C853)),
              if (preview.cashTransactionsCount > 0)
                _buildRecordChip('💵 ${preview.cashTransactionsCount} транз.', Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDuplicatesWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Знайдено дублікати',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _getDuplicatesText(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${preview.totalNewRecords} нових',
              style: const TextStyle(
                color: Color(0xFF00C853),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDuplicatesText() {
    List<String> parts = [];
    if (preview.duplicateTradesCount > 0) {
      parts.add('${preview.duplicateTradesCount} угод');
    }
    if (preview.duplicateDividendsCount > 0) {
      parts.add('${preview.duplicateDividendsCount} дивід.');
    }
    return '${parts.join(', ')} буде пропущено';
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Скасувати'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: preview.isValid ? onConfirm : null,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Імпортувати'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Показати діалог попереднього перегляду
Future<bool> showImportPreviewDialog(
  BuildContext context,
  ImportPreview preview,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ImportPreviewDialog(
      preview: preview,
      onConfirm: () => Navigator.of(ctx).pop(true),
      onCancel: () => Navigator.of(ctx).pop(false),
    ),
  );
  return result ?? false;
}
