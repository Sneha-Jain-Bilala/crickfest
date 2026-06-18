import 'player.dart';
import 'question.dart';
import 'commentary_line.dart';

// All possible states of an IPL Trivia room.
// The game moves through these states in order.
enum TriviaRoomStatus {
  waiting,    // Players are in the lobby waiting for the host to start
  starting,   // Game is about to start (brief transition)
  answering,  // A question is live and players can submit answers
  revealing,  // The correct answer is being revealed
  finished,   // The game is over and the final leaderboard is shown
}

// A leaderboard entry shown in the scoreboard panel on the side.
class LeaderboardEntry {
  final int rank;       // Position: 1, 2, 3 …
  final String name;    // Player's display name
  final int score;      // Their total score

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as int?) ?? 0,
      name: json['name'] as String,
      score: (json['score'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'rank': rank, 'name': name, 'score': score};
  }
}

// The full state of an IPL Trivia room — synced in real time via Firebase.
class TriviaRoom {
  final String roomCode;               // 4-letter code players share to join
  final String hostId;                 // Firebase ID of the host player
  final TriviaRoomStatus status;       // Current game state (see enum above)
  final List<Player> players;          // Everyone in the room
  final Question? currentQuestion;     // The question currently on screen (null if waiting)
  final int questionIndex;             // How many questions have been asked so far
  final int totalQuestions;            // Total number of questions in the game (usually 10)
  final int timeLeft;                  // Seconds remaining on the shot clock (0–10)
  final List<LeaderboardEntry> leaderboard; // Live scoreboard
  final List<CommentaryLine> commentary;    // AI commentary lines

  const TriviaRoom({
    required this.roomCode,
    required this.hostId,
    required this.status,
    required this.players,
    this.currentQuestion,
    this.questionIndex = 0,
    this.totalQuestions = 10,
    this.timeLeft = 10,
    this.leaderboard = const [],
    this.commentary = const [],
  });

  // Build a TriviaRoom from a Firebase snapshot map
  factory TriviaRoom.fromJson(Map<String, dynamic> json) {
    // Parse status string → enum
    final statusString = (json['status'] as String?) ?? 'waiting';
    final status = TriviaRoomStatus.values.firstWhere(
      (s) => s.name == statusString,
      orElse: () => TriviaRoomStatus.waiting,
    );

    // Parse players list
    final rawPlayers = json['players'] as List<dynamic>? ?? [];
    final players = rawPlayers
        .map((p) => Player.fromJson(p as Map<String, dynamic>))
        .toList();

    // Parse optional current question
    final rawQuestion = json['currentQuestion'];
    final question = rawQuestion != null
        ? Question.fromJson(rawQuestion as Map<String, dynamic>)
        : null;

    // Parse leaderboard
    final rawBoard = json['leaderboard'] as List<dynamic>? ?? [];
    final leaderboard = rawBoard
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse commentary
    final rawCommentary = json['commentary'] as List<dynamic>? ?? [];
    final commentary = rawCommentary
        .map((c) => CommentaryLine.fromJson(c as Map<String, dynamic>))
        .toList();

    return TriviaRoom(
      roomCode: json['roomCode'] as String,
      hostId: json['hostId'] as String,
      status: status,
      players: players,
      currentQuestion: question,
      questionIndex: (json['questionIndex'] as int?) ?? 0,
      totalQuestions: (json['totalQuestions'] as int?) ?? 10,
      timeLeft: (json['timeLeft'] as int?) ?? 10,
      leaderboard: leaderboard,
      commentary: commentary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'status': status.name,
      'players': players.map((p) => p.toJson()).toList(),
      'currentQuestion': currentQuestion?.toJson(),
      'questionIndex': questionIndex,
      'totalQuestions': totalQuestions,
      'timeLeft': timeLeft,
      'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      'commentary': commentary.map((c) => c.toJson()).toList(),
    };
  }
}
