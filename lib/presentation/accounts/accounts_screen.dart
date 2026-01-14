import 'package:flutter/material.dart';
import '../../models/ibkr_account.dart';
import '../../services/account_service.dart';

/// Екран управління рахунками IBKR
class AccountsScreen extends StatefulWidget {
  final String userId;
  final bool openCreateDialog;

  const AccountsScreen({
    super.key,
    required this.userId,
    this.openCreateDialog = false,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late AccountService _accountService;

  @override
  void initState() {
    super.initState();
    _accountService = AccountService(userId: widget.userId);
    
    // Відкриваємо діалог створення, якщо потрібно
    if (widget.openCreateDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreateAccountDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Рахунки IBKR'),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<IBKRAccount>>(
          stream: _accountService.getAccountsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final accounts = snapshot.data ?? [];

            if (accounts.isEmpty) {
              return _buildEmptyState();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Інформаційна картка
                _buildInfoCard(accounts),
                
                const SizedBox(height: 24),
                
                // Заголовок
                const Text(
                  'Ваші рахунки',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Список рахунків
                ...accounts.map((account) => _buildAccountCard(account)),
                
                const SizedBox(height: 16),
                
                // Кнопка додавання
                _buildAddButton(),
                
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance,
                size: 50,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Немає рахунків',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Додайте ваш перший рахунок IBKR\nдля відстеження інвестицій',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateAccountDialog,
              icon: const Icon(Icons.add),
              label: const Text('Додати рахунок'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<IBKRAccount> accounts) {
    final totalBalance = accounts.fold(0.0, (sum, acc) => sum + (acc.lastBalance ?? 0));
    final configuredCount = accounts.where((a) => a.isConfigured).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.2),
            const Color(0xFF1A1A1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Загальний баланс',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${totalBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${accounts.length}',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  accounts.length == 1 ? 'рахунок' : 'рахунки',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(IBKRAccount account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: account.isDefault
            ? Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 2)
            : Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAccountDetails(account),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          account.accountTypeEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                account.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (account.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C853).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Основний',
                                    style: TextStyle(
                                      color: Color(0xFF00C853),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            account.accountNumber ?? account.accountTypeName,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      color: const Color(0xFF2A2A2A),
                      onSelected: (value) => _handleMenuAction(value, account),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Colors.white70),
                              SizedBox(width: 8),
                              Text('Редагувати', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        if (!account.isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 18, color: Color(0xFFD4AF37)),
                                SizedBox(width: 8),
                                Text('Зробити основним', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'sync',
                          child: Row(
                            children: [
                              Icon(Icons.sync, size: 18, color: Colors.blueAccent),
                              SizedBox(width: 8),
                              Text('Налаштування синхронізації', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Видалити', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Баланс та статус
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Баланс',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          Text(
                            account.formattedBalance,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(account),
                  ],
                ),

                // Остання синхронізація
                if (account.lastSyncTime != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Оновлено: ${_formatDate(account.lastSyncTime!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(IBKRAccount account) {
    if (account.lastError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
            SizedBox(width: 4),
            Text(
              'Помилка',
              style: TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (!account.isConfigured) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings, size: 14, color: Colors.orangeAccent),
            SizedBox(width: 4),
            Text(
              'Налаштувати',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (account.isAutoSyncEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00C853).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync, size: 14, color: Color(0xFF00C853)),
            SizedBox(width: 4),
            Text(
              'Авто-синхронізація',
              style: TextStyle(color: Color(0xFF00C853), fontSize: 11),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAddButton() {
    return OutlinedButton.icon(
      onPressed: _showCreateAccountDialog,
      icon: const Icon(Icons.add, color: Color(0xFFD4AF37)),
      label: const Text(
        'Додати ще один рахунок',
        style: TextStyle(color: Color(0xFFD4AF37)),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, IBKRAccount account) async {
    switch (action) {
      case 'edit':
        _showEditAccountDialog(account);
        break;
      case 'default':
        await _accountService.setAsDefault(account.id);
        _showSnackBar('${account.name} тепер основний рахунок');
        break;
      case 'sync':
        _showSyncSettingsDialog(account);
        break;
      case 'delete':
        _showDeleteConfirmation(account);
        break;
    }
  }

  void _showCreateAccountDialog() {
    final nameController = TextEditingController();
    final accountNumberController = TextEditingController();
    String? selectedType = AccountType.individual;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Новий рахунок', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Назва рахунку',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'напр. Основний, Пенсійний',
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  filled: true,
                  fillColor: const Color(0xFF0F0F0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Номер рахунку (опційно)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'U1234567',
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  filled: true,
                  fillColor: const Color(0xFF0F0F0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Тип рахунку',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F0F0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: AccountType.all.map((type) => DropdownMenuItem(
                  value: type['value'],
                  child: Text('${type['emoji']} ${type['label']}'),
                )).toList(),
                onChanged: (value) => selectedType = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                _showSnackBar('Введіть назву рахунку');
                return;
              }

              await _accountService.createAccount(
                name: nameController.text.trim(),
                accountNumber: accountNumberController.text.trim().isEmpty
                    ? null
                    : accountNumberController.text.trim(),
                accountType: selectedType,
              );

              Navigator.pop(context);
              _showSnackBar('Рахунок створено');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('Створити'),
          ),
        ],
      ),
    );
  }

  void _showEditAccountDialog(IBKRAccount account) {
    final nameController = TextEditingController(text: account.name);
    final accountNumberController = TextEditingController(text: account.accountNumber ?? '');
    String? selectedType = account.accountType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Редагувати рахунок', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Назва рахунку',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F0F0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Номер рахунку',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F0F0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Тип рахунку',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F0F0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: AccountType.all.map((type) => DropdownMenuItem(
                  value: type['value'],
                  child: Text('${type['emoji']} ${type['label']}'),
                )).toList(),
                onChanged: (value) => selectedType = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _accountService.updateAccount(account.id, {
                'name': nameController.text.trim(),
                'accountNumber': accountNumberController.text.trim().isEmpty
                    ? null
                    : accountNumberController.text.trim(),
                'accountType': selectedType,
              });

              Navigator.pop(context);
              _showSnackBar('Рахунок оновлено');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  void _showSyncSettingsDialog(IBKRAccount account) {
    final tokenController = TextEditingController(text: account.ibkrToken ?? '');
    final queryIdController = TextEditingController(text: account.queryId ?? '');
    bool showToken = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'Синхронізація: ${account.name}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tokenController,
                  obscureText: !showToken,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'IBKR Flex Token',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.key, color: Color(0xFFD4AF37)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showToken ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => showToken = !showToken),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F0F0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: queryIdController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Query ID',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.numbers, color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: const Color(0xFF0F0F0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await _accountService.updateAccountCredentials(
                  account.id,
                  ibkrToken: tokenController.text.trim(),
                  queryId: queryIdController.text.trim(),
                );

                Navigator.pop(context);
                _showSnackBar('Налаштування збережено');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountDetails(IBKRAccount account) {
    // TODO: Можна відкрити детальний екран рахунку
    _showEditAccountDialog(account);
  }

  void _showDeleteConfirmation(IBKRAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Видалити рахунок?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Ви впевнені, що хочете видалити "${account.name}"?\n\nЦя дія видалить всі звіти та дані цього рахунку.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _accountService.deleteAccount(account.id);
              Navigator.pop(context);
              _showSnackBar('Рахунок видалено');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A2A2A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'щойно';
    if (diff.inHours < 1) return '${diff.inMinutes} хв тому';
    if (diff.inDays < 1) return '${diff.inHours} год тому';
    if (diff.inDays < 7) return '${diff.inDays} дн тому';

    return '${date.day}.${date.month}.${date.year}';
  }
}
