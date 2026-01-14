import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../services/ibkr_service.dart';

/// Screen for connecting to IBKR
class IbkrConnectionScreen extends StatefulWidget {
  const IbkrConnectionScreen({super.key});

  @override
  State<IbkrConnectionScreen> createState() => _IbkrConnectionScreenState();
}

class _IbkrConnectionScreenState extends State<IbkrConnectionScreen> {
  final _tokenController = TextEditingController();
  final _queryIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final hasCredentials = await SecureStorageService.hasIbkrCredentials();
    if (hasCredentials) {
      final token = await SecureStorageService.getIbkrToken();
      final queryId = await SecureStorageService.getIbkrQueryId();
      setState(() {
        _tokenController.text = token ?? '';
        _queryIdController.text = queryId ?? '';
        _isConnected = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await SecureStorageService.saveIbkrCredentials(
        token: _tokenController.text.trim(),
        queryId: _queryIdController.text.trim(),
      );

      setState(() {
        _isConnected = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IBKR credentials saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving credentials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    final token = _tokenController.text.trim();
    final queryId = _queryIdController.text.trim();

    if (token.isEmpty || queryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter token and query ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await IbkrService.fetchFlexQuery(token, queryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IBKR Connection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isConnected)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Connected to IBKR'),
                    ],
                  ),
                ),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'IBKR Token',
                  hintText: 'Enter your IBKR Flex Query token',
                ),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Token is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _queryIdController,
                decoration: const InputDecoration(
                  labelText: 'Query ID',
                  hintText: 'Enter your Flex Query ID',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Query ID is required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _testConnection,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test Connection'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isLoading ? null : _saveCredentials,
                child: const Text('Save Credentials'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _queryIdController.dispose();
    super.dispose();
  }
}
