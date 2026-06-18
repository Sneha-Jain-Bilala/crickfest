import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// One of the six number buttons (1–6) the player taps in Hand Cricket.
// States: normal → selected (gold) → blocked by Yorker (red/dashed)
class ShotButton extends StatelessWidget {
  final int number;          // The number this button represents (1–6)
  final bool isSelected;     // Did this player pick this number?
  final bool isBlocked;      // Is this number blocked by the Yorker power card?
  final bool isDisabled;     // Can't be tapped (already chosen or not your turn)
  final VoidCallback? onTap; // What to do when tapped

  const ShotButton({
    super.key,
    required this.number,
    this.isSelected = false,
    this.isBlocked = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Pick colours based on state
    Color borderColor;
    Color bgColor;
    Color textColor;

    if (isBlocked) {
      borderColor = CrickifyColors.danger.withValues(alpha: 0.55);
      bgColor = CrickifyColors.danger.withValues(alpha: 0.10);
      textColor = const Color(0xFFFFC2AD);
    } else if (isSelected) {
      borderColor = CrickifyColors.ropeLight.withValues(alpha: 0.72);
      bgColor = CrickifyColors.ropeLight.withValues(alpha: 0.12);
      textColor = CrickifyColors.ropeLight;
    } else {
      borderColor = CrickifyColors.line;
      bgColor = const Color(0x12FFF7DF);
      textColor = CrickifyColors.ropeLight;
    }

    return GestureDetector(
      onTap: (isDisabled || isBlocked) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
          color: bgColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "Shot" or "Yorker" label above the number
            Text(
              isBlocked ? 'Yorker' : 'Shot',
              style: CrickifyTextStyles.meta.copyWith(
                color: isBlocked
                    ? const Color(0xFFFFC2AD)
                    : CrickifyColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            // The large number
            Text(
              '$number',
              style: CrickifyTextStyles.scoreDisplay.copyWith(
                color: textColor,
                fontSize: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
