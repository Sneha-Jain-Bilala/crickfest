import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/trivia_room.dart';
import '../models/question.dart';
import '../models/commentary_line.dart';
import '../widgets/broadcast_header.dart';
import '../widgets/timer_bar.dart';
import '../widgets/option_button.dart';
import '../widgets/power_card_button.dart';
import '../widgets/leaderboard_list.dart';
import '../widgets/commentary_feed.dart';
import '../widgets/connection_badge.dart';
import '../widgets/toast_banner.dart';

// The main IPL Trivia game screen.
// Shows the question, timer, options, side panel with scoreboard & commentary.
//
// In Milestone 5 this will receive a real TriviaRoom from Firebase.
// For now all data is hardcoded dummy data.
class TriviaGameScreen extends StatelessWidget {
  const TriviaGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Dummy data (replaced in Milestone 5 with real Firebase stream) ──────
    const dummyRoom = TriviaRoom(
      roomCode: 'AB12',
      hostId: 'player1',
      status: TriviaRoomStatus.answering,
      players: [],
      questionIndex: 3,
      totalQuestions: 10,
      timeLeft: 7,
      leaderboard: [
        LeaderboardEntry(rank: 1, name: 'Sneha', score: 120),
        LeaderboardEntry(rank: 2, name: 'Aryan', score: 80),
        LeaderboardEntry(rank: 3, name: 'Priya', score: 60),
      ],
      commentary: [
        CommentaryLine(text: 'What a question! The crowd is on its feet.', timestamp: 0),
        CommentaryLine(text: 'Three players answered correctly. Speed bonus in play!', timestamp: 1),
      ],
    );

    const dummyQuestion = Question(
      id: 'q1',
      question: 'Which team won the IPL 2023 season?',
      options: ['Mumbai Indians', 'Chennai Super Kings', 'Gujarat Titans', 'Rajasthan Royals'],
      correctIndex: 1,
    );
    // ─────────────────────────────────────────────────────────────────────────

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B2317), CrickifyColors.pitchDeep],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── App bar row ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('IPL Trivia', style: CrickifyTextStyles.sectionHeading),
                      const ConnectionBadge(isConnected: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Scrollable game content ─────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Broadcast header (room info strip)
                        BroadcastHeader(
                          roomCode: dummyRoom.roomCode,
                          status: dummyRoom.status.name,
                          primaryLabel: 'Over',
                          primaryValue:
                              '${dummyRoom.questionIndex}/${dummyRoom.totalQuestions}',
                          secondaryLabel: 'Shot clock',
                          secondaryValue: '${dummyRoom.timeLeft}s',
                          accentLabel: 'Format',
                          accentValue: 'IPL quiz',
                        ),
                        const SizedBox(height: 16),

                        // Timer bar
                        TimerBar(timeLeft: dummyRoom.timeLeft),
                        const SizedBox(height: 20),

                        // ── Question card ───────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: CrickifyDecorations.card,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SEED TRIVIA BANK',
                                  style: CrickifyTextStyles.eyebrow),
                              const SizedBox(height: 8),
                              Text(
                                dummyQuestion.question,
                                style: CrickifyTextStyles.sectionHeading,
                              ),
                              const SizedBox(height: 20),

                              // Four answer option buttons
                              ...List.generate(
                                dummyQuestion.options.length,
                                (i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: OptionButton(
                                    index: i,
                                    text: dummyQuestion.options[i],
                                    isSelected: i == 1, // Dummy: B is selected
                                    onTap: () {
                                      // TODO (Milestone 5): submitAnswer(i)
                                      debugPrint('Tapped option $i');
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Power cards ─────────────────────────────────────
                        _SidePanelBlock(
                          title: 'Dugout Boosts',
                          badge: 'One use',
                          child: Column(
                            children: [
                              PowerCardButton(
                                label: 'Review',
                                description:
                                    'Hide one wrong option for this question.',
                                onTap: () {},
                              ),
                              const SizedBox(height: 8),
                              PowerCardButton(
                                label: 'Double Runs',
                                description:
                                    'Your next correct answer scores double.',
                                isUsed: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Leaderboard ─────────────────────────────────────
                        LeaderboardList(entries: dummyRoom.leaderboard),
                        const SizedBox(height: 16),

                        // ── Commentary ──────────────────────────────────────
                        CommentaryFeed(lines: dummyRoom.commentary),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error toast (hidden when empty)
          const ToastBanner(message: ''), // Wire in Milestone 5
        ],
      ),
    );
  }
}

// Reusable container used for side panel blocks
class _SidePanelBlock extends StatelessWidget {
  final String title;
  final String badge;
  final Widget child;

  const _SidePanelBlock({
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
        border: Border.all(color: CrickifyColors.line),
        color: const Color(0x0BFFF7DF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: CrickifyTextStyles.button.copyWith(
                  color: CrickifyColors.sight)),
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
