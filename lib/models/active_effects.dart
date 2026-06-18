// Active power card effects in a Hand Cricket room.
// These effects last for only one ball then are cleared automatically.

// The Yorker effect blocks the batter from choosing a specific number.
class YorkerEffect {
  final int blockedNumber;  // The number (1-6) the batter cannot choose this ball
  final String bowlerId;    // ID of the bowler who activated the Yorker card

  const YorkerEffect({
    required this.blockedNumber,
    required this.bowlerId,
  });

  factory YorkerEffect.fromJson(Map<String, dynamic> json) {
    return YorkerEffect(
      blockedNumber: (json['blockedNumber'] as int?) ?? 0,
      bowlerId: json['bowlerId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blockedNumber': blockedNumber,
      'bowlerId': bowlerId,
    };
  }
}

// Holds all currently active effects in the room.
class ActiveEffects {
  // ID of the batter who has Free Hit (cannot be dismissed this ball).
  // null means Free Hit is not active.
  final String? freeHitPlayerId;

  // The Yorker effect details. null means no Yorker is active.
  final YorkerEffect? yorker;

  const ActiveEffects({
    this.freeHitPlayerId,
    this.yorker,
  });

  // Empty / no effects active
  static const ActiveEffects none = ActiveEffects();

  factory ActiveEffects.fromJson(Map<String, dynamic> json) {
    final rawYorker = json['yorker'];
    return ActiveEffects(
      freeHitPlayerId: json['freeHitPlayerId'] as String?,
      yorker: rawYorker != null
          ? YorkerEffect.fromJson(rawYorker as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'freeHitPlayerId': freeHitPlayerId,
      'yorker': yorker?.toJson(),
    };
  }
}
