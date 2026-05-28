enum GameMode { daily, dailyDueto, dailyQuarteto, infinite }

enum GameStatus {
  loading,
  playing,
  submitting, // Para feedback visual enquanto aguarda API
  won,
  lost,
  error,
}

enum LetterStatus { unknown, absent, present, correct }

extension GameModeExtension on GameMode {
  /// Mapeia para o valor da coluna `game_mode` na tabela `daily_challenges`
  String get supabaseKey {
    switch (this) {
      case GameMode.daily:
        return 'TERMO';
      case GameMode.dailyDueto:
        return 'DUETO';
      case GameMode.dailyQuarteto:
        return 'QUARTETO';
      case GameMode.infinite:
        return 'TERMO';
    }
  }

  /// Número de palavras-alvo simultâneas neste modo
  int get wordCount {
    switch (this) {
      case GameMode.daily:
        return 1;
      case GameMode.dailyDueto:
        return 2;
      case GameMode.dailyQuarteto:
        return 4;
      case GameMode.infinite:
        return 1;
    }
  }

  /// Nome exibido na UI
  String get displayName {
    switch (this) {
      case GameMode.daily:
        return 'Termo';
      case GameMode.dailyDueto:
        return 'Dueto';
      case GameMode.dailyQuarteto:
        return 'Quarteto';
      case GameMode.infinite:
        return 'Infinito';
    }
  }

  /// Se é um modo diário (vs infinito)
  bool get isDaily =>
      this == GameMode.daily ||
      this == GameMode.dailyDueto ||
      this == GameMode.dailyQuarteto;

  /// Mapeia para o identificador usado nas estatísticas de cada modo
  String get statsKey {
    switch (this) {
      case GameMode.daily:
        return 'DAILY';
      case GameMode.dailyDueto:
        return 'DAILY_DUETO';
      case GameMode.dailyQuarteto:
        return 'DAILY_QUARTETO';
      case GameMode.infinite:
        return 'INFINITE';
    }
  }
}
