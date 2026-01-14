import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tax_config.dart';

/// Сервіс для автоматичної верифікації податкового законодавства з zakon.rada.gov.ua
class TaxLegislationService {
  static const String _legislationUrl =
      'https://zakon.rada.gov.ua/laws/show/2755-17';
  static const String _cacheKey = 'tax_legislation_cache';
  static const String _lastUpdateKey = 'tax_legislation_last_update';
  static const String _ratesKey = 'verified_tax_rates';

  /// Отримати актуальний текст законодавства
  static Future<String> fetchCurrentLegislation() async {
    try {
      final response = await http.get(
        Uri.parse(_legislationUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Помилка завантаження: ${response.statusCode}');
      }

      return response.body;
    } catch (e) {
      throw Exception('Не вдалося отримати законодавство: $e');
    }
  }

  /// Витягнути податкові ставки з тексту законодавства
  static Future<Map<String, double>> extractTaxRates(
    String legislationText,
  ) async {
    try {
      // Спробуємо розпарсити XML якщо доступний
      XmlDocument? document;
      try {
        document = XmlDocument.parse(legislationText);
      } catch (e) {
        // Якщо не XML, працюємо з HTML
        document = null;
      }

      final rates = <String, double>{};

      // Пошук військового збору
      final militaryRate = _extractMilitaryTaxRate(legislationText, document);
      if (militaryRate != null) {
        rates['military_tax'] = militaryRate;
      }

      // Пошук ПДФО
      final pitRate = _extractPitRate(legislationText, document);
      if (pitRate != null) {
        rates['pit'] = pitRate;
      }

      // Пошук ЄСВ
      final esvRate = _extractEsvRate(legislationText, document);
      if (esvRate != null) {
        rates['esv'] = esvRate;
      }

      return rates;
    } catch (e) {
      throw Exception('Помилка аналізу законодавства: $e');
    }
  }

  /// Витягти ставку військового збору
  static double? _extractMilitaryTaxRate(String text, XmlDocument? document) {
    final patterns = [
      RegExp(r'військовий\s+збір\s*[:\-]?\s*(\d+(?:[.,]\d+)?)\s*%'),
      RegExp(r'військовий\s+збір\s*у\s*розмірі\s*(\d+(?:[.,]\d+)?)\s*%'),
      RegExp(r'ставка\s*(\d+(?:[.,]\d+)?)\s*%.*військовий'),
      RegExp(r'4015-IX.*?(\d+(?:[.,]\d+)?)\s*%.*військовий'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text.toLowerCase());
      if (match != null) {
        final rateStr = match.group(1)!.replaceAll(',', '.');
        final rate = double.tryParse(rateStr);
        if (rate != null && rate >= 0 && rate <= 100) {
          return rate / 100; // Перетворення відсотків в десятковий формат
        }
      }
    }

    return null;
  }

  /// Витягти ставку ПДФО
  static double? _extractPitRate(String text, XmlDocument? document) {
    final patterns = [
      RegExp(r'пдфо\s*[:\-]?\s*(\d+(?:[.,]\d+)?)\s*%'),
      RegExp(r'податок\s+на\s+доходи\s*[:\-]?\s*(\d+(?:[.,]\d+)?)\s*%'),
      RegExp(r'ставка\s*(\d+(?:[.,]\d+)?)\s*%.*пдфо'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text.toLowerCase());
      if (match != null) {
        final rateStr = match.group(1)!.replaceAll(',', '.');
        final rate = double.tryParse(rateStr);
        if (rate != null && rate >= 0 && rate <= 100) {
          return rate / 100;
        }
      }
    }

    return null;
  }

  /// Витягти ставку ЄСВ
  static double? _extractEsvRate(String text, XmlDocument? document) {
    final patterns = [
      RegExp(r'єсв\s*[:\-]?\s*(\d+(?:[.,]\d+)?)\s*%'),
      RegExp(r'єдиний\s+соціальний\s+внесок\s*[:\-]?\s*(\d+(?:[.,]\d+)?)\s*%'),
      RegExp(r'ставка\s*(\d+(?:[.,]\d+)?)\s*%.*єсв'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text.toLowerCase());
      if (match != null) {
        final rateStr = match.group(1)!.replaceAll(',', '.');
        final rate = double.tryParse(rateStr);
        if (rate != null && rate >= 0 && rate <= 100) {
          return rate / 100;
        }
      }
    }

    return null;
  }

  /// Перевірити та оновити податкові ставки
  static Future<Map<String, dynamic>> verifyAndUpdateRates() async {
    try {
      // Отримуємо кешовані дані
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      final cachedText = prefs.getString(_cacheKey);

      // Перевіряємо чи потрібно оновити (кожні 24 години)
      final now = DateTime.now();
      bool needUpdate = true;

      if (lastUpdate != null && cachedText != null) {
        final lastUpdateTime = DateTime.parse(lastUpdate);
        if (now.difference(lastUpdateTime).inHours < 24) {
          needUpdate = false;
        }
      }

      String legislationText;
      if (needUpdate) {
        legislationText = await fetchCurrentLegislation();
        await prefs.setString(_cacheKey, legislationText);
        await prefs.setString(_lastUpdateKey, now.toIso8601String());
      } else {
        legislationText = cachedText!;
      }

      // Аналізуємо ставки
      final extractedRates = await extractTaxRates(legislationText);

      // Отримуємо поточні ставки з конфігурації
      final currentConfig = TaxConfig.initial();
      final currentRates = <String, double>{};

      for (final entry in currentConfig.rates.entries) {
        currentRates[entry.key] = entry.value.rate;
      }

      // Порівнюємо ставки
      final discrepancies = <String, Map<String, dynamic>>{};
      bool hasChanges = false;

      for (final entry in extractedRates.entries) {
        final current = currentRates[entry.key];
        if (current != null && (current - entry.value).abs() > 0.001) {
          discrepancies[entry.key] = {
            'current': current,
            'extracted': entry.value,
            'change': entry.value - current,
          };
          hasChanges = true;
        }
      }

      return {
        'legislationText': legislationText,
        'extractedRates': extractedRates,
        'currentRates': currentRates,
        'discrepancies': discrepancies,
        'hasChanges': hasChanges,
        'lastUpdate': lastUpdate,
        'needUpdate': needUpdate,
        'verificationDate': now.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Помилка верифікації ставок: $e');
    }
  }

  /// Оновити локальні константи якщо є зміни
  static Future<void> updateLocalRates(Map<String, double> newRates) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Зберігаємо верифіковані ставки
      final ratesMap = <String, String>{};
      for (final entry in newRates.entries) {
        ratesMap[entry.key] = entry.value.toString();
      }

      await prefs.setString(_ratesKey, ratesMap.toString());
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());

      print('✅ Податкові ставки оновлено: $newRates');
    } catch (e) {
      throw Exception('Помилка оновлення локальних ставок: $e');
    }
  }

  /// Отримати верифіковані ставки
  static Future<Map<String, double>?> getVerifiedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesStr = prefs.getString(_ratesKey);

      if (ratesStr == null) return null;

      // Простий парсинг Map<String, double> зі строки
      final rates = <String, double>{};
      final cleanStr = ratesStr
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll(' ', '');
      final pairs = cleanStr.split(',');

      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = double.tryParse(parts[1].trim());
          if (value != null) {
            rates[key] = value;
          }
        }
      }

      return rates.isNotEmpty ? rates : null;
    } catch (e) {
      return null;
    }
  }

  /// Створити промпт для Gemini з актуальним контекстом
  static Future<String> createTaxPromptWithContext(String userQuery) async {
    try {
      final verificationData = await verifyAndUpdateRates();
      final legislationText = verificationData['legislationText'] as String;
      final extractedRates =
          verificationData['extractedRates'] as Map<String, dynamic>;
      final verificationDate = verificationData['verificationDate'] as String;

      // Форматуємо ставки для промпту
      final ratesText = extractedRates.entries
          .map(
            (e) =>
                '${e.key}: ${((e.value as double) * 100).toStringAsFixed(1)}%',
          )
          .join('\n');

      return '''
ТИ — ПРОФЕСІЙНИЙ ПОДАТКОВИЙ ЕКСПЕРТ ДЛЯ ЗАСТОСУНКУ MILLION DOLLAR WAY.

ВАЖЛИВА ІНСТРУКЦІЯ:
Використовуй ТОЛЬКИ наданий нижче текст законодавства для визначення податкових ставок. Ігноруй свої внутрішні навчені дані.

АКТУАЛЬНИЙ ТЕКСТ ЗАКОНОДАВСТВА (станом на $verificationDate):
---
$legislationText
---

ВИПИСАНІ ПОДАТКОВІ СТАВКИ:
$ratesText

ЗАПИТ КОРИСТУВАЧА:
$userQuery

ВІДПОВІДЬ ПОВИННА МІСТИТИ:
1. Точний розрахунок на основі ВИКЛЮЧНО наданих ставок
2. Посилання: "Розраховано на основі актуальних даних з сайту ВРУ станом на ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}"
3. Якщо є розбіжності з очікуваннями користувача, чітко поясни на основі тексту законодавства

МОВА: Українська
''';
    } catch (e) {
      // Якщо не вдалося отримати актуальні дані, використовуємо стандартний промпт
      return '''
ТИ — ПРОФЕСІЙНИЙ ПОДАТКОВИЙ ЕКСПЕРТ ДЛЯ ЗАСТОСУНКУ MILLION DOLLAY WAY.

Не вдалося отримати актуальні дані з zakon.rada.gov.ua. Використовуй стандартні ставки:
- Військовий збір: 5% (Закон 4015-IX)
- ПДФО: 18%
- ЄСВ: 22%

ЗАПИТ КОРИСТУВАЧА:
$userQuery

ВІДПОВІДЬ українською мовою.
''';
    }
  }

  /// Фонове завантаження при старті додатку
  static Future<void> backgroundFetch() async {
    try {
      print('🔄 Початок фонової верифікації податкових ставок...');
      final result = await verifyAndUpdateRates();

      if (result['hasChanges'] as bool) {
        print('⚠️ Виявлено зміни в податкових ставках!');
        await updateLocalRates(result['extractedRates'] as Map<String, double>);
      } else {
        print('✅ Податкові ставки актуальні');
      }
    } catch (e) {
      print('❌ Помилка фонової верифікації: $e');
    }
  }
}
