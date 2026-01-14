import 'package:flutter/material.dart';

/// Dialog showing security information
class SecurityInfoDialog extends StatelessWidget {
  final String securityExplanation;

  const SecurityInfoDialog({
    super.key,
    required this.securityExplanation,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.blue),
          SizedBox(width: 8),
          Text('Безпека даних'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              securityExplanation,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildSecurityFeature(
              icon: Icons.encrypt,
              title: 'Шифрування',
              description: 'Всі дані шифруються перед збереженням',
            ),
            const SizedBox(height: 12),
            _buildSecurityFeature(
              icon: Icons.verified_user,
              title: 'Безпечне зберігання',
              description: 'Використовується Flutter Secure Storage',
            ),
            const SizedBox(height: 12),
            _buildSecurityFeature(
              icon: Icons.privacy_tip,
              title: 'Приватність',
              description: 'Дані не передаються третім особам',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Зрозуміло'),
        ),
      ],
    );
  }

  Widget _buildSecurityFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
