import 'dart:math'; // For generating random room codes
import 'package:firebase_database/firebase_database.dart';

import '../models/trivia_room.dart';
import '../models/hand_room.dart';
import 'commentary_service.dart'; // AI + fallback commentary

// ---------------------------------------------------------------------------
// Deep-cast helper
// ---------------------------------------------------------------------------
// Firebase on Web returns LinkedMap<Object?, Object?> instead of
// Map<String, dynamic> for every nested map in the snapshot.
// Map<String, dynamic>.from() only does a SHALLOW cast, so nested
// objects (players list, powerCards, etc.) still crash at runtime.
//
// _deepCast() walks the entire tree and converts every map and list
// recursively so our fromJson() methods always receive clean types.
// ---------------------------------------------------------------------------

// Converts any value returned by Firebase into its clean Dart equivalent.
dynamic _deepCastValue(dynamic value) {
  if (value is Map) {
    // Convert every key to String, recursively cast every value
    return Map<String, dynamic>.fromEntries(
      value.entries.map(
        (e) => MapEntry(e.key.toString(), _deepCastValue(e.value)),
      ),
    );
  } else if (value is List) {
    // Recursively cast every list element
    return value.map(_deepCastValue).toList();
  }
  // Primitives (int, double, bool, String, null) pass through unchanged
  return value;
}

// Convenience wrapper that always returns a Map<String, dynamic>.
Map<String, dynamic> _deepCast(dynamic raw) {
  return _deepCastValue(raw) as Map<String, dynamic>;
}

// ---------------------------------------------------------------------------
// FirebaseService
// ---------------------------------------------------------------------------
// Every other part of the app (screens, widgets) talks to Firebase ONLY
// through this class — keeping the rest of the code clean and simple.
//
// Database structure:
//   /trivia_rooms/{roomCode}/   ← IPL Trivia rooms
//   /hand_rooms/{roomCode}/     ← Hand Cricket rooms

class FirebaseService {
  // The root reference to Firebase Realtime Database
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Commentary generator (tries Groq AI, falls back to templates)
  final _commentary = CommentaryService();

  // ── Helpers ───────────────────────────────────────────────────────────────

  // Pushes one commentary line to Firebase and trims the list to the limit.
  // [ref] is either a trivia or hand room reference.
  Future<void> _pushCommentary(
      DatabaseReference ref, String text, String mode) async {
    await ref.runTransaction((current) {
      if (current == null) return Transaction.success(current);
      final room = _deepCast(current);

      // Build the new line
      final newLine = {
        'text': text,
        'mode': mode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Prepend to list and keep only the most recent [commentaryLimit] items
      final existing = (room['commentary'] as List? ?? [])
          .map((l) => _deepCast(l))
          .toList();
      final updated = [newLine, ...existing]
          .take(CommentaryService.commentaryLimit)
          .toList();

      room['commentary'] = updated;
      return Transaction.success(room);
    });
  }

  // Generates a random 4-character uppercase room code, e.g. "XK7P"
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No confusable chars
    final random = Random();
    return List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // Reference to a specific trivia room node
  DatabaseReference _triviaRef(String roomCode) =>
      _db.child('trivia_rooms').child(roomCode);

  // Reference to a specific hand room node
  DatabaseReference _handRef(String roomCode) =>
      _db.child('hand_rooms').child(roomCode);

  // ── Connection state ──────────────────────────────────────────────────────

  // Returns a stream that emits true when connected to Firebase, false when not.
  // Used by the ConnectionBadge widget.
  Stream<bool> connectionStream() {
    return FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .map((event) => (event.snapshot.value as bool?) ?? false);
  }

  // ── IPL Trivia — Room create & join ───────────────────────────────────────

  // Creates a brand-new Trivia room and returns the room code.
  // The creator becomes the host.
  Future<String> createTriviaRoom({
    required String playerId,
    required String playerName,
  }) async {
    final roomCode = _generateRoomCode();

    // The initial room data we write to Firebase
    final roomData = {
      'roomCode': roomCode,
      'hostId': playerId,
      'status': 'waiting', // Game hasn't started yet
      'questionIndex': 0,
      'totalQuestions': 10,
      'timeLeft': 10,
      'players': [
        {
          'id': playerId,
          'name': playerName,
          'score': 0,
          'isHost': true,
          'isBatter': false,
          'isBowler': false,
          'answered': false,
          'hasChosen': false,
          'powerCards': [
            {
              'id': 'review',
              'label': 'Review',
              'description': 'Hide one wrong option for this question.',
              'used': false,
              'active': false,
            },
            {
              'id': 'double_runs',
              'label': 'Double Runs',
              'description': 'Your next correct answer scores double.',
              'used': false,
              'active': false,
            },
          ],
        }
      ],
      'leaderboard': [],
      'commentary': [],
    };

    // Write the room to Firebase
    await _triviaRef(roomCode).set(roomData);
    return roomCode;
  }

  // Adds a player to an existing Trivia room.
  // Returns the room code on success, throws an error if room doesn't exist.
  Future<String> joinTriviaRoom({
    required String roomCode,
    required String playerId,
    required String playerName,
  }) async {
    final ref = _triviaRef(roomCode);

    // Check the room actually exists first
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      throw Exception('Room "$roomCode" not found. Check the code and try again.');
    }

    // Check the room hasn't already started
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    if (data['status'] != 'waiting') {
      throw Exception('This game has already started. Wait for the next one!');
    }

    // Count existing players — max 4 for trivia
    final players = (data['players'] as List?) ?? [];
    if (players.length >= 4) {
      throw Exception('Room is full. Maximum 4 players per room.');
    }

    // Build the new player object
    final newPlayer = {
      'id': playerId,
      'name': playerName,
      'score': 0,
      'isHost': false,
      'isBatter': false,
      'isBowler': false,
      'answered': false,
      'hasChosen': false,
      'powerCards': [
        {
          'id': 'review',
          'label': 'Review',
          'description': 'Hide one wrong option for this question.',
          'used': false,
          'active': false,
        },
        {
          'id': 'double_runs',
          'label': 'Double Runs',
          'description': 'Your next correct answer scores double.',
          'used': false,
          'active': false,
        },
      ],
    };

    // Append the player to the list using a transaction (safe for concurrent joins)
    await ref.child('players').runTransaction((current) {
      final list = (current as List?) ?? [];
      list.add(newPlayer);
      return Transaction.success(list);
    });

    return roomCode;
  }

  // Listens to a Trivia room in real time.
  // Every time Firebase data changes, this emits an updated TriviaRoom object.
  Stream<TriviaRoom> triviaRoomStream(String roomCode) {
    return _triviaRef(roomCode).onValue.map((event) {
      if (!event.snapshot.exists) {
        throw Exception('Trivia room "$roomCode" no longer exists.');
      }
      // _deepCast fixes the web-only LinkedMap<Object?,Object?> issue
      final data = _deepCast(event.snapshot.value);
      return TriviaRoom.fromJson(data);
    });
  }

  // ── Hand Cricket — Room create & join ─────────────────────────────────────

  // Creates a brand-new Hand Cricket room and returns the room code.
  Future<String> createHandRoom({
    required String playerId,
    required String playerName,
  }) async {
    final roomCode = _generateRoomCode();

    final roomData = {
      'roomCode': roomCode,
      'hostId': playerId,
      'status': 'waiting',
      'innings': 1,
      'batterId': playerId, // Host bats first
      'bowlerId': null,
      'target': null,
      'choicesLocked': 0,
      'activeEffects': {
        'freeHitPlayerId': null,
        'yorker': null,
      },
      'lastRound': null,
      'winnerId': null,
      'players': [
        {
          'id': playerId,
          'name': playerName,
          'score': 0,
          'isHost': true,
          'isBatter': true,
          'isBowler': false,
          'answered': false,
          'hasChosen': false,
          'powerCards': [
            {
              'id': 'free_hit',
              'label': 'Free Hit',
              'description': 'You cannot get out on the next ball.',
              'used': false,
              'active': false,
            },
            {
              'id': 'yorker',
              'label': 'Yorker',
              'description': 'Block one batter number for the next ball.',
              'used': false,
              'active': false,
            },
          ],
        }
      ],
      'commentary': [],
    };

    await _handRef(roomCode).set(roomData);
    return roomCode;
  }

  // Adds the second player to a Hand Cricket room.
  Future<String> joinHandRoom({
    required String roomCode,
    required String playerId,
    required String playerName,
  }) async {
    final ref = _handRef(roomCode);

    final snapshot = await ref.get();
    if (!snapshot.exists) {
      throw Exception('Room "$roomCode" not found. Check the code and try again.');
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    if (data['status'] != 'waiting') {
      throw Exception('This game has already started.');
    }

    final players = (data['players'] as List?) ?? [];
    if (players.length >= 2) {
      throw Exception('Room is full. Hand Cricket is 1v1 only.');
    }

    // The second player is the bowler
    final newPlayer = {
      'id': playerId,
      'name': playerName,
      'score': 0,
      'isHost': false,
      'isBatter': false,
      'isBowler': true, // Opponent bowls first
      'answered': false,
      'hasChosen': false,
      'powerCards': [
        {
          'id': 'free_hit',
          'label': 'Free Hit',
          'description': 'You cannot get out on the next ball.',
          'used': false,
          'active': false,
        },
        {
          'id': 'yorker',
          'label': 'Yorker',
          'description': 'Block one batter number for the next ball.',
          'used': false,
          'active': false,
        },
      ],
    };

    await ref.runTransaction((current) {
      final room = Map<String, dynamic>.from(current as Map? ?? {});
      final list = (room['players'] as List?) ?? [];
      list.add(newPlayer);
      // Also set the bowler ID now that we know who joined
      room['players'] = list;
      room['bowlerId'] = playerId;
      return Transaction.success(room);
    });

    return roomCode;
  }

  // Listens to a Hand Cricket room in real time.
  Stream<HandRoom> handRoomStream(String roomCode) {
    return _handRef(roomCode).onValue.map((event) {
      if (!event.snapshot.exists) {
        throw Exception('Hand room "$roomCode" no longer exists.');
      }
      // _deepCast fixes the web-only LinkedMap<Object?,Object?> issue
      final data = _deepCast(event.snapshot.value);
      return HandRoom.fromJson(data);
    });
  }

  // ── Shared utilities ──────────────────────────────────────────────────────

  // Removes a player from a room when they leave or disconnect.
  // Called from the screen's dispose() method.
  Future<void> leaveRoom({
    required String roomCode,
    required String playerId,
    required bool isTrivia,
  }) async {
    final ref = isTrivia ? _triviaRef(roomCode) : _handRef(roomCode);
    await ref.runTransaction((current) {
      if (current == null) return Transaction.success(current);
      final room = _deepCast(current);
      final players = (room['players'] as List? ?? [])
          .where((p) => (_deepCastValue(p) as Map)['id'] != playerId)
          .toList();
      room['players'] = players;
      return Transaction.success(room);
    });
  }

  // ── IPL Trivia — Game flow ────────────────────────────────────────────────

  // Host calls this to start the game.
  // Writes the first question + sets status = 'answering'.
  // [questions] is the list returned by TriviaService.pickQuestions().
  Future<void> startTriviaGame({
    required String roomCode,
    required List<Map<String, dynamic>> questions, // Already serialised to JSON maps
  }) async {
    await _triviaRef(roomCode).update({
      'status': 'answering',
      'questionIndex': 0,
      'timeLeft': 10,
      'currentQuestion': questions[0], // Show the first question
      // Store all questions under a separate node so the host can advance them
      'questionBank': questions,
    });
  }

  // Called when a player submits an answer.
  // Updates their score and marks them as answered.
  //
  // [pointsEarned] is already calculated by TriviaService.calculateScore().
  Future<void> submitTriviaAnswer({
    required String roomCode,
    required String playerId,
    required int pointsEarned,
  }) async {
    await _triviaRef(roomCode).runTransaction((current) {
      if (current == null) return Transaction.success(current);

      final room = _deepCast(current);
      final players = (room['players'] as List? ?? []).map((p) {
        final player = _deepCast(p);
        if (player['id'] == playerId) {
          player['answered'] = true;
          player['score'] = ((player['score'] as int?) ?? 0) + pointsEarned;
        }
        return player;
      }).toList();

      room['players'] = players;
      return Transaction.success(room);
    });
  }

  // Host calls this to reveal the correct answer and show the leaderboard.
  // Sets status = 'revealing', builds the leaderboard, and pushes commentary.
  Future<void> revealTriviaAnswer({required String roomCode}) async {
    final snapshot = await _triviaRef(roomCode).get();
    if (!snapshot.exists) return;

    final room = _deepCast(snapshot.value);
    final players = (room['players'] as List? ?? [])
        .map((p) => _deepCast(p))
        .toList();
    final currentQuestion =
        _deepCast(room['currentQuestion'] as Map? ?? {});
    final correctIndex = (currentQuestion['correctIndex'] as int?) ?? 0;
    final options = (currentQuestion['options'] as List? ?? []);
    final correctAnswer =
        correctIndex < options.length ? options[correctIndex].toString() : '?';

    // Sort players by score descending
    players.sort((a, b) =>
        ((b['score'] as int?) ?? 0).compareTo((a['score'] as int?) ?? 0));

    // Build leaderboard entries with rank numbers
    final leaderboard = players.asMap().entries.map((entry) {
      return {
        'rank': entry.key + 1,
        'name': entry.value['name'] as String,
        'score': (entry.value['score'] as int?) ?? 0,
      };
    }).toList();

    await _triviaRef(roomCode).update({
      'status': 'revealing',
      'leaderboard': leaderboard,
    });

    // ── Generate commentary for every player who answered ──────────────────
    // Fire-and-forget: we don't await so the UI isn't blocked
    _generateTriviaRevealCommentary(
      ref: _triviaRef(roomCode),
      players: players,
      correctAnswer: correctAnswer,
    );
  }

  // Generates and pushes commentary lines for each player answer result.
  // Called after reveal; runs async in the background.
  Future<void> _generateTriviaRevealCommentary({
    required DatabaseReference ref,
    required List<Map<String, dynamic>> players,
    required String correctAnswer,
  }) async {
    // One line per player who answered
    for (final player in players) {
      final answered = player['answered'] as bool? ?? false;
      if (!answered) continue;

      final event = {
        'type': 'trivia_answer',
        'playerName': player['name'] ?? 'Player',
        'isCorrect': (player['answered'] == true), // simplified
        'scoreDelta': player['score'] ?? 0,
        'correctAnswer': correctAnswer,
      };
      final line = await _commentary.generateLine(event);
      await _pushCommentary(ref, line, 'trivia');
    }

    // Summary line (all answered / timeout)
    final summaryEvent = {
      'type': 'trivia_end',
      'reason': 'all_answered',
      'correctAnswer': correctAnswer,
    };
    final summaryLine = await _commentary.generateLine(summaryEvent);
    await _pushCommentary(ref, summaryLine, 'trivia');
  }

  // Host calls this to move to the next question (or end the game).
  Future<void> advanceTriviaQuestion({required String roomCode}) async {
    final snapshot = await _triviaRef(roomCode).get();
    if (!snapshot.exists) return;

    final room = _deepCast(snapshot.value);
    final currentIndex = (room['questionIndex'] as int?) ?? 0;
    final totalQuestions = (room['totalQuestions'] as int?) ?? 10;
    final questionBank = (room['questionBank'] as List? ?? []);

    final nextIndex = currentIndex + 1;

    if (nextIndex >= totalQuestions || nextIndex >= questionBank.length) {
      // No more questions — game over
      await _triviaRef(roomCode).update({'status': 'finished'});

      // Game-end commentary — read leaderboard from the existing snapshot
      final existingLeaderboard = (room['leaderboard'] as List? ?? [])
          .map((e) => _deepCast(e))
          .toList();
      final winner =
          existingLeaderboard.isNotEmpty ? existingLeaderboard.first : null;
      if (winner != null) {
        final event = {
          'type': 'trivia_game_end',
          'winnerName': winner['name'] ?? 'The champion',
          'score': winner['score'] ?? 0,
        };
        final line = await _commentary.generateLine(event);
        await _pushCommentary(_triviaRef(roomCode), line, 'trivia');
      }
    } else {
      // Reset player answered flags and push the next question
      final players = (room['players'] as List? ?? []).map((p) {
        final player = _deepCast(p);
        player['answered'] = false; // Reset for next question
        return player;
      }).toList();

      await _triviaRef(roomCode).update({
        'status': 'answering',
        'questionIndex': nextIndex,
        'timeLeft': 10,
        'currentQuestion': questionBank[nextIndex],
        'players': players,
      });
    }
  }

  // Decrements the shot clock by 1 second.
  // The host's device runs this on a Timer.periodic(Duration(seconds: 1), ...).
  Future<void> tickTriviaTimer({required String roomCode}) async {
    await _triviaRef(roomCode).runTransaction((current) {
      if (current == null) return Transaction.success(current);
      final room = _deepCast(current);
      final timeLeft = (room['timeLeft'] as int?) ?? 0;
      room['timeLeft'] = (timeLeft - 1).clamp(0, 10);
      return Transaction.success(room);
    });
  }

  // ── Power card actions (Trivia) ───────────────────────────────────────────

  // Activates the "Review" card for a player — hides one wrong option index.
  Future<void> useReviewCard({
    required String roomCode,
    required String playerId,
    required int hiddenOptionIndex, // The index to hide (chosen by server normally)
  }) async {
    await _triviaRef(roomCode).runTransaction((current) {
      if (current == null) return Transaction.success(current);

      final room = _deepCast(current);

      // Mark the player's Review card as used
      final players = (room['players'] as List? ?? []).map((p) {
        final player = _deepCast(p);
        if (player['id'] == playerId) {
          final cards = (player['powerCards'] as List? ?? []).map((c) {
            final card = _deepCast(c);
            if (card['id'] == 'review') card['used'] = true;
            return card;
          }).toList();
          player['powerCards'] = cards;
        }
        return player;
      }).toList();

      // Add the hidden option to the current question
      final question = _deepCast(room['currentQuestion'] ?? {});
      final hidden = List<int>.from(
          (question['hiddenOptionIndexes'] as List? ?? []));
      if (!hidden.contains(hiddenOptionIndex)) {
        hidden.add(hiddenOptionIndex);
      }
      question['hiddenOptionIndexes'] = hidden;

      room['players'] = players;
      room['currentQuestion'] = question;
      return Transaction.success(room);
    });
  }

  // Activates the "Double Runs" card — marks it active for this player.
  // The next call to submitTriviaAnswer should double their score.
  Future<void> useDoubleRunsCard({
    required String roomCode,
    required String playerId,
  }) async {
    await _triviaRef(roomCode).runTransaction((current) {
      if (current == null) return Transaction.success(current);
      final room = _deepCast(current);
      final players = (room['players'] as List? ?? []).map((p) {
        final player = _deepCast(p);
        if (player['id'] == playerId) {
          final cards = (player['powerCards'] as List? ?? []).map((c) {
            final card = _deepCast(c);
            if (card['id'] == 'double_runs') {
              card['used'] = true;
              card['active'] = true; // Will be deactivated after next answer
            }
            return card;
          }).toList();
          player['powerCards'] = cards;
        }
        return player;
      }).toList();
      room['players'] = players;
      return Transaction.success(room);
    });
  }
}
