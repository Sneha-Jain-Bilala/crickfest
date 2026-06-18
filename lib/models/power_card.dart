// A power card is a one-use special ability a player can activate during the game.
// Examples: "Review" (hide a wrong answer), "Double Runs" (double your next score).

class PowerCard {
  final String id;          // Unique key, e.g. "review" or "double_runs"
  final String label;       // Display name shown on the button, e.g. "Review"
  final String description; // Short description shown under the label
  final bool used;          // Has this card already been used?
  final bool active;        // Is the effect currently active this ball/question?

  const PowerCard({
    required this.id,
    required this.label,
    required this.description,
    this.used = false,
    this.active = false,
  });

  // Build a PowerCard from a Firebase / JSON map
  factory PowerCard.fromJson(Map<String, dynamic> json) {
    return PowerCard(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      used: (json['used'] as bool?) ?? false,
      active: (json['active'] as bool?) ?? false,
    );
  }

  // Convert a PowerCard to a map for saving to Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'description': description,
      'used': used,
      'active': active,
    };
  }
}
