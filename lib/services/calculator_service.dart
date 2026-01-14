import 'package:firebase_ai/firebase_ai.dart';
import 'package:intl/intl.dart';

import '../models/tax_config.dart';
import '../models/taxpayer_profile.dart';
import '../domain/models/user_tax_profile.dart';
import 'tax_monitor_service.dart';

/// Розумний сервіс калькулятора податків з поясненнями
class CalculatorService {
  static CalculatorService? _instance;
  static CalculatorService get instance => _instance ??= CalculatorService._();

  CalculatorService._();

  /// Автоматичне налаштування калькулятора на основі даних платника
  Map<String, dynamic> autoConfigureFromProfile(TaxpayerProfile profile) {
    return {
      'isFop': profile.isFop,
      'fopGroup': profile.fopGroup,
      'taxRate': profile.taxRate,
      'hasVat': profile.hasVat,
      'yearlyRevenue': profile.yearlyRevenue,
      'monthlyIncome': profile.yearlyRevenue / 12,
      'taxTypes': profile.taxTypes,
      'dataSource': 'STS (Дія.Підпис)',
      'lastSync': profile.lastSync.toIso8601String(),
    };
  }

  /// Розрахунок податків з детальним поясненням
  Future<TaxCalculationResult> calculateTaxes({
    required double monthlyIncome,
    required String userId,
    TaxProfile? taxProfile,
    bool? isMilitaryExemptionActive,
    TaxConfig? taxConfig,
    TaxpayerProfile? taxpayerProfile,
  }) async {
    final config = taxConfig ?? TaxMonitorService.instance.currentConfig;

    // Визначаємо ставки - пріоритет DPS даним
    double singleTaxRate;
    double militaryTaxRate;
    double esvRate;
    double pitRate;

    if (taxpayerProfile != null) {
      // Використовуємо дані з ДПС
      singleTaxRate = taxpayerProfile.taxRate;
      militaryTaxRate = config.getRate('military_tax')?.rate ?? 0.05;
      esvRate = config.getRate('esv')?.rate ?? 0.22;
      pitRate = config.getRate('pit')?.rate ?? 0.18;
    } else {
      // Використовуємо стандартні ставки
      singleTaxRate = config.getRate('single_tax_group3')?.rate ?? 0.05;
      militaryTaxRate = config.getRate('military_tax')?.rate ?? 0.05;
      esvRate = config.getRate('esv')?.rate ?? 0.22;
      pitRate = config.getRate('pit')?.rate ?? 0.18;
    }

    // Розраховуємо податки
    final breakdown = <String, double>{};
    final appliedArticles = <String>[];
    double totalTax = 0.0;

    // Єдиний податок (ФОП 3 група або з DPS)
    if (taxpayerProfile?.isFop == true || taxProfile == TaxProfile.fop3) {
      final singleTax = monthlyIncome * singleTaxRate;
      breakdown['Єдиний податок'] = singleTax;
      totalTax += singleTax;
      appliedArticles.add(config.getRate('single_tax_group3')?.article ?? '');
    }

    // Військовий збір (з урахуванням пільги)
    final effectiveMilitaryRate = _calculateMilitaryRate(
      militaryTaxRate,
      taxProfile,
      isMilitaryExemptionActive,
    );
    final militaryTax = monthlyIncome * effectiveMilitaryRate;
    breakdown['Військовий збір'] = militaryTax;
    totalTax += militaryTax;
    appliedArticles.add(config.getRate('military_tax')?.article ?? '');

    // ЄСВ (якщо застосовно)
    if (taxpayerProfile?.isFop == true || taxProfile == TaxProfile.fop3) {
      final esv = monthlyIncome * esvRate;
      breakdown['ЄСВ'] = esv;
      totalTax += esv;
      appliedArticles.add(config.getRate('esv')?.article ?? '');
    }

    // ПДФО (якщо не ФОП)
    if ((taxpayerProfile?.isFop == false && taxpayerProfile != null) ||
        taxProfile == TaxProfile.civilian) {
      final pit = monthlyIncome * pitRate;
      breakdown['ПДФО'] = pit;
      totalTax += pit;
      appliedArticles.add(config.getRate('pit')?.article ?? '');
    }

    // Генеруємо пояснення за допомогою Gemini
    final explanation = await _generateExplanation(
      monthlyIncome: monthlyIncome,
      breakdown: breakdown,
      taxProfile: taxProfile,
      isMilitaryExemptionActive: isMilitaryExemptionActive,
      appliedArticles: appliedArticles,
      config: config,
      taxpayerProfile: taxpayerProfile,
    );

    return TaxCalculationResult(
      totalTax: totalTax,
      breakdown: breakdown,
      explanation: explanation,
      appliedArticles: appliedArticles,
      calculatedAt: DateTime.now(),
    );
  }

  /// Розрахунок ефективної ставки військового збору
  double _calculateMilitaryRate(
    double baseRate,
    TaxProfile? taxProfile,
    bool? isMilitaryExemptionActive,
  ) {
    // Військові звільнені від військового збору
    if (taxProfile == TaxProfile.military) {
      return 0.0;
    }

    // Цивільні з пільгою також звільнені
    if (taxProfile == TaxProfile.civilian &&
        isMilitaryExemptionActive == true) {
      return 0.0;
    }

    return baseRate;
  }

  /// Генерація людського пояснення за допомогою Gemini 2.0 Flash
  Future<String> _generateExplanation({
    required double monthlyIncome,
    required Map<String, double> breakdown,
    required TaxProfile? taxProfile,
    required bool? isMilitaryExemptionActive,
    required List<String> appliedArticles,
    required TaxConfig config,
    TaxpayerProfile? taxpayerProfile,
  }) async {
    try {
      final ai = FirebaseAI.vertexAI();
      final model = ai.generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 1024,
        ),
      );

      final breakdownText = breakdown.entries
          .map((e) => '- ${e.key}: ${e.value.toStringAsFixed(2)} грн')
          .join('\n');

      final articlesText = appliedArticles.join('\n');

      String dataSource = '';
      if (taxpayerProfile != null) {
        dataSource =
            '''
        
📊 **Джерело даних:** Офіційні дані з ДПС України
- ПІБ: ${taxpayerProfile.fullName}
- РНОКПП: ${taxpayerProfile.rnokpp}
- Статус: ${taxpayerProfile.isFop ? 'ФОП ${taxpayerProfile.fopGroup} групи' : 'Фізична особа'}
- Річний дохід: ${taxpayerProfile.yearlyRevenue.toStringAsFixed(2)} грн
- Останнє оновлення: ${DateFormat('dd.MM.yyyy HH:mm').format(taxpayerProfile.lastSync)}
''';
      }

      final prompt =
          '''
Поясни детально, як розраховано податки для фізичної особи в Україні:

Вхідні дані:
- Місячний дохід: ${monthlyIncome.toStringAsFixed(2)} грн
- Податковий профіль: ${taxProfile?.displayName ?? 'Цивільний'}
- Пільга по військовому збору: ${isMilitaryExemptionActive == true ? 'Так' : 'Ні'}$dataSource

Розрахунок податків:
$breakdownText

Загальний податок: ${breakdown.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)} грн

Застосовані статті закону:
$articlesText

Поясни покроково:
1. Чому застосовано саме ці ставки
2. Які статті Податкового кодексу застосовано
3. Як профіль користувача впливає на розрахунок
4. Математичну формулу для кожного податку
5. Якщо використовуються дані з ДПС - вкажи це перевагу

Відповідай українською мовою, чітко і структуровано.
''';

      final response = await model.generateContent([
        Content('user', [TextPart(prompt)]),
      ]);
      return response.text ?? 'Не вдалося згенерувати пояснення';
    } catch (e) {
      print('❌ Error generating explanation: $e');
      return _generateFallbackExplanation(
        monthlyIncome,
        breakdown,
        taxProfile,
        isMilitaryExemptionActive,
        appliedArticles,
      );
    }
  }

  /// Запасне пояснення без AI
  String _generateFallbackExplanation(
    double monthlyIncome,
    Map<String, double> breakdown,
    TaxProfile? taxProfile,
    bool? isMilitaryExemptionActive,
    List<String> appliedArticles,
  ) {
    final explanation = StringBuffer();

    explanation.writeln('📊 **Розрахунок податків**');
    explanation.writeln();

    explanation.writeln('**Дохід:** ${monthlyIncome.toStringAsFixed(2)} грн');
    explanation.writeln(
      '**Профіль:** ${taxProfile?.displayName ?? 'Цивільний'}',
    );
    explanation.writeln();

    explanation.writeln('**Покроковий розрахунок:**');

    breakdown.forEach((tax, amount) {
      final rate = (amount / monthlyIncome * 100).toStringAsFixed(1);
      explanation.writeln(
        '- $tax: ${monthlyIncome.toStringAsFixed(2)} × $rate% = ${amount.toStringAsFixed(2)} грн',
      );
    });

    explanation.writeln();
    explanation.writeln(
      '**Загальний податок:** ${breakdown.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)} грн',
    );

    if (isMilitaryExemptionActive == true) {
      explanation.writeln();
      explanation.writeln(
        '📝 **Примітка:** Військовий збір не застосовується через діючу пільгу.',
      );
    }

    return explanation.toString();
  }

  /// Отримання пояснення для конкретного податку
  Future<String> getTaxExplanation(String taxName) async {
    try {
      final ai = FirebaseAI.vertexAI();
      final model = ai.generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 512,
        ),
      );

      final prompt =
          '''
Поясни простими словами, що таке "$taxName" в Україні:
- Для чого він існує
- Хто його сплачує
- Як використовуються кошти
- Важливі особливості

Відповідай українською мовою, коротко і зрозуміло.
''';

      final response = await model.generateContent([
        Content('user', [TextPart(prompt)]),
      ]);
      return response.text ?? 'Не вдалося отримати пояснення';
    } catch (e) {
      print('❌ Error getting tax explanation: $e');
      return _getFallbackTaxExplanation(taxName);
    }
  }

  /// Запасне пояснення податку
  String _getFallbackTaxExplanation(String taxName) {
    switch (taxName.toLowerCase()) {
      case 'єдиний податок':
        return 'Єдиний податок - це спрощена система оподаткування для ФОП. 3 група сплачує 5% з обороту.';
      case 'військовий збір':
        return 'Військовий збір - 5% з доходів на підтримку ЗСУ (Закон 4015-IX). Військовослужбовці звільнені.';
      case 'єсв':
        return 'ЄСВ - Єдиний соціальний внесок 22% на пенсійне та медичне страхування.';
      case 'пдфо':
        return 'ПДФО - Податок на доходи фізичних осіб 18% з заробітної плати та інших доходів.';
      default:
        return 'Податок - обов\'язковий платіж до державного бюджету.';
    }
  }
}
