import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/commentary_line.dart';

// Shows AI commentary lines in a "From the Box" panel.
// Displays up to 8 most recent lines, newest first.
class CommentaryFeed extends StatelessWidget {
  final List<CommentaryLine> lines; // Commentary lines from the server

  const CommentaryFeed({super.key, required this.lines});

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('From the Box', style: CrickifyTextStyles.button.copyWith(
                color: CrickifyColors.sight,
              )),
              Text('Ball by ball', style: CrickifyTextStyles.eyebrow),
            ],
          ),
          const SizedBox(height: 12),
          // Commentary lines or placeholder
          if (lines.isEmpty)
            Text(
              'The commentator is warming up the mic.',
              style: CrickifyTextStyles.bodyMuted.copyWith(fontSize: 13),
            )
          else
            // Show each line with a bullet/icon based on the mode
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.mode == 'trivia' ? '🎙️' : '🏏',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line.text,
                        style: CrickifyTextStyles.bodyMuted.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
