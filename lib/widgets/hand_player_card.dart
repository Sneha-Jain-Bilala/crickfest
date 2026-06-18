import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// A score card for one player in the Hand Cricket scoreboard.
// Shows their role (batting/bowling), name, and current score.
// The card belonging to "me" (the current user) gets a golden border.
class HandPlayerCard extends StatelessWidget {
  final String name;    // Player's display name
  final int score;      // Their current runs scored
  final bool isBatter;  // Are they currently batting?
  final bool isBowler;  // Are they currently bowling?
  final bool isHost;    // Are they the room host / captain?
  final bool isMe;      // Is this card for the current user?
  final bool hasChosen; // Have they locked in a number this ball?

  const HandPlayerCard({
    super.key,
    required this.name,
    required this.score,
    this.isBatter = false,
    this.isBowler = false,
    this.isHost = false,
    this.isMe = false,
    this.hasChosen = false,
  });

  // Human-readable role label
  String get _roleLabel {
    if (isBatter) return 'ON STRIKE';
    if (isBowler) return 'BOWLING';
    return 'DUGOUT';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          // Gold border for "my" card, subtle for opponent
          color: isMe
              ? CrickifyColors.ropeLight.withValues(alpha: 0.64)
              : CrickifyColors.line,
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMe
              ? [
                  CrickifyColors.ropeLight.withValues(alpha: 0.16),
                  CrickifyColors.grass.withValues(alpha: 0.10),
                ]
              : [
                  CrickifyColors.grass.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role label (e.g. "ON STRIKE")
          Text(_roleLabel, style: CrickifyTextStyles.eyebrow),
          const SizedBox(height: 8),
          // Player name
          Text(
            isHost ? '$name — Captain' : name,
            style: CrickifyTextStyles.sectionHeading.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          // Big score number
          Text('$score', style: CrickifyTextStyles.scoreDisplay),
          const SizedBox(height: 10),
          // Status: locked in or still reading the field
          Text(
            hasChosen ? 'Call locked' : 'Reading the field',
            style: CrickifyTextStyles.bodyMuted.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
