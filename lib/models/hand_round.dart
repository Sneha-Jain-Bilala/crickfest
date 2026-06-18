// The result of one ball in Hand Cricket.
// After both players lock in their number, this reveals what happened.

class HandRound {
  final int innings;           // 1 or 2 — which innings this ball was in
  final String batterName;     // Name of the batter this ball
  final String bowlerName;     // Name of the bowler this ball
  final int batterChoice;      // Number the batter picked (1–6)
  final int bowlerChoice;      // Number the bowler picked (1–6)
  final int runs;              // Runs scored: batter's number if no match, else 0
  final bool wicket;           // true if the numbers matched (and no Free Hit saved it)
  final bool freeHitSaved;     // true if Free Hit card prevented the dismissal
  final int batterScore;       // Batter's total score after this ball
  final int? target;           // The target the chasing team needs (innings 2 only)

  const HandRound({
    required this.innings,
    required this.batterName,
    required this.bowlerName,
    required this.batterChoice,
    required this.bowlerChoice,
    required this.runs,
    required this.wicket,
    required this.batterScore,
    this.freeHitSaved = false,
    this.target,
  });

  // Build a HandRound from a Firebase / JSON map
  factory HandRound.fromJson(Map<String, dynamic> json) {
    return HandRound(
      innings: (json['innings'] as int?) ?? 1,
      batterName: json['batterName'] as String,
      bowlerName: json['bowlerName'] as String,
      batterChoice: (json['batterChoice'] as int?) ?? 0,
      bowlerChoice: (json['bowlerChoice'] as int?) ?? 0,
      runs: (json['runs'] as int?) ?? 0,
      wicket: (json['wicket'] as bool?) ?? false,
      freeHitSaved: (json['freeHitSaved'] as bool?) ?? false,
      batterScore: (json['batterScore'] as int?) ?? 0,
      target: json['target'] as int?,
    );
  }

  // Convert to a map for saving to Firebase
  Map<String, dynamic> toJson() {
    return {
      'innings': innings,
      'batterName': batterName,
      'bowlerName': bowlerName,
      'batterChoice': batterChoice,
      'bowlerChoice': bowlerChoice,
      'runs': runs,
      'wicket': wicket,
      'freeHitSaved': freeHitSaved,
      'batterScore': batterScore,
      'target': target,
    };
  }
}
