import '../../domain/entities/game_enums.dart';
import '../../domain/entities/guess_result.dart';

class GameState {
  final GameStatus status;
  final GameMode mode;
  final int targetWordId;
  final List<int> targetWordIds;
  final String targetWord;
  final List<String> targetWords;
  final String currentGuess;
  final int cursorIndex;
  final List<GuessResult> guesses;
  final List<List<GuessResult>> boardGuesses;
  final Map<String, LetterStatus> keyboardColors;
  final List<Map<String, LetterStatus>> boardKeyboardColors;
  final List<bool> boardCompleted;
  final String? errorMessage;

  // Estatísticas do modo Infinito
  final int infiniteWins;
  final int infiniteLosses;
  final int infiniteStreak;

  const GameState({
    this.status = GameStatus.loading,
    this.mode = GameMode.daily,
    this.targetWordId = 0,
    this.targetWordIds = const [],
    this.targetWord = '',
    this.targetWords = const [],
    this.currentGuess = '',
    this.cursorIndex = 0,
    this.guesses = const [],
    this.boardGuesses = const [],
    this.keyboardColors = const {},
    this.boardKeyboardColors = const [],
    this.boardCompleted = const [],
    this.errorMessage,
    this.infiniteWins = 0,
    this.infiniteLosses = 0,
    this.infiniteStreak = 0,
  });

  GameState copyWith({
    GameStatus? status,
    GameMode? mode,
    int? targetWordId,
    List<int>? targetWordIds,
    String? targetWord,
    List<String>? targetWords,
    String? currentGuess,
    int? cursorIndex,
    List<GuessResult>? guesses,
    List<List<GuessResult>>? boardGuesses,
    Map<String, LetterStatus>? keyboardColors,
    List<Map<String, LetterStatus>>? boardKeyboardColors,
    List<bool>? boardCompleted,
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
      targetWordIds: targetWordIds ?? this.targetWordIds,
      targetWord: targetWord ?? this.targetWord,
      targetWords: targetWords ?? this.targetWords,
      currentGuess: currentGuess ?? this.currentGuess,
      cursorIndex: cursorIndex ?? this.cursorIndex,
      guesses: guesses ?? this.guesses,
      boardGuesses: boardGuesses ?? this.boardGuesses,
      keyboardColors: keyboardColors ?? this.keyboardColors,
      boardKeyboardColors: boardKeyboardColors ?? this.boardKeyboardColors,
      boardCompleted: boardCompleted ?? this.boardCompleted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infiniteWins: infiniteWins ?? this.infiniteWins,
      infiniteLosses: infiniteLosses ?? this.infiniteLosses,
      infiniteStreak: infiniteStreak ?? this.infiniteStreak,
    );
  }
}
