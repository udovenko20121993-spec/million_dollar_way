import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:million_dollar_way/services/file_service.dart';
import 'package:million_dollar_way/services/ibkr_api_service.dart';
import 'package:million_dollar_way/services/import_preview_service.dart';
import 'package:million_dollar_way/presentation/reports/import_preview_dialog.dart';
import 'package:million_dollar_way/presentation/reports/export_dialog.dart';

class IBKRReportCatalogScreen extends StatelessWidget {
  const IBKRReportCatalogScreen({super.key});

  final String userId = "user_test_1";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          "Керування звітами",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('reports')
            .orderBy('lastSyncTime', descending: true)
            .limit(10) // Оптимізація: вантажимо тільки 10 останніх
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Помилка: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text("Звітів немає", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            cacheExtent: 100,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final reportId = docs[index].id;
              // Виносимо картку в окремий віджет, щоб він мав свій Progress Bar
              return ReportCard(
                key: ValueKey(reportId),
                data: data,
                reportId: reportId,
                userId: userId,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00C853),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreateReportDialog(context),
      ),
    );
  }

  void _showCreateReportDialog(BuildContext context) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Новий звіт", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Назва"),
        ),
        actions: [
          TextButton(
            child: const Text("Створити"),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('reports')
                  .add({
                    'name': c.text.isEmpty ? "Мій Портфель" : c.text,
                    'lastSyncTime': FieldValue.serverTimestamp(),
                    'sourceFiles': [],
                    'assets': [],
                    'trades': [],
                    'dividends': [],
                    'cashTransactions': [],
                    'totalCommissions': 0.0,
                    'totalDeposits': 0.0,
                    'totalWithdrawals': 0.0,
                    'lastBalance': 0.0,
                    'cashBalance': 0.0,
                  });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

// --- ОКРЕМИЙ ВІДЖЕТ КАРТКИ ЗІ СМУГОЮ ЗАВАНТАЖЕННЯ ---
class ReportCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String reportId;
  final String userId;

  const ReportCard({
    super.key,
    required this.data,
    required this.reportId,
    required this.userId,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  // --- СТАН ЗАВАНТАЖЕННЯ ---
  bool _isUploading = false;
  double _progressValue = 0.0;
  String _statusText = "";

  @override
  Widget build(BuildContext context) {
    String name = widget.data['name'] ?? 'Без назви';
    Timestamp? lastSync = widget.data['lastSyncTime'];
    String lastSyncStr = lastSync != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(lastSync.toDate())
        : "Ніколи";

    List<dynamic> sourceFilesRaw = widget.data['sourceFiles'] ?? [];

    String? token = widget.data['ibkrToken'];
    String? queryId = widget.data['queryId'];
    bool hasApiConfig =
        token != null &&
        token.isNotEmpty &&
        queryId != null &&
        queryId.isNotEmpty;

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder, color: Color(0xFF00C853)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Оновлено: $lastSyncStr",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  color: const Color(0xFF2C2C2C),
                  onSelected: (value) {
                    if (!_isUploading) {
                      // Блокуємо дії під час завантаження
                      if (value == 'api')
                        _showApiConfigDialog(context, token, queryId);
                      if (value == 'rename') _showRenameDialog(context, name);
                      if (value == 'export') {
                        showExportDialog(
                          context,
                          userId: widget.userId,
                          reportId: widget.reportId,
                          reportName: name,
                        );
                      }
                      if (value == 'delete') _showDeleteConfirmation(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'api',
                      child: Text('API', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Text(
                        '📊 Експорт CSV',
                        style: TextStyle(color: Color(0xFF00C853)),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text(
                        'Перейменувати',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Видалити',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- БЛОК ЗАВАНТАЖЕННЯ (ПРОГРЕС БАР) ---
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00C853),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _statusText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${(_progressValue * 100).toInt()}%",
                        style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (sourceFilesRaw.isNotEmpty)
            ExpansionTile(
              collapsedIconColor: Colors.grey,
              iconColor: const Color(0xFF00C853),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                "Історія файлів (${sourceFilesRaw.length})",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              children: sourceFilesRaw.map((fileItem) {
                String fileName = "";
                String dateStr = "";
                bool isSuccess = true;
                Map<String, dynamic>? stats;

                if (fileItem is String) {
                  fileName = fileItem;
                  dateStr = "Old format";
                } else if (fileItem is Map) {
                  fileName = fileItem['name'] ?? 'N/A';
                  String rawDate = fileItem['uploadTime'] ?? '';
                  if (rawDate.isNotEmpty) {
                    try {
                      dateStr = DateFormat(
                        'dd.MM HH:mm',
                      ).format(DateTime.parse(rawDate));
                    } catch (_) {}
                  }
                  isSuccess = fileItem['status'] != 'error';
                  stats = fileItem['stats'] as Map<String, dynamic>?;
                }

                return _buildFileHistoryItem(
                  context,
                  sourceFilesRaw,
                  fileItem,
                  fileName,
                  dateStr,
                  isSuccess,
                  stats,
                );
              }).toList(),
            ),

          const Divider(height: 1, color: Colors.white10),

          // КНОПКИ (Блокуємо їх, якщо йде завантаження)
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () {
                          if (hasApiConfig)
                            _runApiSync(context, token!, queryId!);
                          else
                            _showApiConfigDialog(context, token, queryId);
                        },
                  icon: Icon(
                    Icons.sync,
                    size: 18,
                    color: _isUploading
                        ? Colors.grey
                        : (hasApiConfig ? Colors.blueAccent : Colors.grey),
                  ),
                  label: Text(
                    hasApiConfig ? "Синхронізувати" : "API",
                    style: TextStyle(
                      color: _isUploading
                          ? Colors.grey
                          : (hasApiConfig ? Colors.blueAccent : Colors.grey),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.white10),
              Expanded(
                child: TextButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _handleFileUpload(context),
                  icon: Icon(
                    Icons.upload_file,
                    size: 18,
                    color: _isUploading ? Colors.grey : const Color(0xFF00C853),
                  ),
                  label: Text(
                    "Додати XML",
                    style: TextStyle(
                      color: _isUploading
                          ? Colors.grey
                          : const Color(0xFF00C853),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ЛОГІКА ЗАВАНТАЖЕННЯ З ПРОГРЕСОМ ТА PREVIEW ---
  Future<void> _handleFileUpload(BuildContext context) async {
    final fileService = FileService();
    final previewService = ImportPreviewService();
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      // Обробляємо кожен файл окремо з preview
      for (var file in result.files) {
        // 1. Створюємо preview
        setState(() {
          _isUploading = true;
          _progressValue = 0.2;
          _statusText = "Аналіз: ${file.name}";
        });

        await Future.delayed(const Duration(milliseconds: 200));

        final preview = await previewService.createPreview(
          file,
          userId: widget.userId,
          reportId: widget.reportId,
        );

        setState(() {
          _isUploading = false;
          _progressValue = 0;
          _statusText = "";
        });

        // 2. Показуємо діалог попереднього перегляду
        if (!context.mounted) return;
        
        final shouldImport = await showImportPreviewDialog(context, preview);

        if (!shouldImport) {
          // Користувач скасував - переходимо до наступного файлу
          continue;
        }

        // 3. Імпортуємо файл
        setState(() {
          _isUploading = true;
          _progressValue = 0.5;
          _statusText = "Імпорт: ${file.name}";
        });

        await Future.delayed(const Duration(milliseconds: 100));

        await fileService.parseAndMergeReport(
          widget.userId,
          widget.reportId,
          file,
          file.name,
        );

        setState(() {
          _progressValue = 1.0;
          _statusText = "✅ ${file.name} імпортовано!";
        });

        await Future.delayed(const Duration(milliseconds: 800));

        setState(() {
          _isUploading = false;
          _progressValue = 0;
          _statusText = "";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = "Помилка: $e";
          _progressValue = 0.0;
        });
        await Future.delayed(const Duration(seconds: 3));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _progressValue = 0.0;
          _statusText = "";
        });
      }
    }
  }

  // --- ЛОГІКА API З ПРОГРЕСОМ ---
  Future<void> _runApiSync(
    BuildContext context,
    String token,
    String queryId,
  ) async {
    final apiService = IbkrApiService();
    final fileService = FileService();

    setState(() {
      _isUploading = true;
      _progressValue = 0.1;
      _statusText = "З'єднання з IBKR...";
    });

    try {
      String xml = await apiService.downloadReport(token, queryId);

      setState(() {
        _progressValue = 0.4;
        _statusText = "Звіт отримано. Обробка...";
      });
      await Future.delayed(const Duration(milliseconds: 200));

      final bytes = utf8.encode(xml);
      String fName =
          "IBKR_API_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xml";
      final vFile = PlatformFile(name: fName, size: bytes.length, bytes: bytes);

      setState(() {
        _progressValue = 0.7;
        _statusText = "Збереження в базу...";
      });

      await fileService.parseAndMergeReport(
        widget.userId,
        widget.reportId,
        vFile,
        "API Auto-Sync",
      );

      setState(() {
        _progressValue = 1.0;
        _statusText = "✅ Успішно оновлено!";
      });

      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      setState(() => _statusText = "Помилка API: $e");
      await Future.delayed(const Duration(seconds: 3));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- ІНШІ ДІАЛОГИ (Rename, Delete, Config) ---
  void _showApiConfigDialog(
    BuildContext context,
    String? token,
    String? queryId,
  ) {
    final tCtrl = TextEditingController(text: token);
    final qCtrl = TextEditingController(text: queryId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tCtrl,
              decoration: const InputDecoration(labelText: "Token"),
            ),
            TextField(
              controller: qCtrl,
              decoration: const InputDecoration(labelText: "Query ID"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('reports')
                  .doc(widget.reportId)
                  .update({'ibkrToken': tCtrl.text, 'queryId': qCtrl.text});
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    final c = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        content: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: const Text("Зберегти"),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('reports')
                  .doc(widget.reportId)
                  .update({'name': c.text});
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Видалити звіт?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: const Text("Так", style: TextStyle(color: Colors.red)),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('reports')
                  .doc(widget.reportId)
                  .delete();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _renameFileInHistory(
    BuildContext context,
    List<dynamic> fullList,
    dynamic itemToRename,
  ) {
    String currentName = "";
    if (itemToRename is String)
      currentName = itemToRename;
    else if (itemToRename is Map)
      currentName = itemToRename['name'];

    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Змінити назву",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: const Text(
              "Зберегти",
              style: TextStyle(color: Color(0xFF00C853)),
            ),
            onPressed: () async {
              List<dynamic> newList = List.from(fullList);
              int index = newList.indexOf(itemToRename);
              if (index != -1) {
                if (newList[index] is String)
                  newList[index] = ctrl.text.trim();
                else if (newList[index] is Map) {
                  Map<String, dynamic> newMap = Map.from(newList[index]);
                  newMap['name'] = ctrl.text.trim();
                  newList[index] = newMap;
                }
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .collection('reports')
                    .doc(widget.reportId)
                    .update({'sourceFiles': newList});
              }
              if (context.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _deleteFileFromHistory(
    BuildContext context,
    List<dynamic> fullList,
    dynamic itemToDelete,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Видалити запис?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: const Text("Так", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              List<dynamic> newList = List.from(fullList);
              newList.remove(itemToDelete);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('reports')
                  .doc(widget.reportId)
                  .update({'sourceFiles': newList});
              if (context.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // --- ВІДЖЕТ ЕЛЕМЕНТА ІСТОРІЇ ФАЙЛІВ ЗІ СТАТИСТИКОЮ ---
  Widget _buildFileHistoryItem(
    BuildContext context,
    List<dynamic> sourceFilesRaw,
    dynamic fileItem,
    String fileName,
    String dateStr,
    bool isSuccess,
    Map<String, dynamic>? stats,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? const Color(0xFF00C853) : Colors.redAccent,
              size: 20,
            ),
            title: Text(
              fileName,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              dateStr,
              style: TextStyle(
                color: Colors.grey.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_horiz,
                size: 18,
                color: Colors.grey,
              ),
              color: const Color(0xFF2C2C2C),
              enabled: !_isUploading,
              onSelected: (action) {
                if (action == 'rename') {
                  _renameFileInHistory(context, sourceFilesRaw, fileItem);
                }
                if (action == 'delete') {
                  _deleteFileFromHistory(context, sourceFilesRaw, fileItem);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Text(
                    'Змінити',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Видалити',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // === СТАТИСТИКА ===
          if (stats != null) _buildFileStats(stats),
        ],
      ),
    );
  }

  Widget _buildFileStats(Map<String, dynamic> stats) {
    final trades = stats['addedTrades'] ?? 0;
    final dividends = stats['addedDividends'] ?? 0;
    final depositsAmount = (stats['depositsAmount'] ?? 0).toDouble();
    final withdrawalsAmount = (stats['withdrawalsAmount'] ?? 0).toDouble();
    final dividendsAmount = (stats['dividendsAmount'] ?? 0).toDouble();
    final commissionsAmount = (stats['commissionsAmount'] ?? 0).toDouble();

    // Якщо немає даних - не показуємо
    if (trades == 0 && dividends == 0 && depositsAmount == 0 && dividendsAmount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (trades > 0)
            _buildStatChip('📊 $trades угод', Colors.blueAccent),
          if (dividends > 0)
            _buildStatChip(
              '💰 +\$${dividendsAmount.toStringAsFixed(0)}',
              Colors.orangeAccent,
            ),
          if (depositsAmount > 0)
            _buildStatChip(
              '⬆️ +\$${depositsAmount.toStringAsFixed(0)}',
              Colors.greenAccent,
            ),
          if (withdrawalsAmount > 0)
            _buildStatChip(
              '⬇️ -\$${withdrawalsAmount.toStringAsFixed(0)}',
              Colors.orange,
            ),
          if (commissionsAmount > 0)
            _buildStatChip(
              '💸 -\$${commissionsAmount.toStringAsFixed(2)}',
              Colors.redAccent,
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
