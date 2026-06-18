import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Two-button tab row to switch between "IPL Trivia" and "Hand Cricket".
// The selected mode is highlighted with a golden border and background.
class ModeTab extends StatelessWidget {
  final String selectedMode;            // Either "trivia" or "hand"
  final void Function(String) onSelect; // Called when the user taps a tab

  const ModeTab({
    super.key,
    required this.selectedMode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // IPL Trivia tab
        Expanded(
          child: _TabButton(
            title: 'IPL Trivia',
            subtitle: 'Rapid-fire quiz chase',
            isActive: selectedMode == 'trivia',
            onTap: () => onSelect('trivia'),
          ),
        ),
        const SizedBox(width: 10),
        // Hand Cricket tab
        Expanded(
          child: _TabButton(
            title: 'Hand Cricket',
            subtitle: 'One-on-one mind game',
            isActive: selectedMode == 'hand',
            onTap: () => onSelect('hand'),
          ),
        ),
      ],
    );
  }
}

// Private helper — a single tab button (not exported outside this file)
class _TabButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            // Golden border when active, subtle border when inactive
            color: isActive
                ? CrickifyColors.ropeLight.withValues(alpha: 0.72)
                : CrickifyColors.line,
            width: 1,
          ),
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x42D8A536), Color(0x23F1C85A)],
                )
              : null,
          color: isActive ? null : const Color(0x0FFFF7DF),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: CrickifyTextStyles.button.copyWith(
              color: CrickifyColors.sight,
            )),
            const SizedBox(height: 4),
            Text(subtitle, style: CrickifyTextStyles.meta),
          ],
        ),
      ),
    );
  }
}
