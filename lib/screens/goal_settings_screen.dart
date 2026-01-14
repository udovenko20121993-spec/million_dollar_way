import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user_goal.dart';
import '../theme/app_theme.dart';
import '../utils/user_session.dart';

class GoalSettingsScreen extends ConsumerStatefulWidget {
  final UserGoal? currentGoal;

  const GoalSettingsScreen({super.key, this.currentGoal});

  @override
  ConsumerState<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends ConsumerState<GoalSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCurrency = 'USD';
  bool _isLoading = false;

  // Попередньо визначені цілі
  final List<Map<String, dynamic>> _predefinedGoals = [
    {
      'name': 'Перший мільйон',
      'amount': 1000000,
      'currency': 'USD',
      'icon': '💰',
    },
    {'name': 'На будинок', 'amount': 500000, 'currency': 'USD', 'icon': '🏠'},
    {'name': 'На пенсію', 'amount': 2000000, 'currency': 'USD', 'icon': '🏖️'},
    {'name': 'На авто', 'amount': 50000, 'currency': 'USD', 'icon': '🚗'},
    {
      'name': 'Стартовий капітал',
      'amount': 100000,
      'currency': 'USD',
      'icon': '🚀',
    },
    {
      'name': 'Фінансова незалежність',
      'amount': 3000000,
      'currency': 'USD',
      'icon': '🎯',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentGoal != null) {
      _nameController.text = widget.currentGoal!.name;
      _amountController.text = widget.currentGoal!.targetAmount.toStringAsFixed(
        0,
      );
      _selectedCurrency = widget.currentGoal!.currency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.currentGoal != null ? 'Редагувати мету' : 'Нова мета',
        ),
        backgroundColor: colors.primaryBackground,
        iconTheme: IconThemeData(color: colors.primaryText),
        actions: [
          TextButton(
            onPressed: _saveGoal,
            child: Text(
              'Зберегти',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.accentHighlight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Попередньо визначені цілі
                      _buildPredefinedGoals(colors, textTheme),
                      const SizedBox(height: 32),

                      // Або налаштуйте власну мету
                      _buildCustomGoalSection(colors, textTheme),
                      const SizedBox(height: 32),

                      // Попередній перегляд
                      _buildGoalPreview(colors, textTheme),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPredefinedGoals(AppThemeExtension colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Оберіть готову мету',
          style: textTheme.titleLarge?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _predefinedGoals.length,
          itemBuilder: (context, index) {
            final goal = _predefinedGoals[index];
            final isSelected =
                _nameController.text == goal['name'] &&
                double.tryParse(_amountController.text) == goal['amount'];

            return GestureDetector(
              onTap: () => _selectPredefinedGoal(goal),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accentHighlight.withOpacity(0.2)
                      : colors.surfaceBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? colors.accentHighlight
                        : colors.dividerColor.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(goal['icon'], style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      goal['name'],
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAmount(goal['amount'], goal['currency']),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomGoalSection(
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Або налаштуйте власну мету',
          style: textTheme.titleLarge?.copyWith(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.dividerColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Назва мети
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Назва мети',
                  hintText: 'Наприклад: "На будинок"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accentHighlight),
                  ),
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                  ),
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.primaryText,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введіть назву мети';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Валюта
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Валюта',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accentHighlight),
                  ),
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.primaryText,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'USD',
                    child: Text('USD - Долар США'),
                  ),
                  DropdownMenuItem(value: 'UAH', child: Text('UAH - Гривня')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR - Євро')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Сума
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Цільова сума',
                  hintText: 'Наприклад: 1000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accentHighlight),
                  ),
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                  ),
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                  ),
                  prefixText: _selectedCurrency == 'USD'
                      ? '\$'
                      : _selectedCurrency == 'UAH'
                      ? '₴'
                      : '€',
                  prefixStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.primaryText,
                  ),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.primaryText,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введіть цільову суму';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Введіть коректну суму';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Повзунок для швидкого вибору
              Text(
                'Або оберіть швидко:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: colors.accentHighlight,
                  inactiveTrackColor: colors.dividerColor.withOpacity(0.3),
                  thumbColor: colors.accentHighlight,
                  overlayColor: colors.accentHighlight.withOpacity(0.2),
                  valueIndicatorColor: colors.accentHighlight,
                  valueIndicatorTextStyle: textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Slider(
                  value: double.tryParse(_amountController.text) ?? 100000,
                  min: 10000,
                  max: _selectedCurrency == 'UAH' ? 10000000 : 5000000,
                  divisions: 100,
                  label: _formatAmount(
                    (double.tryParse(_amountController.text) ?? 100000).round(),
                    _selectedCurrency,
                  ),
                  onChanged: (value) {
                    _amountController.text = value.round().toString();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalPreview(AppThemeExtension colors, TextTheme textTheme) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final name = _nameController.text.trim().isEmpty
        ? 'Нова мета'
        : _nameController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.accentHighlight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentHighlight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: colors.accentHighlight, size: 20),
              const SizedBox(width: 8),
              Text(
                'Попередній перегляд',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.accentHighlight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAmount(amount.round(), _selectedCurrency),
                      style: textTheme.headlineMedium?.copyWith(
                        color: colors.accentHighlight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.accentHighlight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedCurrency,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectPredefinedGoal(Map<String, dynamic> goal) {
    setState(() {
      _nameController.text = goal['name'];
      _amountController.text = goal['amount'].toString();
      _selectedCurrency = goal['currency'];
    });
  }

  String _formatAmount(int amount, String currency) {
    if (currency == 'USD') {
      return '\$${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } else if (currency == 'UAH') {
      return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} грн';
    } else if (currency == 'EUR') {
      return '€${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return '$amount $currency';
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = UserSession.userId ?? 'user_test_1';
      final amount = double.parse(_amountController.text);
      final name = _nameController.text.trim();

      if (widget.currentGoal != null) {
        // Оновлення існуючої мети
        final updatedGoal = widget.currentGoal!.copyWith(
          name: name,
          targetAmount: amount,
          currency: _selectedCurrency,
        );
        // TODO: Зберегти в Firestore
        print('Оновлено мету: ${updatedGoal.toString()}');
      } else {
        // Створення нової мети
        final newGoal = UserGoal.create(
          userId: userId,
          name: name,
          targetAmount: amount,
          currency: _selectedCurrency,
        );
        // TODO: Зберегти в Firestore
        print('Створено нову мету: ${newGoal.toString()}');
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка збереження мети: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
