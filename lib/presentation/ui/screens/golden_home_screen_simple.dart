import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoldenHomeScreen extends ConsumerStatefulWidget {
  const GoldenHomeScreen({super.key});

  @override
  ConsumerState<GoldenHomeScreen> createState() => _GoldenHomeScreenState();
}

class _GoldenHomeScreenState extends ConsumerState<GoldenHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Golden Home Screen - Test',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
