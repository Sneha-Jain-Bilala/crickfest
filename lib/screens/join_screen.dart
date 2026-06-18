import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_badge.dart';
import '../widgets/mode_tab.dart';
import '../widgets/toast_banner.dart';

// The lobby screen where players enter their name and room code to join a game.
// Shows mode selection tabs (IPL Trivia / Hand Cricket) and a join form.
//
// In Milestone 5 this will be wired to FirebaseService.
// For now all data is local state (dummy).
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  // Which game mode is currently selected
  String _selectedMode = 'trivia';

  // Text controllers to read what the user types
  final _nameController = TextEditingController();
  final _roomCodeController = TextEditingController();

  // Error message to show in the toast (empty = no toast)
  String _error = '';

  @override
  void dispose() {
    // Always clean up controllers to avoid memory leaks
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  // Called when the user submits the join form
  void _onJoin() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a display name.');
      return;
    }
    // TODO (Milestone 5): call FirebaseService.joinRoom(name, roomCode, mode)
    setState(() => _error = '');
    debugPrint('Joining as "$name" in mode "$_selectedMode"');
  }

  @override
  Widget build(BuildContext context) {
    final isHandMode = _selectedMode == 'hand';

    return Scaffold(
      body: Stack(
        children: [
          // ── Pitch gradient background ─────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B2317), CrickifyColors.pitchDeep],
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: title + connection badge
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
                      const ConnectionBadge(isConnected: true),
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
                        // Mode description
                        Text(
                          isHandMode
                              ? 'BACKYARD RIVALRY'
                              : 'QUIZ POWERPLAY',
                          style: CrickifyTextStyles.eyebrow,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isHandMode
                              ? 'Call your shot in the hand-cricket cauldron'
                              : 'Take guard for an IPL trivia powerplay',
                          style: CrickifyTextStyles.sectionHeading,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isHandMode
                              ? 'Two players, secret numbers, one nerve test.'
                              : 'Host a room, share the code, and race through IPL questions.',
                          style: CrickifyTextStyles.bodyMuted,
                        ),
                        const SizedBox(height: 20),

                        // Mode tabs
                        ModeTab(
                          selectedMode: _selectedMode,
                          onSelect: (mode) =>
                              setState(() => _selectedMode = mode),
                        ),
                        const SizedBox(height: 20),

                        // Player name input
                        _InputField(
                          label: 'Player name',
                          hint: 'Thala Fan',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 14),

                        // Room code input
                        _InputField(
                          label: 'Room code',
                          hint: 'Blank creates a new room',
                          controller: _roomCodeController,
                        ),
                        const SizedBox(height: 20),

                        // Submit button
                        ElevatedButton(
                          onPressed: _onJoin,
                          child: Text(
                            isHandMode ? 'Enter the crease' : 'Walk out to bat',
                          ),
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
                      children: isHandMode
                          ? [
                              _RuleStat(value: '2', label: 'players in the middle'),
                              _RuleStat(value: '1–6', label: 'secret shot calls'),
                              _RuleStat(value: 'OUT', label: 'when numbers match'),
                            ]
                          : [
                              _RuleStat(value: '10', label: 'questions in the innings'),
                              _RuleStat(value: '10s', label: 'shot clock per ball'),
                              _RuleStat(value: '+5', label: 'speed bonus per second'),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Error toast ───────────────────────────────────────────────────
          if (_error.isNotEmpty) ToastBanner(message: _error),
        ],
      ),
    );
  }
}

// A simple labelled text input field
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
        Text(label, style: CrickifyTextStyles.button.copyWith(
          color: CrickifyColors.cream,
        )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: CrickifyTextStyles.body.copyWith(color: CrickifyColors.sight),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// A stat row in the rules strip (big value + small label below)
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
        border: Border.all(color: CrickifyColors.ropeLight.withValues(alpha: 0.24)),
        gradient: const LinearGradient(
          colors: [Color(0x1FF1C85A), Color(0x0AFFF7DF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: CrickifyTextStyles.scoreDisplay.copyWith(fontSize: 36)),
          const SizedBox(height: 6),
          Text(label, style: CrickifyTextStyles.bodyMuted.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
