import 'package:flutter/material.dart';
import '../../models/ibkr_account.dart';
import '../../services/account_service.dart';
import 'accounts_screen.dart';

/// Випадаючий список для вибору рахунку
class AccountSelector extends StatefulWidget {
  final String userId;
  final Function(IBKRAccount) onAccountChanged;
  final IBKRAccount? currentAccount;

  const AccountSelector({
    super.key,
    required this.userId,
    required this.onAccountChanged,
    this.currentAccount,
  });

  @override
  State<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<AccountSelector> {
  late AccountService _accountService;
  List<IBKRAccount> _accounts = [];
  IBKRAccount? _selectedAccount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _accountService = AccountService(userId: widget.userId);
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _accountService.getAccounts();
    final selected = widget.currentAccount ?? await _accountService.getSelectedAccount();

    if (mounted) {
      setState(() {
        _accounts = accounts;
        _selectedAccount = selected;
        _isLoading = false;
      });
    }
  }

  void _showAccountPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAccountPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 120,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_accounts.isEmpty) {
      return TextButton.icon(
        onPressed: () => _navigateToAccountsScreen(),
        icon: const Icon(Icons.add, size: 18, color: Color(0xFFD4AF37)),
        label: const Text(
          'Додати рахунок',
          style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13),
        ),
      );
    }

    return GestureDetector(
      onTap: _showAccountPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedAccount?.accountTypeEmoji ?? '💼',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              _selectedAccount?.name ?? 'Виберіть',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountPickerSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ручка
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Заголовок
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Виберіть рахунок',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.grey),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToAccountsScreen();
                    },
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10),

            // Список рахунків
            ...(_accounts.map((account) => _buildAccountTile(account))),

            // Кнопка додавання
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFFD4AF37),
                ),
              ),
              title: const Text(
                'Додати рахунок',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToAccountsScreen(openCreate: true);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(IBKRAccount account) {
    final isSelected = _selectedAccount?.id == account.id;
    
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFD4AF37).withOpacity(0.2)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFFD4AF37), width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            account.accountTypeEmoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            account.name,
            style: TextStyle(
              color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      subtitle: Text(
        account.lastBalance != null
            ? account.formattedBalance
            : (account.accountNumber ?? 'Не налаштовано'),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37))
          : null,
      onTap: () async {
        await _accountService.setSelectedAccountId(account.id);
        setState(() => _selectedAccount = account);
        widget.onAccountChanged(account);
        Navigator.pop(context);
      },
    );
  }

  void _navigateToAccountsScreen({bool openCreate = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountsScreen(
          userId: widget.userId,
          openCreateDialog: openCreate,
        ),
      ),
    ).then((_) => _loadAccounts());
  }
}

/// Компактна версія селектора для AppBar
class CompactAccountSelector extends StatefulWidget {
  final String userId;
  final Function(IBKRAccount) onAccountChanged;

  const CompactAccountSelector({
    super.key,
    required this.userId,
    required this.onAccountChanged,
  });

  @override
  State<CompactAccountSelector> createState() => _CompactAccountSelectorState();
}

class _CompactAccountSelectorState extends State<CompactAccountSelector> {
  late AccountService _accountService;
  IBKRAccount? _selectedAccount;
  int _accountCount = 0;

  @override
  void initState() {
    super.initState();
    _accountService = AccountService(userId: widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    final selected = await _accountService.getSelectedAccount();
    final count = await _accountService.getAccountCount();

    if (mounted) {
      setState(() {
        _selectedAccount = selected;
        _accountCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Показуємо тільки якщо є більше одного рахунку
    if (_accountCount <= 1) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _AccountPickerSheet(
            userId: widget.userId,
            selectedAccount: _selectedAccount,
            onSelect: (account) async {
              await _accountService.setSelectedAccountId(account.id);
              setState(() => _selectedAccount = account);
              widget.onAccountChanged(account);
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedAccount?.accountTypeEmoji ?? '💼',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.unfold_more, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _AccountPickerSheet extends StatelessWidget {
  final String userId;
  final IBKRAccount? selectedAccount;
  final Function(IBKRAccount) onSelect;

  const _AccountPickerSheet({
    required this.userId,
    required this.selectedAccount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: StreamBuilder<List<IBKRAccount>>(
          stream: AccountService(userId: userId).getAccountsStream(),
          builder: (context, snapshot) {
            final accounts = snapshot.data ?? [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Рахунки',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...accounts.map((acc) => ListTile(
                  leading: Text(acc.accountTypeEmoji, style: const TextStyle(fontSize: 24)),
                  title: Text(acc.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    acc.formattedBalance,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  trailing: selectedAccount?.id == acc.id
                      ? const Icon(Icons.check, color: Color(0xFFD4AF37))
                      : null,
                  onTap: () {
                    onSelect(acc);
                    Navigator.pop(context);
                  },
                )),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
