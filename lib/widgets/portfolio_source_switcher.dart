import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_source_provider.dart';
import '../domain/enums/portfolio_source.dart';

class PortfolioSourceSwitcher extends ConsumerWidget {
  const PortfolioSourceSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PortfolioSource selectedSource = ref.watch(
      selectedPortfolioSourceProvider,
    );
    final List<PortfolioSource> availableSources = ref.watch(
      availablePortfolioSourcesProvider,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Джерело активів',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Modern segmented control
          _buildModernSegmentedControl(selectedSource, availableSources, ref),
        ],
      ),
    );
  }

  Widget _buildModernSegmentedControl(
    PortfolioSource selectedSource,
    List<PortfolioSource> availableSources,
    WidgetRef ref,
  ) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: availableSources.map((source) {
          final isSelected = selectedSource == source;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedPortfolioSourceProvider.notifier).state =
                    source;
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD4AF37)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    source.displayName,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : const Color(0xFFD4AF37).withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Alternative CupertinoSlidingSegmentedControl version
class PortfolioSourceSwitcherCupertino extends ConsumerWidget {
  const PortfolioSourceSwitcherCupertino({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSource = ref.watch(selectedPortfolioSourceProvider);
    final availableSources = ref.watch(availablePortfolioSourcesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Джерело активів',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Cupertino segmented control
          CupertinoSlidingSegmentedControl<PortfolioSource>(
            groupValue: selectedSource,
            backgroundColor: const Color(0xFF1a1a1a),
            thumbColor: const Color(0xFFD4AF37),
            children: Map.fromEntries(
              availableSources.map(
                (source) => MapEntry(
                  source,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      source.displayName,
                      style: TextStyle(
                        color: selectedSource == source
                            ? Colors.black
                            : const Color(0xFFD4AF37).withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            onValueChanged: (PortfolioSource? newSource) {
              if (newSource != null) {
                ref.read(selectedPortfolioSourceProvider.notifier).state =
                    newSource;
              }
            },
          ),
        ],
      ),
    );
  }
}

// ChoiceChip version for more flexibility
class PortfolioSourceSwitcherChips extends ConsumerWidget {
  const PortfolioSourceSwitcherChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSource = ref.watch(selectedPortfolioSourceProvider);
    final availableSources = ref.watch(availablePortfolioSourcesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Джерело активів',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Choice chips
          Wrap(
            spacing: 8,
            children: availableSources.map((source) {
              final isSelected = selectedSource == source;
              return ChoiceChip(
                label: Text(
                  source.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.black : const Color(0xFFD4AF37),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(selectedPortfolioSourceProvider.notifier).state =
                        source;
                  }
                },
                backgroundColor: const Color(0xFF1a1a1a),
                selectedColor: const Color(0xFFD4AF37),
                side: BorderSide(
                  color: const Color(0xFFD4AF37).withOpacity(0.5),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
