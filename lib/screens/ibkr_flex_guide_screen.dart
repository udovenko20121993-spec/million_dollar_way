import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class IbkrFlexGuideScreen extends StatelessWidget {
  const IbkrFlexGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: const Text('Інструкція IBKR Flex'),
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryText),
        actions: [
          IconButton(
            icon: Icon(Icons.link, color: colors.accentInteractive),
            onPressed: () => _launchIBKRWebsite(),
            tooltip: 'Перейти до IBKR',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors, textTheme),
            const SizedBox(height: 24),
            _buildPrerequisites(colors, textTheme),
            const SizedBox(height: 24),
            _buildSteps(colors, textTheme),
            const SizedBox(height: 24),
            _buildImportantNotes(colors, textTheme),
            const SizedBox(height: 24),
            _buildHelpSection(colors, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeExtension colors, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: colors.accentHighlight, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Створення та завантаження історичного Flex-звіту',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Для того, щоб застосунок "Million Dollar Way" міг повністю відобразити вашу історію інвестицій в Interactive Brokers (IBKR), вам необхідно створити та завантажити спеціальний Flex-звіт.',
            style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildPrerequisites(AppThemeExtension colors, TextTheme textTheme) {
    return _buildSection(
      'Передумови',
      [
        '• Активний рахунок в Interactive Brokers',
        '• Ваші логін та пароль для Client Portal',
      ],
      colors,
      textTheme,
      Icons.check_circle_outline,
    );
  }

  Widget _buildSteps(AppThemeExtension colors, TextTheme textTheme) {
    final steps = [
      {
        'title': 'Крок 1: Увійдіть до Client Portal',
        'content': [
          '1. Відкрийте веб-браузер і перейдіть за адресою: client.interactivebrokers.com',
          '2. Введіть свої ім\'я користувача та пароль і натисніть кнопку Log In',
          '3. Пройдіть двофакторну аутентифікацію, якщо вона налаштована',
        ],
      },
      {
        'title': 'Крок 2: Перейдіть до розділу "Звіти"',
        'content': [
          '1. В меню навігації знайдіть і виберіть "Performance & Reports"',
          '2. У випадаючому меню оберіть "Flex Queries"',
        ],
      },
      {
        'title': 'Крок 3: Створіть новий Flex-запит',
        'content': [
          'На сторінці "Flex Queries" натисніть кнопку "Create New Flex Query"',
        ],
      },
      {
        'title': 'Крок 4: Налаштуйте Параметри звіту',
        'content': [
          '**Тип звіту:** Activity Statement',
          '**Секції даних:** Trades, Cash Report, Dividends, Withholding Tax, Corporate Actions, Charges, Interest, Funds, Change in Asset Values, Positions, Mark-to-Market Performance',
          '**Період:** Custom Date Range (від першої угоди до сьогодні)',
          '**Формат:** XML',
          '**Назва:** MyFullHistory_IBKR або MillionDollarWay_FullHistory',
        ],
      },
      {
        'title': 'Крок 5: Збережіть та згенеруйте звіт',
        'content': [
          '1. Перевірте всі налаштування',
          '2. Натисніть "Continue" або "Create"',
          '3. Знайдіть ваш запит і натисніть "Run"',
          '4. Коли звіт буде готовий, натисніть "Download"',
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Покрокова інструкція',
          style: textTheme.titleLarge?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.map((step) => _buildStepCard(step, colors, textTheme)),
      ],
    );
  }

  Widget _buildStepCard(
    Map<String, dynamic> step,
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.dividerColor),
      ),
      child: ExpansionTile(
        title: Text(
          step['title'],
          style: textTheme.titleMedium?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: colors.accentInteractive,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (step['content'] as List<String>).map((content) {
                final isBold =
                    content.startsWith('**') && content.endsWith('**');
                final displayText = isBold
                    ? content.substring(2, content.length - 2)
                    : content;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isBold) ...[
                        Text(
                          '• ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.accentInteractive,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            displayText,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.secondaryText,
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Text(
                            displayText,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNotes(AppThemeExtension colors, TextTheme textTheme) {
    return _buildSection(
      'Важливі примітки',
      [
        '• Перевірте, що ви обрали всі необхідні секції даних',
        '• Звіт може бути нечитабельним для людини - це нормально',
        '• Flex-запит зберігається у вашому списку для майбутнього використання',
        '• Для автоматичних оновлень потрібен окремий токен Flex Web Service',
      ],
      colors,
      textTheme,
      Icons.info_outline,
    );
  }

  Widget _buildHelpSection(AppThemeExtension colors, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentInteractive),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: colors.accentInteractive,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Потрібна допомога?',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Якщо у вас виникли труднощі з створенням або завантаженням звіту, зверніться до підтримки Interactive Brokers або нашої служби підтримки.',
            style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchIBKRWebsite(),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('IBKR Client Portal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentInteractive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyGuideLink(),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Копіювати посилання'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accentInteractive,
                    side: BorderSide(color: colors.accentInteractive),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> items,
    AppThemeExtension colors,
    TextTheme textTheme,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.accentHighlight, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                item,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchIBKRWebsite() async {
    final Uri url = Uri.parse('https://client.interactivebrokers.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _copyGuideLink() {
    // TODO: Реалізувати копіювання посилання на інструкцію
    HapticFeedback.lightImpact();
  }
}
