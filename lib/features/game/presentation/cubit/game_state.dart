import '../../domain/entities/game_enums.dart';
import '../../domain/entities/guess_result.dart';

class GameState {
  final GameStatus status;
  final GameMode mode;
  final int targetWordId;
  final String targetWord;
  final String currentGuess;
  final List<GuessResult> guesses;
  final Map<String, LetterStatus> keyboardColors;
  final String? errorMessage;
  
  // Estatísticas do modo Infinito
  final int infiniteWins;
  final int infiniteLosses;
  final int infiniteStreak;

  const GameState({
    this.status = GameStatus.loading,
    this.mode = GameMode.daily,
    this.targetWordId = 0,
    this.targetWord = '',
    this.currentGuess = '',
    this.guesses = const [],
    this.keyboardColors = const {},
    this.errorMessage,
    this.infiniteWins = 0,
    this.infiniteLosses = 0,
    this.infiniteStreak = 0,
  });

  GameState copyWith({
    GameStatus? status,
    GameMode? mode,
    int? targetWordId,
    String? targetWord,
    String? currentGuess,
    List<GuessResult>? guesses,
    Map<String, LetterStatus>? keyboardColors,
    String? errorMessage,
    bool clearError = false,
    int? infiniteWins,
    int? infiniteLosses,
    int? infiniteStreak,
  }) {
    return GameState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      targetWordId: targetWordId ?? this.targetWordId,
      targetWord: targetWord ?? this.targetWord,
      currentGuess: currentGuess ?? this.currentGuess,
      guesses: guesses ?? this.guesses,
      keyboardColors: keyboardColors ?? this.keyboardColors,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infiniteWins: infiniteWins ?? this.infiniteWins,
      infiniteLosses: infiniteLosses ?? this.infiniteLosses,
      infiniteStreak: infiniteStreak ?? this.infiniteStreak,
    );
  }
}
