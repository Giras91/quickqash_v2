import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';

class TrainingBanner extends ConsumerWidget {
  const TrainingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final training = ref.watch(trainingModeProvider);

    if (!training) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.orange,
      child: const Text(
        'TRAINING MODE - Practice data only',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class TrainingBadge extends ConsumerWidget {
  const TrainingBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final training = ref.watch(trainingModeProvider);

    if (!training) return const SizedBox.shrink();

    return Chip(
      label: const Text(
        'TRAINING',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.orange.shade100,
      side: const BorderSide(color: Colors.orange),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
