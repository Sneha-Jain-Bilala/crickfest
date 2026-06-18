import 'power_card.dart';

// A player inside a room.
// Used by both Trivia and Hand Cricket game modes.

class Player {
  final String id;          // Unique socket/Firebase ID for this player
  final String name;        // Display name chosen by the player
  final int score;          // Current score (runs / trivia points)
  final bool isHost;        // Is this player the room host / captain?
  final bool isBatter;      // Hand cricket: is this player currently batting?
  final bool isBowler;      // Hand cricket: is this player currently bowling?
  final bool answered;      // Trivia: has this player answered the current question?
  final bool hasChosen;     // Hand cricket: has this player locked in a number this ball?
  final List<PowerCard> powerCards; // The special ability cards this player holds

  const Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.isHost = false,
    this.isBatter = false,
    this.isBowler = false,
    this.answered = false,
    this.hasChosen = false,
    this.powerCards = const [],
  });

  // Build a Player from a Firebase / JSON map
  factory Player.fromJson(Map<String, dynamic> json) {
    // Parse the list of power cards (may be missing if player has none)
    final rawCards = json['powerCards'] as List<dynamic>? ?? [];
    final cards = rawCards
        .map((c) => PowerCard.fromJson(c as Map<String, dynamic>))
        .toList();

    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      score: (json['score'] as int?) ?? 0,
      isHost: (json['isHost'] as bool?) ?? false,
      isBatter: (json['isBatter'] as bool?) ?? false,
      isBowler: (json['isBowler'] as bool?) ?? false,
      answered: (json['answered'] as bool?) ?? false,
      hasChosen: (json['hasChosen'] as bool?) ?? false,
      powerCards: cards,
    );
  }

  // Convert a Player to a map for saving to Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'isHost': isHost,
      'isBatter': isBatter,
      'isBowler': isBowler,
      'answered': answered,
      'hasChosen': hasChosen,
      'powerCards': powerCards.map((c) => c.toJson()).toList(),
    };
  }
}
