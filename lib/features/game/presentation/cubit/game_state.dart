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
  final List<int> newlyCorrectBoardIndices;
  final int correctBoardNonce;

  // Estatísticas do modo de jogo atual
  final int statsWins;
  final int statsLosses;
  final int statsStreak;

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
    this.newlyCorrectBoardIndices = const [],
    this.correctBoardNonce = 0,
    this.statsWins = 0,
    this.statsLosses = 0,
    this.statsStreak = 0,
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
    List<int>? newlyCorrectBoardIndices,
    int? correctBoardNonce,
    int? statsWins,
    int? statsLosses,
    int? statsStreak,
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
      newlyCorrectBoardIndices: newlyCorrectBoardIndices ?? this.newlyCorrectBoardIndices,
      correctBoardNonce: correctBoardNonce ?? this.correctBoardNonce,
      statsWins: statsWins ?? this.statsWins,
      statsLosses: statsLosses ?? this.statsLosses,
      statsStreak: statsStreak ?? this.statsStreak,
    );
  }
}
