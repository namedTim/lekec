import 'package:flutter/material.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}
