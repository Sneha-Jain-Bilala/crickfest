import 'dart:convert'; // For json.encode / json.decode
import 'dart:math';   // For picking random fallback templates
import 'package:http/http.dart' as http;

// CommentaryService generates cricket commentary for game events.
//
// It tries the Groq AI API first (one punchy line, under 18 words).
// If the API key is missing or the call fails, it falls back to
// hand-written template strings that match the original game mood.
//
// HOW TO GET A FREE GROQ KEY:
//   1. Go to https://console.groq.com
//   2. Sign up → API Keys → Create new key
//   3. Paste it below as the value of _groqApiKey
class CommentaryService {
  // ── Configuration ─────────────────────────────────────────────────────────

  // Paste your Groq API key here.
  // Leave empty ('') to always use the offline fallback templates.
  static const String _groqApiKey = '';

  // Free-plan model — fast and cheap
  static const String _model = 'llama-3.1-8b-instant';

  // Groq chat completions endpoint
  static const String _groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Maximum number of commentary lines kept in Firebase (oldest drop off)
  static const int commentaryLimit = 8;

  // ── Public API ────────────────────────────────────────────────────────────

  // Generates a single commentary line for the given event map.
  // Always returns a non-empty string.
  Future<String> generateLine(Map<String, dynamic> event) async {
    // Always compute a fallback first so we never return empty
    final fallback = _fallback(event);

    // If no API key, skip the network call
    if (_groqApiKey.isEmpty) return fallback;

    try {
      final response = await http
          .post(
            Uri.parse(_groqUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_groqApiKey',
            },
            body: json.encode({
              'model': _model,
              'max_tokens': 40,
              'temperature': 0.75,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a witty cricket commentator for a hackathon game. '
                          'Reply with one punchy line under 18 words. No quotes.',
                },
                {
                  'role': 'user',
                  'content': json.encode(event),
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 5)); // Don't wait too long

      if (response.statusCode != 200) return fallback;

      final body = json.decode(response.body) as Map<String, dynamic>;
      final text =
          ((body['choices'] as List?)?.first['message']['content'] as String?)
                  ?.trim() ??
              '';

      // Strip any surrounding quotes the model sometimes adds
      final cleaned =
          text.replaceAll(RegExp(r'''^['"]+|['"]+$'''), '').trim();
      return cleaned.isNotEmpty ? cleaned.substring(0, cleaned.length.clamp(0, 180)) : fallback;
    } catch (_) {
      // Network error, timeout, bad JSON — always fall back gracefully
      return fallback;
    }
  }

  // ── Fallback template engine ───────────────────────────────────────────────
  // Mirrors the original server/commentary.js fallbackTemplates.

  final Random _rand = Random();

  String _pick(List<String> list) => list[_rand.nextInt(list.length)];

  String _fallback(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? '';

    switch (type) {
      case 'trivia_answer':
        final name = event['playerName'] ?? 'The batter';
        final delta = event['scoreDelta'] ?? 0;
        final isCorrect = event['isCorrect'] as bool? ?? false;
        return isCorrect
            ? _pick([
                '$name nails it for $delta. Clean strike under pressure.',
                '$name finds the gap. $delta added in style.',
                '$name reads it early and cashes in for $delta.',
                'That is crisp from $name. The scoreboard jumps by $delta.',
                '$name goes straight down the ground. Correct answer, big reward.',
              ])
            : _pick([
                '$name swings and misses. The scoreboard does not move.',
                '$name goes for glory, but that one sneaks through.',
                'Close shout against $name, and the umpire says no runs.',
                '$name cannot connect this time. Dot ball in the quiz chase.',
                'A rare misread from $name. Pressure stays on.',
              ]);

      case 'trivia_end':
        final answer = event['correctAnswer'] ?? 'unknown';
        final reason = event['reason'] ?? '';
        return reason == 'timeout'
            ? _pick([
                'Time is up. The answer was $answer.',
                'The clock wins that round. $answer was hiding in plain sight.',
                'No more time on the board. $answer was the answer.',
                'That question beats the room. The right call was $answer.',
              ])
            : _pick([
                'Everyone has locked in. $answer was the one.',
                'All answers are in. $answer takes the spotlight.',
                'Fast hands around the room. The correct answer: $answer.',
                'The room commits early. $answer settles it.',
              ]);

      case 'trivia_game_end':
        final winner = event['winnerName'] ?? 'The top scorer';
        final score = event['score'] ?? 0;
        return _pick([
          '$winner tops the table with $score. Big finish.',
          '$winner owns the final leaderboard. $score on the board.',
          'Match over. $winner finishes ahead with $score.',
          '$winner times the chase beautifully and wins with $score.',
        ]);

      case 'hand_round':
        final batter = event['batterName'] ?? 'Batter';
        final bowler = event['bowlerName'] ?? 'Bowler';
        final bChoice = event['batterChoice'] ?? 0;
        final bwChoice = event['bowlerChoice'] ?? 0;
        final runs = event['runs'] ?? 0;
        final wicket = event['wicket'] as bool? ?? false;
        final freeHit = event['freeHitSaved'] as bool? ?? false;

        if (freeHit) {
          return _pick([
            'Free Hit drama. Matching ${bChoice}s, but $batter survives.',
            '$batter gets a life. Free Hit turns a wicket into theatre.',
            'They match numbers, but Free Hit says not today. $batter stays in.',
            'Free Hit pays off. $batter survives the perfect match.',
          ]);
        }
        if (wicket) {
          return _pick([
            '$bowler matches $bChoice. Wicket, and the room erupts.',
            '$bowler calls the bluff. Same number, batter gone.',
            'Bullseye from $bowler. $batter has to walk.',
            '$bowler lands the perfect hand-cricket yorker. Wicket.',
          ]);
        }
        return _pick([
          '$batter picks $bChoice, $bowler misses with $bwChoice. $runs on the board.',
          '$batter sneaks $runs. The bowler guessed $bwChoice.',
          '$batter keeps the innings moving with $runs.',
          'No match from $bowler. $batter pockets $runs.',
          '$batter wins the mind game and adds $runs.',
        ]);

      case 'hand_innings':
        final target = event['target'] ?? 0;
        return _pick([
          'Innings switch. The chase is $target. This could get spicy.',
          'Target set at $target. Time for the chase.',
          'One innings down. $target is the number to beat.',
          'The chase begins now. $target needed for victory.',
        ]);

      case 'hand_game_end':
        final winner = event['winnerName'] ?? '';
        if (winner == 'Tie') {
          return _pick([
            'Scores level. Hand cricket has produced a proper thriller.',
            'Nothing separates them. That is a proper last-ball kind of tie.',
            'Dead heat on the scoreboard. Nobody blinked.',
            'All square. The rematch button suddenly looks very tempting.',
          ]);
        }
        return _pick([
          '$winner takes the match. Ice in the veins.',
          '$winner wins the duel. Sharp hands, sharper nerve.',
          'Game over. $winner reads the room and takes it.',
          '$winner closes it out like a finisher.',
        ]);

      case 'power_card':
        final player = event['playerName'] ?? 'A player';
        final card = event['cardLabel'] ?? 'a boost';
        return _pick([
          '$player plays $card. Tactical twist incoming.',
          '$card is out from $player. The plot thickens.',
          '$player reaches for $card. Brave call.',
          '$card changes the field for $player.',
        ]);

      default:
        return _pick([
          'The match keeps moving. Eyes on the next ball.',
          'A little pause, a little pressure, and we go again.',
          'The room resets. Next moment could swing it.',
          'Nothing settled yet. The next play matters.',
        ]);
    }
  }
}
