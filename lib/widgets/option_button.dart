import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// One answer option button in the IPL Trivia question area.
// Shows A/B/C/D label on the left and the answer text on the right.
// Visual states: normal → selected (gold) → correct (green) → wrong (red)
class OptionButton extends StatelessWidget {
  final int index;          // 0=A, 1=B, 2=C, 3=D
  final String text;        // The answer text
  final bool isSelected;    // Did this player choose this option?
  final bool isCorrect;     // Is this the correct answer? (shown after reveal)
  final bool isWrong;       // Was this the player's wrong choice?
  final bool isHidden;      // Hidden by "Review" power card
  final bool isDisabled;    // Can't be tapped (already answered or time up)
  final VoidCallback? onTap; // What to do when tapped

  const OptionButton({
    super.key,
    required this.index,
    required this.text,
    this.isSelected = false,
    this.isCorrect = false,
    this.isWrong = false,
    this.isHidden = false,
    this.isDisabled = false,
    this.onTap,
  });

  // Convert index to letter: 0→A, 1→B, 2→C, 3→D
  String get _letter => String.fromCharCode(65 + index);

  @override
  Widget build(BuildContext context) {
    // Pick border colour and background based on the current state
    Color borderColor;
    Color bgColor;

    if (isCorrect) {
      borderColor = CrickifyColors.good.withValues(alpha: 0.72);
      bgColor = CrickifyColors.good.withValues(alpha: 0.12);
    } else if (isWrong || isHidden) {
      borderColor = CrickifyColors.danger.withValues(alpha: 0.48);
      bgColor = CrickifyColors.danger.withValues(alpha: 0.10);
    } else if (isSelected) {
      borderColor = CrickifyColors.ropeLight.withValues(alpha: 0.72);
      bgColor = CrickifyColors.ropeLight.withValues(alpha: 0.12);
    } else {
      borderColor = CrickifyColors.line;
      bgColor = const Color(0x12FFF7DF);
    }

    return GestureDetector(
      onTap: isDisabled || isHidden ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            // Dashed style for hidden/wrong options
            style: (isWrong || isHidden)
                ? BorderStyle.solid
                : BorderStyle.solid,
            width: 1,
          ),
          color: bgColor,
        ),
        child: Row(
          children: [
            // Letter badge (circle with A/B/C/D)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CrickifyColors.ropeLight.withValues(alpha: 0.14),
              ),
              alignment: Alignment.center,
              child: Text(
                _letter,
                style: CrickifyTextStyles.button.copyWith(
                  color: CrickifyColors.ropeLight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Answer text
            Expanded(
              child: Text(
                isHidden ? 'Review removed this line' : text,
                style: CrickifyTextStyles.body.copyWith(
                  color: isHidden
                      ? CrickifyColors.danger.withValues(alpha: 0.7)
                      : CrickifyColors.sight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
