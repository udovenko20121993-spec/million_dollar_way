import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:million_dollar_way/models/ibkr_data.dart';
import 'package:million_dollar_way/models/ibkr_account.dart';
import 'package:million_dollar_way/presentation/dashboard/widgets/capital_chart.dart';
import 'package:million_dollar_way/presentation/benchmark/benchmark_comparison_card.dart';
import 'package:million_dollar_way/presentation/accounts/account_selector.dart';
import 'package:million_dollar_way/presentation/accounts/accounts_screen.dart';
import 'package:million_dollar_way/services/account_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String userId = "user_test_1";
  late AccountService _accountService;
  IBKRAccount? _selectedAccount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _accountService = AccountService(userId: userId);
    _loadSelectedAccount();
  }

  Future<void> _loadSelectedAccount() async {
    // Міграція старих даних (якщо потрібно)
    await _accountService.migrateFromOldFormat();
    
    final account = await _accountService.getSelectedAccount();
    if (mounted) {
      setState(() {
        _selectedAccount = account;
        _isLoading = false;
      });
    }
  }

  void _onAccountChanged(IBKRAccount account) {
    setState(() => _selectedAccount = account);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_graph, color: Color(0xFF00C853)),
            SizedBox(width: 10),
            Text(
              'Million Dollar Way',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        centerTitle: false,
        actions: [
          // Селектор рахунку
          AccountSelector(
            userId: userId,
            currentAccount: _selectedAccount,
            onAccountChanged: _onAccountChanged,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _selectedAccount == null
                ? _buildNoAccountState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildNoAccountState() {
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
              'Почніть з додавання рахунку',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Додайте ваш рахунок IBKR\nдля відстеження інвестицій',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountsScreen(
                      userId: userId,
                      openCreateDialog: true,
                    ),
                  ),
                ).then((_) => _loadSelectedAccount());
              },
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

  Widget _buildContent() {
    // Для сумісності зі старим форматом перевіряємо обидві колекції
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(_selectedAccount!.id)
          .collection('reports')
          .snapshots(),
      builder: (context, accountSnapshot) {
        // Якщо в новій структурі немає даних, пробуємо стару
        if (!accountSnapshot.hasData || accountSnapshot.data!.docs.isEmpty) {
          return _buildFromOldStructure();
        }

        return _buildReportContent(accountSnapshot.data!.docs);
      },
    );
  }

  Widget _buildFromOldStructure() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reports')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _buildEmptyReportsState();
        }

        return _buildReportContent(docs);
      },
    );
  }

  Widget _buildEmptyReportsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart_outlined, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              'Немає даних',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Завантажте звіт для цього рахунку',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(List<QueryDocumentSnapshot> docs) {
    // Сортуємо (найсвіжіший звіт зверху)
    docs.sort((a, b) {
      final tA = (a.data() as Map)['lastSyncTime'];
      final tB = (b.data() as Map)['lastSyncTime'];
      if (tA == null) return 1;
      if (tB == null) return -1;
      return (tB as Timestamp).compareTo(tA as Timestamp);
    });

    final report = IBKRReport.fromFirestore(docs.first);

    // Розрахунки
    double netFlow = report.totalDeposits + report.totalWithdrawals;
    double profit = report.lastBalance - netFlow;
    double profitPercent = netFlow != 0 ? (profit / netFlow.abs()) * 100 : 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Інформація про рахунок (якщо більше одного)
          FutureBuilder<int>(
            future: _accountService.getAccountCount(),
            builder: (context, snapshot) {
              if (snapshot.data != null && snapshot.data! > 1) {
                return _buildAccountInfoCard();
              }
              return const SizedBox.shrink();
            },
          ),

          // 1. ГОЛОВНА КАРТКА (Баланс + Прибуток)
          _buildMainCard(report.lastBalance, profit, profitPercent),

          const SizedBox(height: 24),

          // 2. СТАТИСТИКА (Плитки 2x2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    "Дивіденди",
                    "+${report.totalDividends.toStringAsFixed(2)}\$",
                    Icons.attach_money,
                    Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatTile(
                    "Комісії",
                    "${report.totalCommissions.toStringAsFixed(2)}\$",
                    Icons.receipt_long,
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    "Внесено",
                    "${report.totalDeposits.toStringAsFixed(0)}\$",
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatTile(
                    "Виведено",
                    "${report.totalWithdrawals.toStringAsFixed(0)}\$",
                    Icons.arrow_upward,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 3. ГРАФІК КАПІТАЛУ
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Динаміка",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          CapitalChart(trades: report.trades),

          const SizedBox(height: 24),

          // 4. ПОРІВНЯННЯ З S&P 500
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "vs S&P 500",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          BenchmarkComparisonCard(userId: userId),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    if (_selectedAccount == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            _selectedAccount!.accountTypeEmoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedAccount!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedAccount!.accountNumber != null)
                  Text(
                    _selectedAccount!.accountNumber!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountsScreen(userId: userId),
                ),
              ).then((_) => _loadSelectedAccount());
            },
            child: const Text(
              'Усі рахунки',
              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Віджет головної картки
  Widget _buildMainCard(double balance, double profit, double percent) {
    bool isPos = profit >= 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF0F0F0F).withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: (isPos ? const Color(0xFF00C853) : Colors.red).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Загальний капітал",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "${balance.toStringAsFixed(2)}\$",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isPos ? Colors.green : Colors.red).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPos ? Icons.trending_up : Icons.trending_down,
                  color: isPos ? const Color(0xFF00C853) : Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "${isPos ? '+' : ''}${profit.toStringAsFixed(2)}\$ (${percent.toStringAsFixed(2)}%)",
                  style: TextStyle(
                    color: isPos ? const Color(0xFF00C853) : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Віджет плитки статистики
  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
