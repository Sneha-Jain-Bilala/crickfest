// The result shown to a player after they submit an answer in IPL Trivia.
// Tells them if they were correct and how many points they earned.

class AnswerResult {
  final bool isCorrect;  // Did the player pick the right option?
  final int scoreDelta;  // How many points were added to their score
  final bool doubled;    // Was the "Double Runs" power card active? (shows "+20 double runs")

  const AnswerResult({
    required this.isCorrect,
    required this.scoreDelta,
    this.doubled = false,
  });

  // Build an AnswerResult from a Firebase / JSON map
  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    return AnswerResult(
      isCorrect: (json['isCorrect'] as bool?) ?? false,
      scoreDelta: (json['scoreDelta'] as int?) ?? 0,
      doubled: (json['doubled'] as bool?) ?? false,
    );
  }

  // Convert to a map for saving to Firebase
  Map<String, dynamic> toJson() {
    return {
      'isCorrect': isCorrect,
      'scoreDelta': scoreDelta,
      'doubled': doubled,
    };
  }
}
