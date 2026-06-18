// A single trivia question shown during the IPL Trivia game mode.

class Question {
  final String id;                    // Unique ID used to track which question is active
  final String question;              // The question text shown to players
  final List<String> options;         // Four answer choices (A, B, C, D)
  final int correctIndex;             // Index of the correct option (0 = A, 1 = B …)
  final String source;                // "groq" if AI-generated, "seed" if from trivia.json
  final List<int> hiddenOptionIndexes; // Indexes hidden by the "Review" power card

  const Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.source = 'seed',
    this.hiddenOptionIndexes = const [],
  });

  // Build a Question from a Firebase / JSON map
  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    final rawHidden = json['hiddenOptionIndexes'] as List<dynamic>? ?? [];

    return Question(
      id: json['id'] as String,
      question: json['question'] as String,
      options: rawOptions.map((o) => o as String).toList(),
      correctIndex: (json['correctIndex'] as int?) ?? 0,
      source: (json['source'] as String?) ?? 'seed',
      hiddenOptionIndexes: rawHidden.map((i) => i as int).toList(),
    );
  }

  // Convert a Question to a map for saving to Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'source': source,
      'hiddenOptionIndexes': hiddenOptionIndexes,
    };
  }
}
