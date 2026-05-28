class GameStats {
  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int maxStreak;
  final Map<int, int> guessDistribution;

  GameStats({
    required this.gamesPlayed,
    required this.gamesWon,
    required this.currentStreak,
    required this.maxStreak,
    required this.guessDistribution,
  });

  factory GameStats.empty() {
    return GameStats(
      gamesPlayed: 0,
      gamesWon: 0,
      currentStreak: 0,
      maxStreak: 0,
      guessDistribution: {},
    );
  }

  factory GameStats.fromJson(Map<String, dynamic> json) {
    final rawDist = json['guess_distribution'] as Map<dynamic, dynamic>? ?? {};
    final dist = <int, int>{};
    rawDist.forEach((key, value) {
      final k = int.tryParse(key.toString());
      final v = int.tryParse(value.toString());
      if (k != null && v != null) {
        dist[k] = v;
      }
    });

    return GameStats(
      gamesPlayed: json['games_played'] as int? ?? 0,
      gamesWon: json['games_won'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      maxStreak: json['max_streak'] as int? ?? 0,
      guessDistribution: dist,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'games_played': gamesPlayed,
      'games_won': gamesWon,
      'current_streak': currentStreak,
      'max_streak': maxStreak,
      'guess_distribution': guessDistribution.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
}
