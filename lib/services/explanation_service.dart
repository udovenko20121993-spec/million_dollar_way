import 'package:flutter/material.dart';

class ExplanationService {
  static const Map<String, String> _explanations = {
    'FIFO':
        'Метод "Першим прийшов — першим пішов". Податкова вимагає рахувати прибуток, припускаючи, що ви продаєте найстаріші акції у вашому портфелі спочатку.',
    'Курс НБУ':
        'Для податків використовується офіційний курс гривні на дату кожної окремої угоди, а не на сьогодні. Ми автоматично підтягуємо ці дані.',
    'Взаємозалік':
        'Ви не платите податок двічі. Оскільки ви вже сплатили 15% у США, український ПДФО на дивіденди (9%) повністю покривається цим платежем.',
    'Drawdown':
        'Максимальне падіння вартості портфеля від піку до мінімуму. Показник 4.2% означає дуже низький ризик стратегії.',
    'Win Rate':
        'Відсоток прибуткових угод. Win Rate 68% означає, що майже 7 з 10 угод закінчуються прибутком.',
    'Confidence Score':
        'Рівень впевненості алгоритму в сигналі. Вищий показник означає більшу ймовірність успіху.',
    'Військовий збір':
        'Податок 5% на обороти військових потреб. Для військовослужбовців діє пільга 0% згідно з законом.',
    'ПДФО':
        'Податок на доходи фізичних осіб. Стандартна ставка 18% для більшості громадян України.',
    'ФОП 3 група':
        'Оплата 5% від обороту. Підходить для професійних трейдерів. Податок рахується від суми продажу, а не від прибутку, згідно з актуальними роз\'ясненнями ДПС.',
    'RSI':
        'Індекс відносної сили. Технічний індикатор, що показує, чи не переокуплено чи не перепродано актив.',
    'Ковзні середні':
        'Технічний індикатор, що показує середню ціну за певний період. Допомагає визначити тренд.',
  };

  static String getExplanation(String term) {
    return _explanations[term] ?? 'Пояснення відсутне для терміну: $term';
  }

  static Map<String, String> getAllExplanations() {
    return Map.from(_explanations);
  }

  static bool hasExplanation(String term) {
    return _explanations.containsKey(term);
  }
}

class InfoWrapper extends StatelessWidget {
  final String term;
  final Widget child;
  final String? customExplanation;
  final TextStyle? textStyle;

  const InfoWrapper({
    super.key,
    required this.term,
    required this.child,
    this.customExplanation,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (!ExplanationService.hasExplanation(term) && customExplanation == null) {
      return child;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _showExplanation(context),
          onLongPress: () => _showTooltip(context),
          child: Container(
            padding: const EdgeInsets.all(2),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _showExplanation(BuildContext context) {
    final explanation =
        customExplanation ?? ExplanationService.getExplanation(term);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ExplanationBottomSheet(term: term, explanation: explanation),
    );
  }

  void _showTooltip(BuildContext context) {
    final explanation =
        customExplanation ?? ExplanationService.getExplanation(term);

    // Show brief tooltip for long press
    final tooltip = Tooltip(
      message: explanation.length > 50
          ? '${explanation.substring(0, 47)}...'
          : explanation,
      child: Container(),
    );

    // Create overlay for tooltip
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    explanation.length > 50
                        ? '${explanation.substring(0, 47)}...'
                        : explanation,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => entry.remove(),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Auto-remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }
}

class _ExplanationBottomSheet extends StatelessWidget {
  final String term;
  final String explanation;

  const _ExplanationBottomSheet({
    required this.term,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school, color: cs.onPrimary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        term,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Фінансовий термін',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withOpacity(0.2)),
              ),
              child: Text(
                explanation,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Related terms (if any)
          _buildRelatedTerms(context, cs),

          const SizedBox(height: 20),

          // Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Дякую, зрозумів',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildRelatedTerms(BuildContext context, ColorScheme cs) {
    final relatedTerms = _getRelatedTerms(term);

    if (relatedTerms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Схожі терміни:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: relatedTerms.map((relatedTerm) {
              return ActionChip(
                label: Text(relatedTerm),
                onPressed: () {
                  Navigator.of(context).pop();
                  InfoWrapper(
                    term: relatedTerm,
                    child: const SizedBox.shrink(),
                  )._showExplanation(context);
                },
                backgroundColor: cs.surface,
                side: BorderSide(color: cs.outline.withOpacity(0.3)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<String> _getRelatedTerms(String term) {
    switch (term) {
      case 'FIFO':
        return ['ПДФО', 'Курс НБУ'];
      case 'Курс НБУ':
        return ['FIFO', 'Взаємозалік'];
      case 'Взаємозалік':
        return ['ПДФО', 'ФОП 3 група'];
      case 'Drawdown':
        return ['Win Rate', 'Confidence Score'];
      case 'Win Rate':
        return ['Drawdown', 'Confidence Score'];
      case 'Confidence Score':
        return ['Win Rate', 'RSI'];
      case 'RSI':
        return ['Ковзні середні', 'Confidence Score'];
      case 'Ковзні середні':
        return ['RSI', 'Drawdown'];
      case 'Військовий збір':
        return ['ПДФО', 'ФОП 3 група'];
      case 'ПДФО':
        return ['Військовий збір', 'Взаємозалік'];
      case 'ФОП 3 група':
        return ['ПДФО', 'Військовий збір'];
      default:
        return [];
    }
  }
}
