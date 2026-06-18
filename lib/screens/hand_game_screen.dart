import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/hand_room.dart';
import '../models/hand_round.dart';
import '../models/commentary_line.dart';
import '../models/active_effects.dart';
import '../models/player.dart';
import '../widgets/broadcast_header.dart';
import '../widgets/hand_player_card.dart';
import '../widgets/shot_button.dart';
import '../widgets/power_card_button.dart';
import '../widgets/commentary_feed.dart';
import '../widgets/connection_badge.dart';

// The Hand Cricket game screen.
// Shows two player score cards, 1-6 shot buttons, and the round reveal.
//
// In Milestone 6 this will receive a real HandRoom from Firebase.
// For now all data is hardcoded dummy data.
class HandGameScreen extends StatelessWidget {
  const HandGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Dummy data (replaced in Milestone 6 with real Firebase stream) ──────
    final dummyPlayers = [
      const Player(id: 'p1', name: 'Sneha', score: 14, isBatter: true, isHost: true),
      const Player(id: 'p2', name: 'Aryan', score: 0, isBowler: true),
    ];

    final dummyRoom = HandRoom(
      roomCode: 'XY99',
      hostId: 'p1',
      status: HandRoomStatus.playing,
      players: dummyPlayers,
      innings: 1,
      batterId: 'p1',
      bowlerId: 'p2',
      activeEffects: ActiveEffects.none,
    );

    // Dummy round result to show how the reveal looks
    const dummyRound = HandRound(
      innings: 1,
      batterName: 'Sneha',
      bowlerName: 'Aryan',
      batterChoice: 4,
      bowlerChoice: 2,
      runs: 4,
      wicket: false,
      batterScore: 14,
    );

    // My player ID (hardcoded for the static demo)
    const myId = 'p1';
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── App bar row ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hand Cricket',
                          style: CrickifyTextStyles.sectionHeading),
                      const ConnectionBadge(isConnected: true),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Broadcast header ──────────────────────────────────────
                  BroadcastHeader(
                    roomCode: dummyRoom.roomCode,
                    status: dummyRoom.status.name,
                    primaryLabel: 'Innings',
                    primaryValue: '${dummyRoom.innings}',
                    secondaryLabel: 'Chase',
                    secondaryValue: dummyRoom.target != null
                        ? 'Target ${dummyRoom.target}'
                        : 'Set the target',
                    accentLabel: 'Your role',
                    accentValue: 'On strike',
                  ),
                  const SizedBox(height: 16),

                  // ── Two player score cards ────────────────────────────────
                  Row(
                    children: dummyRoom.players
                        .map(
                          (p) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: p == dummyRoom.players.first ? 8 : 0,
                              ),
                              child: HandPlayerCard(
                                name: p.name,
                                score: p.score,
                                isBatter: p.isBatter,
                                isBowler: p.isBowler,
                                isHost: p.isHost,
                                isMe: p.id == myId,
                                hasChosen: p.hasChosen,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Context bar (role / target / locked) ─────────────────
                  Row(
                    children: [
                      _ContextCell(text: 'On strike'),
                      const SizedBox(width: 8),
                      _ContextCell(
                        text: 'Set the target',
                        isAccent: true,
                      ),
                      const SizedBox(width: 8),
                      _ContextCell(text: '${dummyRoom.choicesLocked}/2 locked'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Shot selection panel ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: CrickifyDecorations.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shot selection',
                                style: CrickifyTextStyles.button.copyWith(
                                    color: CrickifyColors.sight)),
                            Text('Pick your shot from 1 to 6.',
                                style: CrickifyTextStyles.meta),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 6 shot buttons in a row
                        SizedBox(
                          height: 90,
                          child: Row(
                            children: List.generate(6, (i) {
                              final num = i + 1;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                                  child: ShotButton(
                                    number: num,
                                    isSelected: num == 4, // Dummy: 4 is selected
                                    onTap: () {
                                      // TODO (Milestone 6): submitHandChoice(num)
                                      debugPrint('Chose $num');
                                    },
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Round result reveal ───────────────────────────────────
                  _RoundReveal(round: dummyRound),
                  const SizedBox(height: 16),

                  // ── Power cards ───────────────────────────────────────────
                  _SidePanelBlock(
                    title: 'Dugout Boosts',
                    badge: 'One use',
                    child: Column(
                      children: [
                        PowerCardButton(
                          label: 'Free Hit',
                          description:
                              'You cannot get out on the next ball.',
                          onTap: () {},
                        ),
                        const SizedBox(height: 8),
                        PowerCardButton(
                          label: 'Yorker',
                          description:
                              'Block one batter number for the next ball.',
                          isUsed: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Commentary ────────────────────────────────────────────
                  CommentaryFeed(
                    lines: [
                      CommentaryLine(
                          text: 'Sneha calls 4, Aryan calls 2. Runs on the board!',
                          timestamp: 0),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Match rules ───────────────────────────────────────────
                  Container(
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
                            Text('Match Notes',
                                style: CrickifyTextStyles.button
                                    .copyWith(color: CrickifyColors.sight)),
                            Text('1-6', style: CrickifyTextStyles.eyebrow),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Different calls score the batter\'s number.',
                            style: CrickifyTextStyles.bodyMuted
                                .copyWith(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                            'Matching calls mean wicket, unless Free Hit is active.',
                            style: CrickifyTextStyles.bodyMuted
                                .copyWith(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                            'The chase ends on wicket or when the target is reached.',
                            style: CrickifyTextStyles.bodyMuted
                                .copyWith(fontSize: 13)),
                      ],
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

// Shows the result of the last ball — what each player called and what happened
class _RoundReveal extends StatelessWidget {
  final HandRound round;

  const _RoundReveal({required this.round});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CrickifyColors.ropeLight.withValues(alpha: 0.36),
          width: 1,
        ),
        color: const Color(0x14FFF7DF),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Batter's call
              Expanded(
                child: _CallCard(
                    label: '${round.batterName} called',
                    value: '${round.batterChoice}'),
              ),
              const SizedBox(width: 12),
              // Bowler's call
              Expanded(
                child: _CallCard(
                    label: '${round.bowlerName} called',
                    value: '${round.bowlerChoice}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Result text
          Text(
            round.wicket
                ? 'Wicket. The whole stand is on its feet.'
                : '${round.runs} run${round.runs == 1 ? '' : 's'} tucked into the scorebook.',
            style: CrickifyTextStyles.button.copyWith(
              color: CrickifyColors.cream,
            ),
          ),
          if (round.freeHitSaved) ...[
            const SizedBox(height: 4),
            Text(
              'Free Hit saves the batter. Proper box-office chaos.',
              style: CrickifyTextStyles.bodyMuted.copyWith(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// Small call card inside the round reveal
class _CallCard extends StatelessWidget {
  final String label;
  final String value;

  const _CallCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x14FFF7DF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CrickifyTextStyles.meta),
          const SizedBox(height: 4),
          Text(value, style: CrickifyTextStyles.scoreDisplay.copyWith(fontSize: 36)),
        ],
      ),
    );
  }
}

// Context info cell (role / target / locked)
class _ContextCell extends StatelessWidget {
  final String text;
  final bool isAccent;

  const _ContextCell({required this.text, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CrickifyColors.line),
          color: const Color(0x0AFFF7DF),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: CrickifyTextStyles.button.copyWith(
            color: isAccent ? CrickifyColors.ropeLight : CrickifyColors.cream,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// Reusable side panel block
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
              Text(title, style: CrickifyTextStyles.button
                  .copyWith(color: CrickifyColors.sight)),
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
