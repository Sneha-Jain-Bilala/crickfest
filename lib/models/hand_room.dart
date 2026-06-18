import 'player.dart';
import 'hand_round.dart';
import 'active_effects.dart';
import 'commentary_line.dart';

// All possible states of a Hand Cricket room.
enum HandRoomStatus {
  waiting,      // Waiting for both players to join
  playing,      // Both players are picking their numbers
  roundReveal,  // The result of the last ball is being shown
  finished,     // The game is over
}

// The full state of a Hand Cricket room — synced in real time via Firebase.
class HandRoom {
  final String roomCode;           // 4-letter code to share with your opponent
  final String hostId;             // Firebase ID of the host player
  final HandRoomStatus status;     // Current game state (see enum above)
  final List<Player> players;      // Exactly 2 players
  final int innings;               // 1 = first innings, 2 = second innings (chase)
  final String? batterId;          // Firebase ID of the player currently batting
  final String? bowlerId;          // Firebase ID of the player currently bowling
  final int? target;               // Runs the chasing team needs to win (set after innings 1)
  final int choicesLocked;         // How many players have locked in a number this ball (0, 1, or 2)
  final ActiveEffects activeEffects; // Power card effects active this ball
  final HandRound? lastRound;      // Result of the previous ball (shown on screen)
  final String? winnerId;          // Firebase ID of the winner, or "tie", or null if ongoing
  final List<CommentaryLine> commentary; // AI commentary lines

  const HandRoom({
    required this.roomCode,
    required this.hostId,
    required this.status,
    required this.players,
    this.innings = 1,
    this.batterId,
    this.bowlerId,
    this.target,
    this.choicesLocked = 0,
    this.activeEffects = ActiveEffects.none,
    this.lastRound,
    this.winnerId,
    this.commentary = const [],
  });

  // Build a HandRoom from a Firebase snapshot map
  factory HandRoom.fromJson(Map<String, dynamic> json) {
    // Parse status string → enum
    final statusString = (json['status'] as String?) ?? 'waiting';
    final status = HandRoomStatus.values.firstWhere(
      (s) => s.name == statusString,
      orElse: () => HandRoomStatus.waiting,
    );

    // Parse players list
    final rawPlayers = json['players'] as List<dynamic>? ?? [];
    final players = rawPlayers
        .map((p) => Player.fromJson(p as Map<String, dynamic>))
        .toList();

    // Parse optional last round result
    final rawRound = json['lastRound'];
    final lastRound = rawRound != null
        ? HandRound.fromJson(rawRound as Map<String, dynamic>)
        : null;

    // Parse active effects
    final rawEffects = json['activeEffects'];
    final effects = rawEffects != null
        ? ActiveEffects.fromJson(rawEffects as Map<String, dynamic>)
        : ActiveEffects.none;

    // Parse commentary
    final rawCommentary = json['commentary'] as List<dynamic>? ?? [];
    final commentary = rawCommentary
        .map((c) => CommentaryLine.fromJson(c as Map<String, dynamic>))
        .toList();

    return HandRoom(
      roomCode: json['roomCode'] as String,
      hostId: json['hostId'] as String,
      status: status,
      players: players,
      innings: (json['innings'] as int?) ?? 1,
      batterId: json['batterId'] as String?,
      bowlerId: json['bowlerId'] as String?,
      target: json['target'] as int?,
      choicesLocked: (json['choicesLocked'] as int?) ?? 0,
      activeEffects: effects,
      lastRound: lastRound,
      winnerId: json['winnerId'] as String?,
      commentary: commentary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'status': status.name,
      'players': players.map((p) => p.toJson()).toList(),
      'innings': innings,
      'batterId': batterId,
      'bowlerId': bowlerId,
      'target': target,
      'choicesLocked': choicesLocked,
      'activeEffects': activeEffects.toJson(),
      'lastRound': lastRound?.toJson(),
      'winnerId': winnerId,
      'commentary': commentary.map((c) => c.toJson()).toList(),
    };
  }
}
