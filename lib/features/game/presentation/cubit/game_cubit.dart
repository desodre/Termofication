import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/game_enums.dart';
import '../../domain/entities/guess_result.dart';
import '../../domain/usecases/get_random_word_usecase.dart';
import '../../domain/usecases/submit_guess_usecase.dart';
import '../../domain/repositories/game_repository.dart';
import 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final SubmitGuessUseCase submitGuessUseCase;
  final GetRandomWordUseCase getRandomWordUseCase;
  final GameRepository repository;
  final AuthCubit? authCubit;

  static const int maxAttempts = 6;
  static const int wordLength = 5;

  static int maxAttemptsForMode(GameMode mode) {
    switch (mode) {
      case GameMode.dailyDueto:
        return 7;
      case GameMode.dailyQuarteto:
        return 9;
      case GameMode.daily:
      case GameMode.infinite:
        return maxAttempts;
    }
  }

  GameCubit({
    required this.submitGuessUseCase,
    required this.getRandomWordUseCase,
    required this.repository,
    this.authCubit,
  }) : super(const GameState());

  Future<void> startGame(GameMode mode) async {
    final boardCount = mode.wordCount;

    emit(state.copyWith(
      status: GameStatus.loading,
      mode: mode,
      targetWordId: 0,
      targetWordIds: const [],
      targetWord: '',
      targetWords: const [],
      currentGuess: '',
      guesses: [],
      boardGuesses: List.generate(boardCount, (_) => <GuessResult>[]),
      keyboardColors: {},
      boardKeyboardColors:
          List.generate(boardCount, (_) => <String, LetterStatus>{}),
      boardCompleted: List.generate(boardCount, (_) => false),
      clearError: true,
    ));

    try {
      if (mode.isDaily) {
        await _startDailyGame();
      } else {
        await _startInfiniteGame();
      }
    } catch (e, st) {
      print(e);
      print(st);
      emit(state.copyWith(
        status: GameStatus.error,
        errorMessage: 'Erro: $e',
      ));
    }
  }

  Future<void> _startDailyGame() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedData = await repository.getDailyGame(mode: state.mode);

    if (savedData != null &&
        savedData['date'] == today &&
        (savedData['wordIds'] as List).isNotEmpty) {
      final List<int> wordIds = List<int>.from(savedData['wordIds'] as List);
      final List<String> targetWords =
          List<String>.from(savedData['targetWords'] as List? ?? const []);
      final List<List<GuessResult>> boardGuesses =
          List<List<GuessResult>>.from(savedData['boardGuesses'] as List? ?? const []);
      final List<bool> boardCompleted =
          List<bool>.from(savedData['boardCompleted'] as List? ?? const []);
      final Map<String, LetterStatus> keyboardColors =
          Map<String, LetterStatus>.from(savedData['keyboardColors'] as Map? ?? const {});
      final GameStatus status = savedData['status'] as GameStatus;

      final normalizedBoardGuesses = _normalizeBoardGuesses(wordIds.length, boardGuesses);
      final normalizedBoardCompleted = _normalizeBoardCompleted(
        wordIds.length,
        boardCompleted,
        normalizedBoardGuesses,
      );
      final boardKeyboardColors = _rebuildAllBoardKeyboardColors(normalizedBoardGuesses);
      final mergedKeyboard = keyboardColors.isNotEmpty
          ? keyboardColors
          : _mergeAllKeyboardColors(boardKeyboardColors);

      emit(state.copyWith(
        status: status,
        targetWordId: wordIds.first,
        targetWordIds: wordIds,
        targetWord: targetWords.isNotEmpty ? targetWords.first : '',
        targetWords: targetWords,
        guesses: normalizedBoardGuesses.first,
        boardGuesses: normalizedBoardGuesses,
        keyboardColors: mergedKeyboard,
        boardKeyboardColors: boardKeyboardColors,
        boardCompleted: normalizedBoardCompleted,
      ));
      return;
    }

    try {
      final challenge = await repository.getDailyChallenge(mode: state.mode);
      final wordIds = challenge.wordIds.isNotEmpty
          ? challenge.wordIds.take(state.mode.wordCount).toList()
          : [challenge.wordId];

      final boardGuesses = List.generate(wordIds.length, (_) => <GuessResult>[]);
      final boardKeyboardColors =
          List.generate(wordIds.length, (_) => <String, LetterStatus>{});
      final boardCompleted = List.generate(wordIds.length, (_) => false);

      emit(state.copyWith(
        status: GameStatus.playing,
        targetWordId: wordIds.first,
        targetWordIds: wordIds,
        targetWord: '',
        targetWords: List.generate(wordIds.length, (_) => ''),
        guesses: boardGuesses.first,
        boardGuesses: boardGuesses,
        keyboardColors: {},
        boardKeyboardColors: boardKeyboardColors,
        boardCompleted: boardCompleted,
      ));
      await _saveDailyState();
    } catch (e, st) {
      print(e);
      print(st);
      emit(state.copyWith(
        status: GameStatus.error,
        errorMessage: 'Erro: $e',
      ));
    }
  }

  Future<void> _startInfiniteGame() async {
    final challenge = await getRandomWordUseCase(length: wordLength);
    final stats = await repository.getInfiniteStats();

    emit(state.copyWith(
      status: GameStatus.playing,
      targetWordId: challenge.wordId,
      targetWordIds: [challenge.wordId],
      targetWord: '',
      targetWords: const [''],
      guesses: const [],
      boardGuesses: const <List<GuessResult>>[[]],
      infiniteWins: stats['wins'] ?? 0,
      infiniteLosses: stats['losses'] ?? 0,
      infiniteStreak: stats['streak'] ?? 0,
      keyboardColors: const {},
      boardKeyboardColors: const <Map<String, LetterStatus>>[{}],
      boardCompleted: const [false],
    ));
  }

  void addLetter(String letter) {
    if (state.status != GameStatus.playing) return;
    if (state.currentGuess.length >= wordLength) return;
    
    final newGuess = state.currentGuess + letter.toLowerCase();
    emit(state.copyWith(
      currentGuess: newGuess,
      clearError: true,
    ));
  }

  void removeLetter() {
    if (state.status != GameStatus.playing) return;
    if (state.currentGuess.isEmpty) return;
    
    final newGuess = state.currentGuess.substring(0, state.currentGuess.length - 1);
    emit(state.copyWith(
      currentGuess: newGuess,
      clearError: true,
    ));
  }

  Future<void> submitGuess() async {
    if (state.status != GameStatus.playing) return;
    if (state.currentGuess.length < wordLength) {
      emit(state.copyWith(errorMessage: 'Palavra incompleta. Digite $wordLength letras.'));
      return;
    }

    emit(state.copyWith(status: GameStatus.submitting, clearError: true));

    try {
      final targetWordIds = state.targetWordIds.isNotEmpty
          ? state.targetWordIds
          : [state.targetWordId];

      final results = await Future.wait(
        targetWordIds.map(
          (wordId) => submitGuessUseCase(state.currentGuess, wordId),
        ),
      );

      final updatedBoardGuesses = List<List<GuessResult>>.generate(
        targetWordIds.length,
        (index) {
          final base = index < state.boardGuesses.length
              ? List<GuessResult>.from(state.boardGuesses[index])
              : <GuessResult>[];
          base.add(results[index]);
          return base;
        },
      );

      final updatedBoardKeyboard = List<Map<String, LetterStatus>>.generate(
        targetWordIds.length,
        (index) {
          final base = index < state.boardKeyboardColors.length
              ? state.boardKeyboardColors[index]
              : const <String, LetterStatus>{};
          return _updateKeyboardColors(base, results[index]);
        },
      );

      final updatedKeyboard = _mergeAllKeyboardColors(updatedBoardKeyboard);
      final updatedBoardCompleted = List<bool>.generate(
        targetWordIds.length,
        (index) {
          final wasCompleted =
              index < state.boardCompleted.length && state.boardCompleted[index];
          return wasCompleted || results[index].isCorrect;
        },
      );

      final attemptsUsed =
          updatedBoardGuesses.isNotEmpty ? updatedBoardGuesses.first.length : 0;
      final attemptsLimit = maxAttemptsForMode(state.mode);
      final allBoardsCompleted =
          updatedBoardCompleted.isNotEmpty && updatedBoardCompleted.every((b) => b);

      GameStatus nextStatus = GameStatus.playing;
      int wins = state.infiniteWins;
      int losses = state.infiniteLosses;
      int streak = state.infiniteStreak;
      List<String> revealedWords =
          List<String>.filled(targetWordIds.length, '', growable: false);

      if (allBoardsCompleted) {
        nextStatus = GameStatus.won;
        for (var i = 0; i < targetWordIds.length; i++) {
          try {
            revealedWords[i] = await repository.revealWord(targetWordIds[i]);
          } catch (_) {
            revealedWords[i] = '';
          }
        }

        if (state.mode == GameMode.infinite) {
          wins++;
          streak++;
          await repository.saveInfiniteStats(wins: wins, losses: losses, streak: streak);

          final authState = authCubit?.state;
          if (authState is UserAuthAuthenticated) {
            await repository.recordGame(
              won: true,
              attempts: attemptsUsed,
              accessToken: authState.accessToken,
            );
          }
        }
      } else if (attemptsUsed >= attemptsLimit) {
        nextStatus = GameStatus.lost;
        for (var i = 0; i < targetWordIds.length; i++) {
          try {
            revealedWords[i] = await repository.revealWord(targetWordIds[i]);
          } catch (_) {
            revealedWords[i] = '';
          }
        }

        if (state.mode == GameMode.infinite) {
          losses++;
          streak = 0;
          await repository.saveInfiniteStats(wins: wins, losses: losses, streak: streak);

          final authState = authCubit?.state;
          if (authState is UserAuthAuthenticated) {
            await repository.recordGame(
              won: false,
              attempts: attemptsUsed,
              accessToken: authState.accessToken,
            );
          }
        }
      }

      emit(state.copyWith(
        status: nextStatus,
        currentGuess: '',
        targetWord: revealedWords.isNotEmpty ? revealedWords.first : '',
        targetWords: revealedWords,
        guesses: updatedBoardGuesses.isNotEmpty
            ? updatedBoardGuesses.first
            : const <GuessResult>[],
        boardGuesses: updatedBoardGuesses,
        keyboardColors: updatedKeyboard,
        boardKeyboardColors: updatedBoardKeyboard,
        boardCompleted: updatedBoardCompleted,
        infiniteWins: wins,
        infiniteLosses: losses,
        infiniteStreak: streak,
      ));

      if (state.mode.isDaily) {
        await _saveDailyState();
      }
    } on InvalidWordException catch (e) {
      emit(state.copyWith(
        status: GameStatus.playing,
        errorMessage: e.message,
      ));
    } on NetworkException catch (e) {
      emit(state.copyWith(
        status: GameStatus.playing,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GameStatus.playing,
        errorMessage: 'Erro inesperado ao validar palpite.',
      ));
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  Future<void> _saveDailyState() async {
    if (!state.mode.isDaily) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await repository.saveDailyGame(
      mode: state.mode,
      date: today,
      wordIds: state.targetWordIds.isNotEmpty
          ? state.targetWordIds
          : [state.targetWordId],
      targetWords: state.targetWords,
      boardGuesses: state.boardGuesses.isNotEmpty
          ? state.boardGuesses
          : [state.guesses],
      boardCompleted: state.boardCompleted.isNotEmpty
          ? state.boardCompleted
          : [state.status == GameStatus.won],
      status: state.status,
      keyboardColors: state.keyboardColors,
    );
  }

  Map<String, LetterStatus> _updateKeyboardColors(
    Map<String, LetterStatus> currentColors,
    GuessResult newResult,
  ) {
    final Map<String, LetterStatus> updated = Map.from(currentColors);
    
    for (final fb in newResult.feedback) {
      final current = updated[fb.letter];
      if (current == LetterStatus.correct) continue;
      if (current == LetterStatus.present && fb.status == LetterStatus.absent) {
        continue;
      }
      updated[fb.letter] = fb.status;
    }
    
    return updated;
  }

  Map<String, LetterStatus> _rebuildKeyboardColors(List<GuessResult> guesses) {
    Map<String, LetterStatus> colors = {};
    for (final g in guesses) {
      colors = _updateKeyboardColors(colors, g);
    }
    return colors;
  }

  List<List<GuessResult>> _normalizeBoardGuesses(
    int expectedBoards,
    List<List<GuessResult>> boardGuesses,
  ) {
    final normalized = List<List<GuessResult>>.from(boardGuesses);
    while (normalized.length < expectedBoards) {
      normalized.add(<GuessResult>[]);
    }
    if (normalized.length > expectedBoards) {
      return normalized.sublist(0, expectedBoards);
    }
    return normalized;
  }

  List<bool> _normalizeBoardCompleted(
    int expectedBoards,
    List<bool> boardCompleted,
    List<List<GuessResult>> boardGuesses,
  ) {
    final normalized = List<bool>.from(boardCompleted);
    while (normalized.length < expectedBoards) {
      final idx = normalized.length;
      final guesses = idx < boardGuesses.length ? boardGuesses[idx] : const <GuessResult>[];
      normalized.add(guesses.any((g) => g.isCorrect));
    }
    if (normalized.length > expectedBoards) {
      return normalized.sublist(0, expectedBoards);
    }
    return normalized;
  }

  List<Map<String, LetterStatus>> _rebuildAllBoardKeyboardColors(
    List<List<GuessResult>> boardGuesses,
  ) {
    return boardGuesses.map(_rebuildKeyboardColors).toList();
  }

  Map<String, LetterStatus> _mergeAllKeyboardColors(
    List<Map<String, LetterStatus>> boardKeyboardColors,
  ) {
    final merged = <String, LetterStatus>{};
    for (final boardColors in boardKeyboardColors) {
      for (final entry in boardColors.entries) {
        final current = merged[entry.key] ?? LetterStatus.unknown;
        if (_priority(entry.value) > _priority(current)) {
          merged[entry.key] = entry.value;
        }
      }
    }
    return merged;
  }

  int _priority(LetterStatus status) {
    switch (status) {
      case LetterStatus.correct:
        return 3;
      case LetterStatus.present:
        return 2;
      case LetterStatus.absent:
        return 1;
      case LetterStatus.unknown:
        return 0;
    }
  }
}
