import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Shows a green "Live feed" pill when connected, red "Off air" when not.
// Used in the top-right corner of every screen.
class ConnectionBadge extends StatelessWidget {
  final bool isConnected; // Pass true when Firebase is connected

  const ConnectionBadge({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    // Pick label and dot colour based on connection state
    final label = isConnected ? 'Live feed' : 'Off air';
    final dotColor = isConnected ? CrickifyColors.good : CrickifyColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xD0101812),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CrickifyColors.line, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Shrink-wrap to content
        children: [
          // Coloured dot indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Label text
          Text(label, style: CrickifyTextStyles.button.copyWith(
            color: CrickifyColors.sight,
            fontSize: 13,
          )),
        ],
      ),
    );
  }
}
