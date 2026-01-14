import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/models/custom_portfolio_models.dart';
import '../models/ibkr_data.dart';
import 'tax_calculation_service.dart';

/// Service for exporting tax reports to PDF
class PdfExportService {
  /// Export tax report to PDF file
  Future<void> exportTaxReport({
    required List<IBKRTrade> trades,
    required int year,
    required List<TaxMatch> matches,
    required List<ProcessedDividend> dividends,
    required double dividendPitRate,
    required double dividendMilitaryRate,
  }) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = 'tax_report_$year.pdf';
      final filePath = '${directory.path}/$fileName';

      // For now, create a simple text file as placeholder
      // In production, use a PDF library like pdf or printing
      final file = File(filePath);
      final content = _generateReportContent(
        year: year,
        matches: matches,
        dividends: dividends,
        dividendPitRate: dividendPitRate,
        dividendMilitaryRate: dividendMilitaryRate,
      );

      await file.writeAsString(content);

      // Share the file
      final xFile = XFile(filePath);
      await Share.shareXFiles([xFile], text: 'Податковий звіт за $year рік');
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  String _generateReportContent({
    required int year,
    required List<TaxMatch> matches,
    required List<ProcessedDividend> dividends,
    required double dividendPitRate,
    required double dividendMilitaryRate,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('ПОДАТКОВИЙ ЗВІТ ЗА $year РІК');
    buffer.writeln('=' * 50);
    buffer.writeln();

    // Capital gains section
    buffer.writeln('ПРИБУТОК ВІД ПРОДАЖУ АКТИВІВ');
    buffer.writeln('-' * 50);
    if (matches.isEmpty) {
      buffer.writeln('Немає проданих угод у $year році');
    } else {
      double totalProfit = 0.0;
      double totalTax = 0.0;

      for (final match in matches) {
        buffer.writeln('Символ: ${match.symbol}');
        buffer.writeln('  Продаж: ${match.sellQuantity} @ ${match.sellPrice} (${match.sellDate.toString().split(' ')[0]})');
        buffer.writeln('  Купівля: ${match.buyQuantity} @ ${match.buyPrice} (${match.buyDate.toString().split(' ')[0]})');
        buffer.writeln('  Прибуток/збиток: ${match.profitLoss.toStringAsFixed(2)}');
        buffer.writeln('  Податок: ${match.taxAmount.toStringAsFixed(2)}');
        buffer.writeln();
        totalProfit += match.profitLoss;
        totalTax += match.taxAmount;
      }

      buffer.writeln('Загальний прибуток: ${totalProfit.toStringAsFixed(2)}');
      buffer.writeln('Загальний податок: ${totalTax.toStringAsFixed(2)}');
    }
    buffer.writeln();

    // Dividends section
    buffer.writeln('ДИВІДЕНДИ');
    buffer.writeln('-' * 50);
    if (dividends.isEmpty) {
      buffer.writeln('Немає дивідендів у $year році');
    } else {
      double totalGross = 0.0;
      double totalWithheld = 0.0;

      for (final dividend in dividends) {
        buffer.writeln('${dividend.assetSymbol}: ${dividend.grossAmount.toStringAsFixed(2)}');
        buffer.writeln('  Утримано: ${dividend.taxWithheld.toStringAsFixed(2)}');
        totalGross += dividend.grossAmount;
        totalWithheld += dividend.taxWithheld;
      }

      buffer.writeln();
      buffer.writeln('Загальна сума дивідендів: ${totalGross.toStringAsFixed(2)}');
      buffer.writeln('Утримано податку: ${totalWithheld.toStringAsFixed(2)}');
      buffer.writeln('ПДФО ставка: ${(dividendPitRate * 100).toStringAsFixed(1)}%');
      buffer.writeln('ВЗ ставка: ${(dividendMilitaryRate * 100).toStringAsFixed(1)}%');
    }

    return buffer.toString();
  }
}
