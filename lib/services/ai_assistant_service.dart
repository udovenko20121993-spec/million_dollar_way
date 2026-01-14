import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/remote/firestore_service.dart';
import '../domain/models/user_tax_profile.dart';
import 'tax_legislation_service.dart';
import 'usage_tracker.dart';

class AiAssistantService {
  final FirestoreService _firestore;

  AiAssistantService({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  /// Отримати ім'я користувача для персоналізації
  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    // Якщо імені немає, використовуємо нейтральне звертання
    return 'Друже';
  }

  Future<String> buildSystemPrompt({required String userId}) async {
    final profile = await _firestore.getUserTaxProfile(userId);
    final settings = await _firestore.getDividendTaxSettings(userId);

    final taxProfile = profile?.profile ?? TaxProfile.civilian;
    final isMilitaryExemptionActive =
        profile?.isMilitaryExemptionActive ?? false;

    final pitRate = (settings?['pitRate'] as double?) ?? 0.09;
    final militaryRate = (settings?['militaryRate'] as double?) ?? 0.05;
    final applyForeignTaxCredit =
        (settings?['applyForeignTaxCredit'] as bool?) ?? true;

    final militaryText =
        taxProfile == TaxProfile.military ||
            (taxProfile == TaxProfile.civilian && isMilitaryExemptionActive)
        ? '0%'
        : '${(militaryRate * 100).toStringAsFixed(2)}%';

    return [
      'Ти — Мідас, мудрий фінансовий наставник для майбутніх мільйонерів у застосунку Million Dollar Way.',
      'Твоє ім\'я — Мідас. Ти є преміум AI-асистентом, який допомагає людям досягти фінансового успіху.',
      'Завжди відповідай українською мовою. Використовуй тільки українську фінансову та податкову термінологію.',
      'Використовуй правильні українські терміни: ПДФО (податок на доходи фізичних осіб), військовий збір, ЄСВ (єдиний соціальний внесок), КВЕД (книга обліку доходів і витрат), ДПС (Державна податкова служба).',
      'ВАЖЛИВО: Військовий збір в Україні становить 5% згідно із Законом 4015-IX. Це критично важливо для всіх розрахунків!',
      'Не вигадуй цифри та дані. Якщо інформації недостатньо — чітко вкажи, що потрібно уточнити.',
      'Пояснюй розрахунки покроково, використовуючи українську податкову термінологію.',
      'Будь коротким, влучним та мотивуючим. Ти — наставник, а не просто калькулятор.',
      'Використовуй філософію "час — гроші" та мотивуй користувачів діяти негайно.',
      '',
      'Податкові ставки для інвестиційного доходу та дивідендів:',
      '- ПДФО: 18% (з дивідендів для фізичних осіб)',
      '- Військовий збір: 5% (згідно із Законом 4015-IX)',
      '- Загальний податок: 23% (18% ПДФО + 5% військовий збір)',
      '- Для ФОП 3 групи: 5% єдиний податок + ЄСВ',
      '',
      'Контекст користувача:',
      '- Податковий статус: ${taxProfile.displayName}',
      '- Пільга за військовим збором: ${isMilitaryExemptionActive ? 'активна' : 'неактивна'}',
      '- Ставки оподаткування дивідендів: ПДФО ${(pitRate * 100).toStringAsFixed(2)}%, військовий збір $militaryText',
      '- Залік іноземного податку: ${applyForeignTaxCredit ? 'враховується' : 'не враховується'}',
      '',
      'Правила розрахунків:',
      '- Прибуток від інвестицій розраховується за методом FIFO.',
      '- Конвертація валют в гривню виконується за офіційним курсом НБУ на дату операції.',
      '- Для ФОП 3 групи: базова ставка 5% від обороту, але наголошуй на необхідності ведення КВЕД та консультації з податковим консультантом.',
      '- Військовий збір: 0% для військовослужбовців та осіб з пільгою, інакше 5% від доходів (Закон 4015-IX).',
      '',
      'Важливе попередження: Надана інформація має інформаційний характер і не є юридичною консультацією. Для складних податкових питань рекомендується звернутися до сертифікованого податкового консультанта.',
    ].join('\n');
  }

  GenerativeModel _model() {
    final ai = FirebaseAI.vertexAI();
    return ai.generativeModel(
      model: 'gemini-2.0-flash',
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 4096,
      ),
    );
  }

  /// Отримати відповідь від Мідаса для аналізу симуляції
  Future<String> getSimulationAnalysis({
    required String userName, // Параметр збережено для сумісності
    required double initialAmount,
    required int yearsEarlier,
    required double monthlyContribution,
    required double annualReturn,
    required double lostOpportunity,
    required double futurePotential,
  }) async {
    try {
      // Використовуємо реальне ім'я користувача
      final displayName = _getUserDisplayName();

      final prompt =
          '''
Мідас, проаналізуй фінансову симуляцію для користувача $displayName:

ПАРАМЕТРИ СИМУЛЯЦІЇ:
- Початкова сума: \$${initialAmount.toStringAsFixed(0)}
- Роки раніше: $yearsEarlier
- Щомісячний внесок: \$${monthlyContribution.toStringAsFixed(0)}
- Річна дохідність: ${annualReturn.toStringAsFixed(1)}%

РЕЗУЛЬТАТИ:
- Втрачена можливість: \$${lostOpportunity.toStringAsFixed(0)}
- Майбутній потенціал: \$${futurePotential.toStringAsFixed(0)}
- Різниця через зволікання: \$${(lostOpportunity - initialAmount).toStringAsFixed(0)}

${yearsEarlier >= 20 ? 'ВАЖЛИВО: Користувач розглядає дуже довгий період ($yearsEarlier років). Згадай про силу складних відсотків та те, як навіть малі інвестиції перетворюються на величезні суми за такий час.' : ''}

Дай коротку, влучну пораду українською мовою. Почни з імені користувача ($displayName). Використовуй філософію "час — гроші". Будь мотивуючим та надихаючим. Максимальна довжина відповіді - 2 речення.
''';

      final model = _model();
      final response = await model.generateContent([Content.text(prompt)]);

      return response.text ??
          'На жаль, я не зміг сформулювати пораду. Спробуй ще раз!';
    } catch (e) {
      return 'Помилка отримання аналізу: $e';
    }
  }

  Future<String> getResponseWithGrounding({
    required String userId,
    required String userQuery,
    bool useLiveLegislation = true,
    bool useSearchGrounding = true,
  }) async {
    try {
      String prompt;

      if (useLiveLegislation) {
        // Використовуємо актуальне законодавство
        prompt = await TaxLegislationService.createTaxPromptWithContext(
          userQuery,
        );
      } else {
        // Використовуємо стандартний промпт
        prompt =
            '${await buildSystemPrompt(userId: userId)}\n\nЗАПИТ: $userQuery';
      }

      final model = _model();

      // Налаштовуємо Google Search Grounding
      if (useSearchGrounding) {
        prompt +=
            '\n\nIMPORTANT: Use Google Search Grounding to verify current tax rates and regulations. Always check zakon.rada.gov.ua for the most up-to-date information.';
      }

      final response = await model.generateContent([Content.text(prompt)]);

      return response.text ?? 'Не вдалося отримати відповідь';
    } catch (e) {
      return 'Помилка отримання відповіді: $e';
    }
  }

  /// Оновити податкові ставки на основі верифікації
  static Future<void> updateTaxRatesFromVerification() async {
    try {
      final verifiedRates = await TaxLegislationService.getVerifiedRates();
      if (verifiedRates != null) {
        // Оновлюємо локальні константи
        await TaxLegislationService.updateLocalRates(verifiedRates);
        print('✅ Податкові ставки оновлено на основі верифікації');
      }
    } catch (e) {
      print('❌ Помилка оновлення ставок: $e');
    }
  }

  Future<String> generateReply({
    required String systemPrompt,
    required List<Content> history,
    required String userMessage,
  }) async {
    // Збільшуємо лічильник запитів
    await UsageTracker.incrementAiRequests();

    final prompt = <Content>[
      Content('user', [TextPart('SYSTEM:\n$systemPrompt')]),
      ...history,
      Content('user', [TextPart(userMessage)]),
    ];

    final model = _model();
    final response = await model.generateContent(prompt.toList());

    return response.text ?? 'Не вдалося отримати відповідь';
  }
}
