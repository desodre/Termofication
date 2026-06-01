import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/string_utils.dart';
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

  Future<void> warmUp() async {
    await repository.warmUp();
  }

  Future<void> startGame(GameMode mode) async {
    final boardCount = mode.wordCount;

    emit(
      state.copyWith(
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
        boardKeyboardColors: List.generate(
          boardCount,
          (_) => <String, LetterStatus>{},
        ),
        boardCompleted: List.generate(boardCount, (_) => false),
        newlyCorrectBoardIndices: const [],
        correctBoardNonce: 0,
        clearError: true,
        lastReplicatedIndices: const [],
        replicationNonce: 0,
      ),
    );

    try {
      if (mode.isDaily) {
        await _startDailyGame();
      } else {
        await _startInfiniteGame();
      }
    } catch (e, st) {
      log(
        'Erro ao iniciar jogo: $e',
        name: 'GameCubit',
        error: e,
        stackTrace: st,
      );
      emit(state.copyWith(status: GameStatus.error, errorMessage: 'Erro: $e'));
    }
  }

  Future<void> _startDailyGame() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedData = await repository.getDailyGame(mode: state.mode);

    if (savedData != null &&
        savedData['date'] == today &&
        (savedData['wordIds'] as List).isNotEmpty) {
      final List<int> wordIds = List<int>.from(savedData['wordIds'] as List);
      final List<String> targetWords = List<String>.from(
        savedData['targetWords'] as List? ?? const [],
      );
      final List<List<GuessResult>> boardGuesses = List<List<GuessResult>>.from(
        savedData['boardGuesses'] as List? ?? const [],
      );
      final List<bool> boardCompleted = List<bool>.from(
        savedData['boardCompleted'] as List? ?? const [],
      );
      final Map<String, LetterStatus> keyboardColors =
          Map<String, LetterStatus>.from(
            savedData['keyboardColors'] as Map? ?? const {},
          );
      final GameStatus status = savedData['status'] as GameStatus;

      final normalizedBoardGuesses = _normalizeBoardGuesses(
        wordIds.length,
        boardGuesses,
      );
      final normalizedBoardCompleted = _normalizeBoardCompleted(
        wordIds.length,
        boardCompleted,
        normalizedBoardGuesses,
      );
      final boardKeyboardColors = _rebuildAllBoardKeyboardColors(
        normalizedBoardGuesses,
      );
      final mergedKeyboard = keyboardColors.isNotEmpty
          ? keyboardColors
          : _mergeAllKeyboardColors(boardKeyboardColors);

      if (authCubit?.state is UserAuthAuthenticated) {
        try {
          await repository.syncStats(mode: state.mode);
        } catch (_) {}
      }
      final statsObj = await repository.getStats(mode: state.mode);

      emit(
        state.copyWith(
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
          newlyCorrectBoardIndices: const [],
          correctBoardNonce: 0,
          statsWins: statsObj.gamesWon,
          statsLosses: statsObj.gamesPlayed - statsObj.gamesWon,
          statsStreak: statsObj.currentStreak,
        ),
      );
      return;
    }

    try {
      final challenge = await repository.getDailyChallenge(mode: state.mode);
      final wordIds = challenge.wordIds.isNotEmpty
          ? challenge.wordIds.take(state.mode.wordCount).toList()
          : [challenge.wordId];

      final boardGuesses = List.generate(
        wordIds.length,
        (_) => <GuessResult>[],
      );
      final boardKeyboardColors = List.generate(
        wordIds.length,
        (_) => <String, LetterStatus>{},
      );
      final boardCompleted = List.generate(wordIds.length, (_) => false);

      if (authCubit?.state is UserAuthAuthenticated) {
        try {
          await repository.syncStats(mode: state.mode);
        } catch (_) {}
      }
      final statsObj = await repository.getStats(mode: state.mode);

      emit(
        state.copyWith(
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
          newlyCorrectBoardIndices: const [],
          correctBoardNonce: 0,
          statsWins: statsObj.gamesWon,
          statsLosses: statsObj.gamesPlayed - statsObj.gamesWon,
          statsStreak: statsObj.currentStreak,
        ),
      );
      await _saveDailyState();
    } catch (e, st) {
      log(
        'Erro ao iniciar jogo diário: $e',
        name: 'GameCubit',
        error: e,
        stackTrace: st,
      );
      emit(state.copyWith(status: GameStatus.error, errorMessage: 'Erro: $e'));
    }
  }

  Future<void> _startInfiniteGame() async {
    log('GameCubit: _startInfiniteGame() called', name: 'GameCubit');
    final challenge = await getRandomWordUseCase(length: wordLength);
    
    log('GameCubit: _startInfiniteGame: authCubit state = ${authCubit?.state}', name: 'GameCubit');
    if (authCubit?.state is UserAuthAuthenticated) {
      try {
        log('GameCubit: _startInfiniteGame: User authenticated. Calling syncStats...', name: 'GameCubit');
        await repository.syncStats(mode: GameMode.infinite);
        log('GameCubit: _startInfiniteGame: syncStats completed successfully.', name: 'GameCubit');
      } catch (e, st) {
        log('GameCubit: _startInfiniteGame: syncStats failed: $e', error: e, stackTrace: st, name: 'GameCubit');
        emit(state.copyWith(errorMessage: 'Aviso: Falha ao sincronizar estatísticas da nuvem.'));
      }
    } else {
      log('GameCubit: _startInfiniteGame: User not authenticated, skipping syncStats.', name: 'GameCubit');
    }
    
    final statsObj = await repository.getStats(mode: GameMode.infinite);

    emit(
      state.copyWith(
        status: GameStatus.playing,
        targetWordId: challenge.wordId,
        targetWordIds: [challenge.wordId],
        targetWord: '',
        targetWords: const [''],
        currentGuess: '',
        cursorIndex: 0,
        guesses: const [],
        boardGuesses: const <List<GuessResult>>[[]],
        statsWins: statsObj.gamesWon,
        statsLosses: statsObj.gamesPlayed - statsObj.gamesWon,
        statsStreak: statsObj.currentStreak,
        keyboardColors: const {},
        boardKeyboardColors: const <Map<String, LetterStatus>>[{}],
        boardCompleted: const [false],
        newlyCorrectBoardIndices: const [],
        correctBoardNonce: 0,
      ),
    );
  }

  void setCursor(int index) {
    if (state.status != GameStatus.playing) return;
    String newGuess = state.currentGuess;
    if (newGuess.length < wordLength) {
      newGuess = newGuess.padRight(wordLength, ' ');
    }
    emit(state.copyWith(
      currentGuess: newGuess,
      cursorIndex: index,
      lastReplicatedIndices: const [],
    ));
  }

  void addLetter(String letter) {
    if (state.status != GameStatus.playing) return;
    
    String padded = state.currentGuess.padRight(wordLength, ' ');
    
    // Evita sobrescrever a última letra acidentalmente se a palavra já estiver cheia
    // e o cursor estiver no final (comportamento clássico).
    if (state.cursorIndex == wordLength - 1 && padded[state.cursorIndex] != ' ' && !padded.contains(' ')) {
      return;
    }

    String newGuess = padded.substring(0, state.cursorIndex) + 
                      letter.toLowerCase() + 
                      padded.substring(state.cursorIndex + 1);
                      
    int nextCursor = state.cursorIndex;
    
    // 1. Search for the next empty cell to the right of the cursor
    int nextEmptyToRight = -1;
    for (int i = state.cursorIndex + 1; i < wordLength; i++) {
      if (newGuess[i] == ' ') {
        nextEmptyToRight = i;
        break;
      }
    }

    if (nextEmptyToRight != -1) {
      nextCursor = nextEmptyToRight;
    } else {
      // 2. If no empty cell is found to the right, search from the beginning of the row
      int nextEmptyFromStart = -1;
      for (int i = 0; i < state.cursorIndex; i++) {
        if (newGuess[i] == ' ') {
          nextEmptyFromStart = i;
          break;
        }
      }

      if (nextEmptyFromStart != -1) {
        nextCursor = nextEmptyFromStart;
      } else {
        // 3. If all cells are full, position the cursor at the end of the row
        if (nextCursor < wordLength - 1) {
          nextCursor = wordLength - 1;
        }
      }
    }
    
    emit(state.copyWith(
      currentGuess: newGuess.trimRight(), 
      cursorIndex: nextCursor,
      clearError: true,
      lastReplicatedIndices: const [],
    ));
  }

  void removeLetter() {
    if (state.status != GameStatus.playing) return;
    if (state.currentGuess.isEmpty) return;

    String padded = state.currentGuess.padRight(wordLength, ' ');
    int targetIndex = state.cursorIndex;
    
    if (padded[targetIndex] == ' ' && targetIndex > 0) {
      targetIndex--;
    }
    
    String newGuess = '${padded.substring(0, targetIndex)} ${padded.substring(targetIndex + 1)}';
                      
    if (newGuess.trim().isEmpty) {
       newGuess = '';
       targetIndex = 0;
    }
    
    emit(state.copyWith(
      currentGuess: newGuess.trimRight(), 
      cursorIndex: targetIndex,
      clearError: true,
      lastReplicatedIndices: const [],
    ));
  }

  Future<void> submitGuess() async {
    if (state.status != GameStatus.playing) return;
    final guessStr = state.currentGuess;
    if (guessStr.trim().length < wordLength || guessStr.contains(' ')) {
      emit(
        state.copyWith(
          errorMessage: 'Palavra incompleta. Digite $wordLength letras.',
        ),
      );
      return;
    }

    emit(state.copyWith(
      status: GameStatus.submitting,
      clearError: true,
      lastReplicatedIndices: const [],
    ));

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
          final wasCompleted =
              index < state.boardCompleted.length &&
              state.boardCompleted[index];
          if (!wasCompleted) {
            base.add(results[index]);
          }
          return base;
        },
      );

      final updatedBoardKeyboard = List<Map<String, LetterStatus>>.generate(
        targetWordIds.length,
        (index) {
          final base = index < state.boardKeyboardColors.length
              ? state.boardKeyboardColors[index]
              : const <String, LetterStatus>{};
          final wasCompleted =
              index < state.boardCompleted.length &&
              state.boardCompleted[index];
          if (!wasCompleted) {
            return _updateKeyboardColors(base, results[index]);
          }
          return base;
        },
      );

      final updatedKeyboard = _mergeAllKeyboardColors(updatedBoardKeyboard);
      final updatedBoardCompleted = List<bool>.generate(targetWordIds.length, (
        index,
      ) {
        final wasCompleted =
            index < state.boardCompleted.length && state.boardCompleted[index];
        return wasCompleted || results[index].isCorrect;
      });

      final List<int> newlyCorrectBoardIndices = [];
      for (int i = 0; i < targetWordIds.length; i++) {
        final wasCompleted = i < state.boardCompleted.length && state.boardCompleted[i];
        final isCompletedNow = updatedBoardCompleted[i];
        if (!wasCompleted && isCompletedNow) {
          newlyCorrectBoardIndices.add(i);
        }
      }
      final int correctBoardNonce = newlyCorrectBoardIndices.isNotEmpty
          ? state.correctBoardNonce + 1
          : state.correctBoardNonce;

      final attemptsUsed = updatedBoardGuesses.isNotEmpty
          ? updatedBoardGuesses.fold<int>(
              0,
              (max, list) => list.length > max ? list.length : max,
            )
          : 0;
      final attemptsLimit = maxAttemptsForMode(state.mode);
      final allBoardsCompleted =
          updatedBoardCompleted.isNotEmpty &&
          updatedBoardCompleted.every((b) => b);

      GameStatus nextStatus = GameStatus.playing;
      int wins = state.statsWins;
      int losses = state.statsLosses;
      int streak = state.statsStreak;
      List<String> revealedWords = List<String>.filled(
        targetWordIds.length,
        '',
        growable: false,
      );

      if (allBoardsCompleted) {
        nextStatus = GameStatus.won;
        for (var i = 0; i < targetWordIds.length; i++) {
          try {
            revealedWords[i] = await repository.revealWord(targetWordIds[i]);
          } catch (_) {
            revealedWords[i] = '';
          }
        }

        try {
          log('GameCubit: submitGuess (won): Calling recordGame(mode: ${state.mode.name}, won: true, attempts: $attemptsUsed)...', name: 'GameCubit');
          await repository.recordGame(
            mode: state.mode,
            won: true,
            attempts: attemptsUsed,
          );
          log('GameCubit: submitGuess (won): recordGame completed successfully.', name: 'GameCubit');
        } catch (e, st) {
          log('GameCubit: submitGuess (won): recordGame failed: $e', error: e, stackTrace: st, name: 'GameCubit');
          emit(state.copyWith(errorMessage: 'Aviso: Falha ao sincronizar estatísticas com a nuvem.'));
        }

        final statsObj = await repository.getStats(mode: state.mode);
        wins = statsObj.gamesWon;
        losses = statsObj.gamesPlayed - statsObj.gamesWon;
        streak = statsObj.currentStreak;
      } else if (attemptsUsed >= attemptsLimit) {
        nextStatus = GameStatus.lost;
        for (var i = 0; i < targetWordIds.length; i++) {
          try {
            revealedWords[i] = await repository.revealWord(targetWordIds[i]);
          } catch (_) {
            revealedWords[i] = '';
          }
        }

        try {
          log('GameCubit: submitGuess (lost): Calling recordGame(mode: ${state.mode.name}, won: false, attempts: $attemptsUsed)...', name: 'GameCubit');
          await repository.recordGame(
            mode: state.mode,
            won: false,
            attempts: attemptsUsed,
          );
          log('GameCubit: submitGuess (lost): recordGame completed successfully.', name: 'GameCubit');
        } catch (e, st) {
          log('GameCubit: submitGuess (lost): recordGame failed: $e', error: e, stackTrace: st, name: 'GameCubit');
          emit(state.copyWith(errorMessage: 'Aviso: Falha ao sincronizar estatísticas com a nuvem.'));
        }

        final statsObj = await repository.getStats(mode: state.mode);
        wins = statsObj.gamesWon;
        losses = statsObj.gamesPlayed - statsObj.gamesWon;
        streak = statsObj.currentStreak;
      }

      emit(
        state.copyWith(
          status: nextStatus,
          currentGuess: '',
          cursorIndex: 0,
          targetWord: revealedWords.isNotEmpty ? revealedWords.first : '',
          targetWords: revealedWords,
          guesses: updatedBoardGuesses.isNotEmpty
              ? updatedBoardGuesses.first
              : const <GuessResult>[],
          boardGuesses: updatedBoardGuesses,
          keyboardColors: updatedKeyboard,
          boardKeyboardColors: updatedBoardKeyboard,
          boardCompleted: updatedBoardCompleted,
          newlyCorrectBoardIndices: newlyCorrectBoardIndices,
          correctBoardNonce: correctBoardNonce,
          statsWins: wins,
          statsLosses: losses,
          statsStreak: streak,
          lastReplicatedIndices: const [],
        ),
      );

      if (state.mode.isDaily) {
        await _saveDailyState();
      }
    } on InvalidWordException catch (e) {
      emit(state.copyWith(status: GameStatus.playing, errorMessage: e.message));
    } on NetworkException catch (e) {
      emit(state.copyWith(status: GameStatus.playing, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          status: GameStatus.playing,
          errorMessage: 'Erro inesperado ao validar palpite.',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true, lastReplicatedIndices: const []));
  }

  void replicatePreviousGreenLetters(int boardIndex) {
    if (state.status != GameStatus.playing) return;
    if (boardIndex >= state.boardGuesses.length) return;

    final guesses = state.boardGuesses[boardIndex];
    if (guesses.isEmpty) return; // Nenhuma tentativa anterior neste tabuleiro

    final lastGuess = guesses.last;
    
    // Garantir que a palavra atual tenha tamanho correto para manipulação
    String padded = state.currentGuess.padRight(wordLength, ' ');
    List<String> chars = padded.split('');
    List<int> replicatedIndices = [];

    for (int i = 0; i < wordLength; i++) {
      if (lastGuess.feedback[i].status == LetterStatus.correct) {
        final greenLetter = lastGuess.feedback[i].letter;
        if (chars[i] != greenLetter) {
          chars[i] = greenLetter;
          replicatedIndices.add(i);
        }
      }
    }

    if (replicatedIndices.isNotEmpty) {
      String newGuess = chars.join('');
      
      // Mover cursor inteligentemente para a próxima célula vazia
      int nextCursor = state.cursorIndex;
      // Se a posição atual do cursor foi preenchida, encontra a próxima vazia à direita, senão à esquerda
      if (newGuess[nextCursor] != ' ') {
        int nextEmpty = -1;
        for (int i = nextCursor + 1; i < wordLength; i++) {
          if (newGuess[i] == ' ') {
            nextEmpty = i;
            break;
          }
        }
        if (nextEmpty == -1) {
          for (int i = 0; i < nextCursor; i++) {
            if (newGuess[i] == ' ') {
              nextEmpty = i;
              break;
            }
          }
        }
        if (nextEmpty != -1) {
          nextCursor = nextEmpty;
        } else {
          // Se não há posições vazias, posiciona o cursor na última célula
          nextCursor = wordLength - 1;
        }
      }

      emit(state.copyWith(
        currentGuess: newGuess.trimRight(),
        cursorIndex: nextCursor,
        lastReplicatedIndices: replicatedIndices,
        replicationNonce: state.replicationNonce + 1,
        clearError: true,
      ));
    }
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
      final normalizedLetter = normalizePortuguese(fb.letter).toUpperCase();
      final current = updated[normalizedLetter];
      if (current == LetterStatus.correct) continue;
      if (current == LetterStatus.present && fb.status == LetterStatus.absent) {
        continue;
      }
      updated[normalizedLetter] = fb.status;
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
      final guesses = idx < boardGuesses.length
          ? boardGuesses[idx]
          : const <GuessResult>[];
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
