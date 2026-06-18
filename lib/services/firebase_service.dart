import 'dart:math'; // For generating random room codes
import 'package:firebase_database/firebase_database.dart';

import '../models/trivia_room.dart';
import '../models/hand_room.dart';

// FirebaseService handles ALL communication with the Firebase Realtime Database.
// Every other part of the app (screens, widgets) talks to Firebase ONLY through
// this class — keeping the rest of the code clean and simple.
//
// Database structure:
//   /trivia_rooms/{roomCode}/   ← IPL Trivia rooms
//   /hand_rooms/{roomCode}/     ← Hand Cricket rooms

class FirebaseService {
  // The root reference to Firebase Realtime Database
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // ── Helpers ───────────────────────────────────────────────────────────────

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
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
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
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
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
      final room = Map<String, dynamic>.from(current as Map);
      final players = (room['players'] as List? ?? [])
          .where((p) => (p as Map)['id'] != playerId)
          .toList();
      room['players'] = players;
      return Transaction.success(room);
    });
  }
}
