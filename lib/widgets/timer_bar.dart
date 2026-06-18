import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// The shot-clock progress bar shown during an IPL Trivia question.
// The bar shrinks from full-width (10s) to empty (0s) as time runs out.
// Colour transitions: green → gold → red (matching the CSS gradient).
class TimerBar extends StatelessWidget {
  final int timeLeft;     // Seconds remaining (0–10)
  final int totalTime;    // Total duration in seconds (default 10)

  const TimerBar({
    super.key,
    required this.timeLeft,
    this.totalTime = 10,
  });

  @override
  Widget build(BuildContext context) {
    // What fraction of the bar should be filled? (0.0 = empty, 1.0 = full)
    final fraction = (timeLeft / totalTime).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels: "Powerplay clock" on the left, "7s left" on the right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Powerplay clock', style: CrickifyTextStyles.bodyMuted),
            Text('${timeLeft}s left', style: CrickifyTextStyles.button.copyWith(
              color: CrickifyColors.cream,
            )),
          ],
        ),
        const SizedBox(height: 8),
        // The progress bar track
        Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x14FFF7DF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CrickifyColors.line, width: 1),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              // Width as a fraction of the track
              width: MediaQuery.of(context).size.width * fraction,
              decoration: BoxDecoration(
                // Green → Gold → Red gradient matching legacy CSS
                gradient: const LinearGradient(
                  colors: [
                    CrickifyColors.good,
                    CrickifyColors.ropeLight,
                    CrickifyColors.danger,
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
