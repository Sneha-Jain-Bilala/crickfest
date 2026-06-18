import 'dart:async'; // For Timer (shot clock)
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/trivia_room.dart';
import '../models/question.dart';
import '../services/firebase_service.dart';
import '../services/trivia_service.dart';
import '../widgets/broadcast_header.dart';
import '../widgets/timer_bar.dart';
import '../widgets/option_button.dart';
import '../widgets/power_card_button.dart';
import '../widgets/leaderboard_list.dart';
import '../widgets/commentary_feed.dart';
import '../widgets/connection_badge.dart';
import '../widgets/toast_banner.dart';

// The live IPL Trivia game screen.
// Listens to Firebase in real time and reacts to every state change.
//
// Pass roomCode and playerId when navigating here, e.g.:
//   Navigator.pushNamed(context, '/trivia',
//     arguments: {'roomCode': 'AB12', 'playerId': 'uuid', 'playerName': 'Sneha'});
class TriviaGameScreen extends StatefulWidget {
  const TriviaGameScreen({super.key});

  @override
  State<TriviaGameScreen> createState() => _TriviaGameScreenState();
}

class _TriviaGameScreenState extends State<TriviaGameScreen> {
  // Services
  final FirebaseService _firebase = FirebaseService();
  final TriviaService _trivia = TriviaService();

  // Route arguments (set in initState)
  String _roomCode = '';
  String _playerId = '';
  String _playerName = '';

  // Real-time room state from Firebase
  TriviaRoom? _room;

  // Which answer option this player selected this question (-1 = none yet)
  int _selectedIndex = -1;

  // Error message to show in the toast
  String _error = '';

  // Subscription to the Firebase stream
  StreamSubscription<TriviaRoom>? _roomSub;

  // Shot clock timer (runs on the host's device)
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    // Arguments come in the next frame, so use addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Extract the route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _roomCode = (args?['roomCode'] as String?) ?? '';
    _playerId = (args?['playerId'] as String?) ?? '';
    _playerName = (args?['playerName'] as String?) ?? 'Player';

    if (_roomCode.isEmpty) {
      setState(() => _error = 'No room code provided.');
      return;
    }

    // Subscribe to real-time room updates
    _roomSub = _firebase.triviaRoomStream(_roomCode).listen(
      (room) {
        if (!mounted) return;
        setState(() => _room = room);

        // Reset selection whenever a new question arrives
        if (room.status == TriviaRoomStatus.answering && _selectedIndex != -1) {
          if (_room?.questionIndex != room.questionIndex) {
            _selectedIndex = -1;
          }
        }

        // If I'm the host, manage the shot clock
        _manageHostClock(room);
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _error = e.toString());
      },
    );

    // Load trivia questions (host will start the game)
    if (!_trivia.isLoaded) {
      await _trivia.loadQuestions();
    }
  }

  // The host's device drives the shot clock.
  // When the timer reaches 0, automatically reveal the answer.
  void _manageHostClock(TriviaRoom room) {
    final isHost = room.hostId == _playerId;
    final isAnswering = room.status == TriviaRoomStatus.answering;

    if (isHost && isAnswering && room.timeLeft > 0) {
      // Start clock if not already running
      _clockTimer ??= Timer.periodic(const Duration(seconds: 1), (_) async {
        await _firebase.tickTriviaTimer(roomCode: _roomCode);
        // Check if time has run out
        final snap = _room;
        if (snap != null && snap.timeLeft <= 1) {
          _stopClock();
          await _firebase.revealTriviaAnswer(roomCode: _roomCode);
        }
      });
    } else if (room.status == TriviaRoomStatus.revealing) {
      _stopClock();
    }
  }

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  @override
  void dispose() {
    _stopClock();
    _roomSub?.cancel();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  // Start game (host only)
  Future<void> _startGame() async {
    final questions = _trivia.pickQuestions(count: 10);
    final questionMaps = questions.map((q) => q.toJson()).toList();
    await _firebase.startTriviaGame(
      roomCode: _roomCode,
      questions: questionMaps,
    );
  }

  // Submit an answer
  Future<void> _submitAnswer(int index) async {
    if (_selectedIndex != -1) return; // Already answered
    if (_room?.status != TriviaRoomStatus.answering) return;

    setState(() => _selectedIndex = index);

    final question = _room?.currentQuestion;
    if (question == null) return;

    final isCorrect = index == question.correctIndex;

    // Check if Double Runs card is active for this player
    final me = _room?.players.where((p) => p.id == _playerId).firstOrNull;
    final doubleActive = me?.powerCards
            .where((c) => c.id == 'double_runs' && c.active)
            .isNotEmpty ??
        false;

    final points = isCorrect
        ? _trivia.calculateScore(
            timeLeft: _room?.timeLeft ?? 0,
            doubleRuns: doubleActive,
          )
        : _trivia.wrongAnswerScore();

    await _firebase.submitTriviaAnswer(
      roomCode: _roomCode,
      playerId: _playerId,
      pointsEarned: points,
    );
  }

  // Host presses "Next question" during the reveal phase
  Future<void> _nextQuestion() async {
    setState(() => _selectedIndex = -1);
    await _firebase.advanceTriviaQuestion(roomCode: _roomCode);
  }

  // Use the Review power card
  Future<void> _useReview() async {
    final question = _room?.currentQuestion;
    if (question == null) return;

    // Find the first option index that is NOT the correct answer
    int wrongIndex = -1;
    for (int i = 0; i < question.options.length; i++) {
      if (i != question.correctIndex) {
        wrongIndex = i;
        break;
      }
    }
    if (wrongIndex == -1) return;

    await _firebase.useReviewCard(
      roomCode: _roomCode,
      playerId: _playerId,
      hiddenOptionIndex: wrongIndex,
    );
  }

  // Use the Double Runs power card
  Future<void> _useDoubleRuns() async {
    await _firebase.useDoubleRunsCard(
      roomCode: _roomCode,
      playerId: _playerId,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final isHost = room?.hostId == _playerId;
    final question = room?.currentQuestion;
    final me = room?.players.where((p) => p.id == _playerId).firstOrNull;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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
                // App bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('IPL Trivia',
                          style: CrickifyTextStyles.sectionHeading),
                      // Real-time connection badge
                      StreamBuilder<bool>(
                        stream: _firebase.connectionStream(),
                        builder: (_, snap) => ConnectionBadge(
                          isConnected: snap.data ?? false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;

                      // Left side: Game Flow (Question, Timer, Header, Lobby)
                      final leftContent = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (room == null || room.status == TriviaRoomStatus.waiting)
                            _buildWaitingLobby(room, isHost),

                          if (room != null && room.status != TriviaRoomStatus.waiting) ...[
                            BroadcastHeader(
                              roomCode: room.roomCode,
                              status: room.status.name,
                              primaryLabel: 'Over',
                              primaryValue:
                                  '${room.questionIndex + 1}/${room.totalQuestions}',
                              secondaryLabel: 'Shot clock',
                              secondaryValue: '${room.timeLeft}s',
                              accentLabel: 'Format',
                              accentValue: 'IPL quiz',
                            ),
                            const SizedBox(height: 16),

                            if (room.status == TriviaRoomStatus.answering)
                              TimerBar(timeLeft: room.timeLeft),
                            const SizedBox(height: 20),

                            if (question != null)
                              _buildQuestion(question, room, me),
                            const SizedBox(height: 16),

                            if (isHost && room.status == TriviaRoomStatus.revealing)
                              ElevatedButton(
                                onPressed: _nextQuestion,
                                child: Text(
                                  room.questionIndex + 1 >= room.totalQuestions
                                      ? 'Show Final Scoreboard'
                                      : 'Next question',
                                ),
                              ),

                            if (room.status == TriviaRoomStatus.finished)
                              _buildFinishedCard(room),
                            const SizedBox(height: 24),
                          ],
                        ],
                      );

                      // Right side: Meta Data (Power Cards, Leaderboard, Commentary)
                      final rightContent = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (room != null && room.status != TriviaRoomStatus.waiting) ...[
                            if (me != null && me.powerCards.isNotEmpty) ...[
                              _buildPowerCards(me.powerCards, room),
                              const SizedBox(height: 16),
                            ],
                            // Live Players List
                            _buildPlayersList(room),
                            const SizedBox(height: 16),
                            
                            // Leaderboard (only populated during revealing/finished)
                            if (room.leaderboard.isNotEmpty) ...[
                              LeaderboardList(entries: room.leaderboard),
                              const SizedBox(height: 16),
                            ],

                            CommentaryFeed(lines: room.commentary),
                            const SizedBox(height: 24),
                          ],
                        ],
                      );

                      if (constraints.maxWidth > 700) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 13,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(20, 0, 10, 20),
                                child: leftContent,
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(10, 0, 20, 20),
                                child: rightContent,
                              ),
                            ),
                          ],
                        );
                      }

                      // Mobile / narrow layout: stack everything vertically
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            leftContent,
                            rightContent,
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Error toast
          if (_error.isNotEmpty) ToastBanner(message: _error),
        ],
      ),
    );
  }

  // ── Sub-builders ─────────────────────────────────────────────────────────

  Widget _buildWaitingLobby(TriviaRoom? room, bool isHost) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(24),
      decoration: CrickifyDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LOBBY', style: CrickifyTextStyles.eyebrow),
          const SizedBox(height: 8),
          Text('Waiting for players', style: CrickifyTextStyles.sectionHeading),
          const SizedBox(height: 8),
          if (room != null) ...[
            Text('Room code: ${room.roomCode}',
                style: CrickifyTextStyles.body.copyWith(
                    color: CrickifyColors.ropeLight)),
            const SizedBox(height: 8),
            Text('${room.players.length} player(s) in the dugout',
                style: CrickifyTextStyles.bodyMuted),
            // List players
            ...room.players.map((p) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    p.isHost ? '${p.name} — Captain' : p.name,
                    style: CrickifyTextStyles.button.copyWith(
                        color: CrickifyColors.sight),
                  ),
                )),
          ],
          const SizedBox(height: 20),
          if (isHost)
            ElevatedButton(
              onPressed: _startGame,
              child: const Text('Start the powerplay'),
            )
          else
            Text('Waiting for the captain to start…',
                style: CrickifyTextStyles.bodyMuted),
        ],
      ),
    );
  }

  Widget _buildQuestion(
      Question question, TriviaRoom room, dynamic me) {
    final isRevealing = room.status == TriviaRoomStatus.revealing;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: CrickifyDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IPL TRIVIA', style: CrickifyTextStyles.eyebrow),
          const SizedBox(height: 8),
          Text(question.question, style: CrickifyTextStyles.sectionHeading),
          const SizedBox(height: 20),

          // Four answer buttons
          ...List.generate(question.options.length, (i) {
            final isHidden = question.hiddenOptionIndexes.contains(i);
            final isSelected = _selectedIndex == i;
            final isCorrect = isRevealing && i == question.correctIndex;
            final isWrong = isRevealing &&
                _selectedIndex == i &&
                i != question.correctIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OptionButton(
                index: i,
                text: question.options[i],
                isSelected: isSelected,
                isCorrect: isCorrect,
                isWrong: isWrong,
                isHidden: isHidden,
                isDisabled: _selectedIndex != -1 || isRevealing,
                onTap: () => _submitAnswer(i),
              ),
            );
          }),

          // "Answered" message when already submitted
          if (_selectedIndex != -1 && !isRevealing)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Answer locked in. Waiting for others…',
                style: CrickifyTextStyles.bodyMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPowerCards(List<dynamic> cards, TriviaRoom room) {
    return _SidePanelBlock(
      title: 'Dugout Boosts',
      badge: 'One use',
      child: Column(
        children: cards.asMap().entries.map((entry) {
          final card = entry.value;
          final id = card.id as String;
          final isAnswering = room.status == TriviaRoomStatus.answering;

          return Padding(
            padding: EdgeInsets.only(bottom: entry.key < cards.length - 1 ? 8 : 0),
            child: PowerCardButton(
              label: card.label,
              description: card.description,
              isUsed: card.used,
              isActive: card.active,
              isDisabled: !isAnswering,
              onTap: () {
                if (id == 'review') _useReview();
                if (id == 'double_runs') _useDoubleRuns();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlayersList(TriviaRoom room) {
    return _SidePanelBlock(
      title: 'Players',
      badge: '${room.players.length}',
      child: Column(
        children: room.players.map((p) {
          final isAnswering = room.status == TriviaRoomStatus.answering;
          final hasAnswered = p.answered;
          String statusText = '';
          Color statusColor = CrickifyColors.muted;

          if (isAnswering) {
            if (hasAnswered) {
              statusText = 'Locked';
              statusColor = CrickifyColors.sight;
            } else {
              statusText = 'Thinking…';
              statusColor = CrickifyColors.ropeLight;
            }
          } else {
            statusText = 'Ready';
            statusColor = CrickifyColors.muted;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p.isHost ? '${p.name} (Host)' : p.name,
                    style: CrickifyTextStyles.bodyMuted.copyWith(
                        color: p.id == _playerId ? CrickifyColors.sight : null),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  statusText,
                  style: CrickifyTextStyles.eyebrow.copyWith(color: statusColor),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFinishedCard(TriviaRoom room) {
    final winner = room.leaderboard.isNotEmpty ? room.leaderboard.first : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: CrickifyDecorations.matchCallout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STUMPS DRAWN', style: CrickifyTextStyles.eyebrow),
          const SizedBox(height: 8),
          Text('Final scoreboard', style: CrickifyTextStyles.sectionHeading),
          if (winner != null) ...[
            const SizedBox(height: 10),
            Text(
              '${winner.name} takes the trophy with ${winner.score} runs!',
              style: CrickifyTextStyles.body.copyWith(
                  color: CrickifyColors.ropeLight),
            ),
          ],
        ],
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
              Text(title,
                  style: CrickifyTextStyles.button
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
