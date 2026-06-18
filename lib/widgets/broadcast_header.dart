import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// The dark scoreboard strip shown at the top of every game screen.
// Shows room code, three stat cells, a status chip, and a copy-code button.
class BroadcastHeader extends StatelessWidget {
  final String roomCode;      // e.g. "AB12"
  final String status;        // e.g. "answering" — shown as a human label
  final String primaryLabel;  // e.g. "Over"
  final String primaryValue;  // e.g. "3/10"
  final String secondaryLabel; // e.g. "Shot clock"
  final String secondaryValue; // e.g. "7s"
  final String accentLabel;   // e.g. "Format"
  final String accentValue;   // e.g. "IPL quiz" — shown in gold

  const BroadcastHeader({
    super.key,
    required this.roomCode,
    required this.status,
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.accentLabel,
    required this.accentValue,
  });

  // Converts the raw status key into a friendly display label
  String _statusLabel(String s) {
    const labels = {
      'waiting': 'At the pavilion',
      'starting': 'Walking out',
      'answering': 'Powerplay live',
      'revealing': 'Third umpire',
      'playing': 'Ball in play',
      'round_reveal': 'Big screen replay',
      'finished': 'Final scoreboard',
    };
    return labels[s] ?? 'Match room';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B120D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CrickifyColors.line, width: 1),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Room code badge (gold gradient)
          _Cell(
            label: 'Room',
            value: roomCode,
            isAccent: false,
            isRoomBadge: true,
          ),
          // Three stat cells
          _Cell(label: primaryLabel, value: primaryValue),
          _Cell(label: secondaryLabel, value: secondaryValue),
          _Cell(label: accentLabel, value: accentValue, isAccent: true),
          // Status chip (gold pill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CrickifyColors.ropeLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel(status),
              style: CrickifyTextStyles.meta.copyWith(
                color: const Color(0xFF17210F),
              ),
            ),
          ),
          // Copy code button
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: roomCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Room code copied!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CrickifyColors.ropeLight.withValues(alpha: 0.42),
                ),
                color: const Color(0x0FFFF7DF),
              ),
              child: Text(
                'Copy code',
                style: CrickifyTextStyles.button.copyWith(
                  color: CrickifyColors.sight,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A single stat cell inside the header (label on top, bold value below)
class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final bool isAccent;    // If true, value text is shown in gold
  final bool isRoomBadge; // If true, cell gets the gold gradient background

  const _Cell({
    required this.label,
    required this.value,
    this.isAccent = false,
    this.isRoomBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isRoomBadge
            ? const LinearGradient(
                colors: [Color(0x40D8A536), Color(0x1A2FB26F)],
              )
            : null,
        color: isRoomBadge ? null : const Color(0x0FFFF7DF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: CrickifyTextStyles.meta),
          const SizedBox(height: 4),
          Text(
            value,
            style: CrickifyTextStyles.button.copyWith(
              color: isAccent ? CrickifyColors.ropeLight : CrickifyColors.sight,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
