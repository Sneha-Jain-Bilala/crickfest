import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/trivia_room.dart'; // For LeaderboardEntry

// The live scoreboard shown in the side panel during IPL Trivia.
// Lists players ranked by score with their position number.
class LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries; // Sorted list from the server

  const LeaderboardList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return _PanelBlock(
      title: 'Scoreboard',
      badge: 'Live',
      child: entries.isEmpty
          // Show a placeholder when the game hasn't started yet
          ? Text(
              'Scoreboard populates once the game starts.',
              style: CrickifyTextStyles.bodyMuted.copyWith(fontSize: 13),
            )
          : Column(
              children: entries.map((entry) => _LeaderboardRow(entry: entry)).toList(),
            ),
    );
  }
}

// A single row in the leaderboard
class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0AFFF7DF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Rank number
          Text(
            '${entry.rank}',
            style: CrickifyTextStyles.meta.copyWith(
              color: CrickifyColors.ropeLight,
            ),
          ),
          const SizedBox(width: 12),
          // Player name
          Expanded(
            child: Text(entry.name, style: CrickifyTextStyles.button.copyWith(
              color: CrickifyColors.sight,
            )),
          ),
          // Score
          Text('${entry.score}', style: CrickifyTextStyles.button.copyWith(
            color: CrickifyColors.ropeLight,
          )),
        ],
      ),
    );
  }
}

// Reusable panel block with a title and optional badge — used across side panels
class _PanelBlock extends StatelessWidget {
  final String title;
  final String badge;
  final Widget child;

  const _PanelBlock({
    required this.title,
    required this.badge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CrickifyColors.line, width: 1),
        color: const Color(0x0BFFF7DF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with badge on the right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: CrickifyTextStyles.button.copyWith(
                color: CrickifyColors.sight,
              )),
              Text(badge, style: CrickifyTextStyles.eyebrow),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
