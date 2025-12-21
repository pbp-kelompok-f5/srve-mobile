// File: lib/modules/matches/models/submatch.dart

class SubMatch {
  final int id;
  final String playersA;
  final String playersB;
  final int scoreA;
  final int scoreB;

  SubMatch({
    required this.id,
    required this.playersA,
    required this.playersB,
    required this.scoreA,
    required this.scoreB,
  });

  factory SubMatch.fromJson(Map<String, dynamic> json) {
    return SubMatch(
      id: json['id'],
      playersA: json['players_A'],
      playersB: json['players_B'],
      scoreA: json['score_A'],
      scoreB: json['score_B'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'players_A': playersA,
      'players_B': playersB,
      'score_A': scoreA,
      'score_B': scoreB,
    };
  }
}