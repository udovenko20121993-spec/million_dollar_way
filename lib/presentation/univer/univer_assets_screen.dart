import 'package:flutter/material.dart';

import '../../domain/models/custom_portfolio_models.dart';
import '../../services/univer_service.dart';

class UniverAssetsScreen extends StatefulWidget {
  const UniverAssetsScreen({super.key});

  @override
  State<UniverAssetsScreen> createState() => _UniverAssetsScreenState();
}

class _UniverAssetsScreenState extends State<UniverAssetsScreen> {
  final UniverService _service = UniverService();
  final String _userId = 'user_test_1';
  final List<UniverAsset> _assets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final assets = await _service.getUniverAssets(_userId);
      setState(() {
        _assets
          ..clear()
          ..addAll(assets);
      });
    } catch (e) {
      setState(() {
        _error = 'Не вдалося завантажити активи: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _upsertAsset(UniverAsset asset, {bool isNew = false}) async {
    try {
      if (isNew) {
        await _service.addUniverAsset(_userId, asset);
      } else {
        await _service.updateUniverAsset(_userId, asset);
      }
      await _loadAssets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNew ? 'Актив додано' : 'Актив оновлено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Помилка збереження: $e')));
      }
    }
  }

  Future<void> _deleteAsset(UniverAsset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Видалити актив?'),
          content: Text('"${asset.name}" буде видалено назавжди.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Видалити'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      try {
        await _service.deleteUniverAsset(_userId, asset.id);
        await _loadAssets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Актив "${asset.name}" видалено')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Помилка видалення: $e')));
        }
      }
    }
  }

  void _openAssetForm({UniverAsset? asset}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: UniverAssetForm(
            initialAsset: asset,
            onSubmit: (result) => _upsertAsset(result, isNew: asset == null),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Активи Univer.ua'),
        actions: [
          IconButton(onPressed: _loadAssets, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAssetForm(),
        icon: const Icon(Icons.add),
        label: const Text('Новий актив'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadAssets,
              child: const Text('Спробувати знову'),
            ),
          ],
        ),
      );
    }

    if (_assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.savings_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Додайте свої перші активи з Univer.ua'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openAssetForm(),
              child: const Text('Додати актив'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssets,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final asset = _assets[index];
          return _UniverAssetCard(
            asset: asset,
            onEdit: () => _openAssetForm(asset: asset),
            onDelete: () => _deleteAsset(asset),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _assets.length,
      ),
    );
  }
}

class _UniverAssetCard extends StatelessWidget {
  const _UniverAssetCard({
    required this.asset,
    required this.onEdit,
    required this.onDelete,
  });

  final UniverAsset asset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _typeColor() {
    switch (asset.type) {
      case UniverAssetType.ovdp:
        return const Color(0xFF1E88E5);
      case UniverAssetType.stock:
        return const Color(0xFF43A047);
      case UniverAssetType.other:
      default:
        return const Color(0xFF8E24AA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _typeColor().withOpacity(0.15),
                  child: Text(asset.symbol.isNotEmpty ? asset.symbol[0] : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${asset.symbol} • ${asset.type.name.toUpperCase()}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _StatChip(
                  label: 'Інвестовано',
                  value: '₴${asset.initialInvestment.toStringAsFixed(0)}',
                ),
                _StatChip(
                  label: 'Поточна вартість',
                  value: '₴${asset.currentMarketValue.toStringAsFixed(0)}',
                ),
                _StatChip(
                  label: 'Купон',
                  value: '${asset.couponRate.toStringAsFixed(2)}%',
                ),
                if (asset.maturityDate != null)
                  _StatChip(
                    label: 'Погашення',
                    value:
                        '${asset.maturityDate!.day}.${asset.maturityDate!.month}.${asset.maturityDate!.year}',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  asset.belongsToDaughter
                      ? '🎁 У фонді доньки'
                      : 'Особистий актив',
                  style: TextStyle(
                    color: asset.belongsToDaughter
                        ? const Color(0xFFD81B60)
                        : Colors.blueGrey,
                  ),
                ),
                Text(
                  'Нараховано купонів: ₴${asset.totalDividendsPaid.toStringAsFixed(0)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class UniverAssetForm extends StatefulWidget {
  const UniverAssetForm({super.key, this.initialAsset, required this.onSubmit});

  final UniverAsset? initialAsset;
  final ValueChanged<UniverAsset> onSubmit;

  @override
  State<UniverAssetForm> createState() => _UniverAssetFormState();
}

class _UniverAssetFormState extends State<UniverAssetForm> {
  late TextEditingController _nameController;
  late TextEditingController _symbolController;
  late TextEditingController _initialInvestmentController;
  late TextEditingController _currentValueController;
  late TextEditingController _nominalController;
  late TextEditingController _couponController;
  late TextEditingController _accruedInterestController;
  late TextEditingController _dividendsController;
  late DateTime _purchaseDate;
  DateTime? _maturityDate;
  late UniverAssetType _type;
  bool _belongsToDaughter = false;
  late String _assetId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final asset = widget.initialAsset;
    _assetId = asset?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _nameController = TextEditingController(text: asset?.name ?? '');
    _symbolController = TextEditingController(text: asset?.symbol ?? '');
    _initialInvestmentController = TextEditingController(
      text: asset?.initialInvestment.toString() ?? '0',
    );
    _currentValueController = TextEditingController(
      text: asset?.currentMarketValue.toString() ?? '0',
    );
    _nominalController = TextEditingController(
      text: asset?.nominalValue.toString() ?? '0',
    );
    _couponController = TextEditingController(
      text: asset?.couponRate.toString() ?? '0',
    );
    _accruedInterestController = TextEditingController(
      text: asset?.accruedInterest.toString() ?? '0',
    );
    _dividendsController = TextEditingController(
      text: asset?.totalDividendsPaid.toString() ?? '0',
    );
    _purchaseDate = asset?.purchaseDate ?? DateTime.now();
    _maturityDate = asset?.maturityDate;
    _type = asset?.type ?? UniverAssetType.ovdp;
    _belongsToDaughter = asset?.belongsToDaughter ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _initialInvestmentController.dispose();
    _currentValueController.dispose();
    _nominalController.dispose();
    _couponController.dispose();
    _accruedInterestController.dispose();
    _dividendsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool forMaturity}) async {
    final initialDate = forMaturity
        ? (_maturityDate ?? DateTime.now().add(const Duration(days: 365)))
        : _purchaseDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (forMaturity) {
          _maturityDate = picked;
        } else {
          _purchaseDate = picked;
        }
      });
    }
  }

  double _parseDouble(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0.0;

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final asset = UniverAsset(
      id: _assetId,
      name: _nameController.text.trim(),
      symbol: _symbolController.text.trim(),
      type: _type,
      initialInvestment: _parseDouble(_initialInvestmentController.text),
      purchaseDate: _purchaseDate,
      maturityDate: _maturityDate,
      nominalValue: _parseDouble(_nominalController.text),
      couponRate: _parseDouble(_couponController.text),
      currentMarketValue: _parseDouble(_currentValueController.text),
      accruedInterest: _parseDouble(_accruedInterestController.text),
      totalDividendsPaid: _parseDouble(_dividendsController.text),
      belongsToDaughter: _belongsToDaughter,
    );

    widget.onSubmit(asset);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.initialAsset == null
                          ? 'Новий актив'
                          : 'Редагувати актив',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: Navigator.of(context).pop,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UniverAssetType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Тип активу'),
                  items: UniverAssetType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Назва активу'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Обов’язково'
                      : null,
                ),
                TextFormField(
                  controller: _symbolController,
                  decoration: const InputDecoration(labelText: 'Тикер / ISIN'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _initialInvestmentController,
                        decoration: const InputDecoration(
                          labelText: 'Початкове вкладення, ₴',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _currentValueController,
                        decoration: const InputDecoration(
                          labelText: 'Поточна вартість, ₴',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nominalController,
                        decoration: const InputDecoration(
                          labelText: 'Номінальна вартість, ₴',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _couponController,
                        decoration: const InputDecoration(
                          labelText: 'Купонна ставка, %',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _accruedInterestController,
                        decoration: const InputDecoration(
                          labelText: 'Нарахований купон, ₴',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dividendsController,
                        decoration: const InputDecoration(
                          labelText: 'Виплачені купони, ₴',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Дата купівлі'),
                        subtitle: Text(
                          '${_purchaseDate.day}.${_purchaseDate.month}.${_purchaseDate.year}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _pickDate(forMaturity: false),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Дата погашення'),
                        subtitle: Text(
                          _maturityDate == null
                              ? 'Не вказано'
                              : '${_maturityDate!.day}.${_maturityDate!.month}.${_maturityDate!.year}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.event_available),
                          onPressed: () => _pickDate(forMaturity: true),
                        ),
                      ),
                    ),
                  ],
                ),
                SwitchListTile.adaptive(
                  title: const Text('Належить доньці'),
                  value: _belongsToDaughter,
                  onChanged: (value) {
                    setState(() => _belongsToDaughter = value);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: const Text('Зберегти'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
