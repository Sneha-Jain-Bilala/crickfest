import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// A one-use special ability button shown in the "Dugout Boosts" panel.
// Once used, the button is greyed out and disabled.
class PowerCardButton extends StatelessWidget {
  final String label;        // e.g. "Review" or "Double Runs"
  final String description;  // e.g. "Hide one wrong option for this question."
  final bool isUsed;         // Has this card already been used?
  final bool isActive;       // Is the effect currently active?
  final bool isDisabled;     // Can it be tapped right now?
  final VoidCallback? onTap; // What to do when tapped

  const PowerCardButton({
    super.key,
    required this.label,
    required this.description,
    this.isUsed = false,
    this.isActive = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = !isUsed && !isDisabled;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isUsed ? 0.4 : 1.0, // Fade out when used
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? CrickifyColors.ropeLight.withValues(alpha: 0.6)
                  : CrickifyColors.line,
              width: isActive ? 1.5 : 1,
            ),
            color: isActive
                ? CrickifyColors.ropeLight.withValues(alpha: 0.08)
                : const Color(0x0AFFF7DF),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: CrickifyTextStyles.button.copyWith(
                color: CrickifyColors.sight,
              )),
              const SizedBox(height: 4),
              Text(description, style: CrickifyTextStyles.meta),
            ],
          ),
        ),
      ),
    );
  }
}
