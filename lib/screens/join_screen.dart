import 'dart:math'; // For generating a temporary player ID
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../widgets/connection_badge.dart';
import '../widgets/mode_tab.dart';
import '../widgets/toast_banner.dart';

// The lobby screen where players enter their name and room code to join a game.
// Tapping the CTA button either creates a new room (no code) or joins one.
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final FirebaseService _firebase = FirebaseService();

  // Selected game mode
  String _selectedMode = 'trivia';

  // Form controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  // UI state
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // Generate a temporary player ID (UUID-style).
  // In a production app you would use Firebase Auth.
  String _generatePlayerId() {
    final rand = Random();
    return List.generate(12, (_) => rand.nextInt(16).toRadixString(16)).join();
  }

  // Called when the player taps the golden CTA button
  Future<void> _onJoin() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a display name first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final playerId = _generatePlayerId();
      final roomCode = _codeController.text.trim().toUpperCase();
      final isTrivia = _selectedMode == 'trivia';

      String finalCode;

      if (roomCode.isEmpty) {
        // No code → create a brand-new room
        if (isTrivia) {
          finalCode = await _firebase.createTriviaRoom(
            playerId: playerId,
            playerName: name,
          );
        } else {
          finalCode = await _firebase.createHandRoom(
            playerId: playerId,
            playerName: name,
          );
        }
      } else {
        // Code given → join an existing room
        if (isTrivia) {
          finalCode = await _firebase.joinTriviaRoom(
            roomCode: roomCode,
            playerId: playerId,
            playerName: name,
          );
        } else {
          finalCode = await _firebase.joinHandRoom(
            roomCode: roomCode,
            playerId: playerId,
            playerName: name,
          );
        }
      }

      // Navigate to the right game screen and pass the room info along
      if (mounted) {
        Navigator.pushNamed(
          context,
          isTrivia ? '/trivia' : '/hand',
          arguments: {
            'roomCode': finalCode,
            'playerId': playerId,
            'playerName': name,
          },
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHand = _selectedMode == 'hand';

    return Scaffold(
      body: Stack(
        children: [
          // Pitch gradient background
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ───────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STADIUM CONTROL ROOM',
                                style: CrickifyTextStyles.eyebrow),
                            const SizedBox(height: 6),
                            Text('Cricket\nArcade',
                                style: CrickifyTextStyles.hero),
                            const SizedBox(height: 10),
                            Text(
                              'Floodlights on. Dugout loud. Every tap counts.',
                              style: CrickifyTextStyles.bodyMuted,
                            ),
                          ],
                        ),
                      ),
                      // Live connection indicator
                      StreamBuilder<bool>(
                        stream: _firebase.connectionStream(),
                        builder: (_, snap) => ConnectionBadge(
                          isConnected: snap.data ?? false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Join card ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: CrickifyDecorations.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHand ? 'BACKYARD RIVALRY' : 'QUIZ POWERPLAY',
                          style: CrickifyTextStyles.eyebrow,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isHand
                              ? 'Call your shot in the hand-cricket cauldron'
                              : 'Take guard for an IPL trivia powerplay',
                          style: CrickifyTextStyles.sectionHeading,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isHand
                              ? 'Two players, secret numbers, one nerve test.'
                              : 'Host a room, share the code, race through IPL questions.',
                          style: CrickifyTextStyles.bodyMuted,
                        ),
                        const SizedBox(height: 20),

                        // Mode tabs
                        ModeTab(
                          selectedMode: _selectedMode,
                          onSelect: (m) => setState(() => _selectedMode = m),
                        ),
                        const SizedBox(height: 20),

                        // Player name
                        _InputField(
                          label: 'Player name',
                          hint: 'Thala Fan',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 14),

                        // Room code (optional — blank = create new)
                        _InputField(
                          label: 'Room code',
                          hint: 'Blank = create a new room',
                          controller: _codeController,
                        ),
                        const SizedBox(height: 20),

                        // CTA button — shows spinner while loading
                        ElevatedButton(
                          onPressed: _isLoading ? null : _onJoin,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF17210F),
                                  ),
                                )
                              : Text(isHand
                                  ? 'Enter the crease'
                                  : 'Walk out to bat'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Rules strip ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: CrickifyDecorations.card,
                    child: Column(
                      children: isHand
                          ? [
                              _RuleStat(value: '2', label: 'players in the middle'),
                              _RuleStat(value: '1–6', label: 'secret shot calls'),
                              _RuleStat(value: 'OUT', label: 'when numbers match'),
                            ]
                          : [
                              _RuleStat(value: '10', label: 'questions in the innings'),
                              _RuleStat(value: '10s', label: 'shot clock per ball'),
                              _RuleStat(value: '+1', label: 'speed bonus per second'),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Error toast
          if (_error.isNotEmpty) ToastBanner(message: _error),
        ],
      ),
    );
  }
}

// Labelled text field
class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: CrickifyTextStyles.button.copyWith(
                color: CrickifyColors.cream)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style:
              CrickifyTextStyles.body.copyWith(color: CrickifyColors.sight),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// A big stat in the rules strip
class _RuleStat extends StatelessWidget {
  final String value;
  final String label;

  const _RuleStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: CrickifyColors.ropeLight.withValues(alpha: 0.24)),
        gradient: const LinearGradient(
          colors: [Color(0x1FF1C85A), Color(0x0AFFF7DF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: CrickifyTextStyles.scoreDisplay
                  .copyWith(fontSize: 36)),
          const SizedBox(height: 6),
          Text(label,
              style: CrickifyTextStyles.bodyMuted.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
