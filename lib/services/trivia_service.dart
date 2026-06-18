import 'dart:convert';     // For json.decode
import 'dart:math';       // For Random
import 'package:flutter/services.dart'; // For rootBundle (reads assets/)
import '../models/question.dart';

// TriviaService loads the IPL questions from assets/trivia.json,
// shuffles them, and picks 10 for each game.
// It also calculates the score for a correct answer.

class TriviaService {
  // Cached list of all questions — loaded once, reused for every game
  List<Question> _allQuestions = [];

  // Whether questions have been loaded yet
  bool get isLoaded => _allQuestions.isNotEmpty;

  // ── Load questions from assets ────────────────────────────────────────────

  // Call this once before starting a game.
  // Reads assets/trivia.json and converts each entry into a Question object.
  Future<void> loadQuestions() async {
    if (isLoaded) return; // Already loaded — don't reload

    // Read the raw JSON file from the assets folder
    final String raw = await rootBundle.loadString('assets/trivia.json');

    // Parse the JSON array into a Dart list of maps
    final List<dynamic> jsonList = json.decode(raw) as List<dynamic>;

    // Convert each map to a Question object
    _allQuestions = jsonList
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── Pick questions for a game ─────────────────────────────────────────────

  // Returns a shuffled list of [count] questions for one game session.
  // Always call loadQuestions() first.
  List<Question> pickQuestions({int count = 10}) {
    if (_allQuestions.isEmpty) {
      throw StateError('Call loadQuestions() before pickQuestions().');
    }

    // Copy and shuffle so each game gets a different order
    final shuffled = List<Question>.from(_allQuestions)..shuffle(Random());

    // Return only [count] questions (or fewer if the bank is small)
    return shuffled.take(count).toList();
  }

  // ── Scoring ───────────────────────────────────────────────────────────────

  // Calculates the points a player earns for a correct answer.
  //
  // Base score: 10 points
  // Speed bonus: +1 point for each second remaining on the clock
  // Double Runs power card: doubles the total if active
  //
  // Example: answered at 7 seconds left, normal → 10 + 7 = 17 points
  //          answered at 7 seconds left, Double Runs → (10 + 7) × 2 = 34 points
  int calculateScore({
    required int timeLeft,   // Seconds left when the answer was submitted
    bool doubleRuns = false, // Is the "Double Runs" power card active?
  }) {
    const int baseScore = 10;
    final int speedBonus = timeLeft; // 1 point per second remaining
    final int total = baseScore + speedBonus;
    return doubleRuns ? total * 2 : total;
  }

  // Wrong answer always scores 0
  int wrongAnswerScore() => 0;
}
