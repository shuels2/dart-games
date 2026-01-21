import 'package:flutter/material.dart';

class WizardProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const WizardProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            totalSteps,
            (index) => _buildStepIndicator(index, theme),
          ),
        ),
        const SizedBox(height: 12),
        // Current step label
        Text(
          stepLabels[currentStep],
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        // Step count
        Text(
          'Step ${currentStep + 1} of $totalSteps',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int index, ThemeData theme) {
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;

    Color indicatorColor;
    if (isCompleted) {
      indicatorColor = theme.colorScheme.primary;
    } else if (isCurrent) {
      indicatorColor = theme.colorScheme.primary;
    } else {
      indicatorColor = theme.colorScheme.onSurface.withOpacity(0.3);
    }

    return Row(
      children: [
        if (index > 0) _buildConnector(isCompleted, theme),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? theme.colorScheme.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: indicatorColor,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  )
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isCompleted, ThemeData theme) {
    return Container(
      width: 40,
      height: 2,
      color: isCompleted
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface.withOpacity(0.3),
    );
  }
}
