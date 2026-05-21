import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
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

  static const int maxAttempts = 6;
  static const int wordLength = 5;

  GameCubit({
    required this.submitGuessUseCase,
    required this.getRandomWordUseCase,
    required this.repository,
  }) : super(const GameState());

  Future<void> startGame(GameMode mode) async {
    emit(state.copyWith(
      status: GameStatus.loading,
      mode: mode,
      currentGuess: '',
      guesses: [],
      keyboardColors: {},
      clearError: true,
    ));

    try {
      if (mode == GameMode.daily) {
        await _startDailyGame();
      } else {
        await _startInfiniteGame();
      }
    } catch (e) {
      emit(state.copyWith(
        status: GameStatus.error,
        errorMessage: 'Falha ao conectar ao servidor. Tente jogar mais tarde.',
      ));
    }
  }

  Future<void> _startDailyGame() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedData = await repository.getDailyGame();

    if (savedData != null && savedData['date'] == today) {
      final int wordId = savedData['wordId'] as int;
      final String word = savedData['word'] as String;
      final List<GuessResult> guesses = savedData['guesses'] as List<GuessResult>;
      final GameStatus status = savedData['status'] as GameStatus;
      
      final keyboardColors = _rebuildKeyboardColors(guesses);
      
      emit(state.copyWith(
        status: status,
        targetWordId: wordId,
        targetWord: word,
        guesses: guesses,
        keyboardColors: keyboardColors,
      ));
    } else {
      try {
        final challenge = await repository.getDailyChallenge();
        emit(state.copyWith(
          status: GameStatus.playing,
          targetWordId: challenge.wordId,
          targetWord: '',
        ));
        await _saveDailyState();
      } catch (e) {
        emit(state.copyWith(
          status: GameStatus.error,
          errorMessage: 'Falha ao conectar ao servidor. Tente jogar mais tarde.',
        ));
      }
    }
  }

  Future<void> _startInfiniteGame() async {
    final challenge = await getRandomWordUseCase(length: wordLength);
    final stats = await repository.getInfiniteStats();
    
    emit(state.copyWith(
      status: GameStatus.playing,
      targetWordId: challenge.wordId,
      targetWord: '',
      infiniteWins: stats['wins'] ?? 0,
      infiniteLosses: stats['losses'] ?? 0,
      infiniteStreak: stats['streak'] ?? 0,
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
      final result = await submitGuessUseCase(state.currentGuess, state.targetWordId);
      
      final updatedGuesses = List<GuessResult>.from(state.guesses)..add(result);
      final updatedKeyboard = _updateKeyboardColors(state.keyboardColors, result);
      
      GameStatus nextStatus = GameStatus.playing;
      int wins = state.infiniteWins;
      int losses = state.infiniteLosses;
      int streak = state.infiniteStreak;
      String revealedWord = '';

      if (result.isCorrect) {
        nextStatus = GameStatus.won;
        try {
          revealedWord = await repository.revealWord(state.targetWordId);
        } catch (_) {
          revealedWord = state.currentGuess;
        }
        if (state.mode == GameMode.infinite) {
          wins++;
          streak++;
          await repository.saveInfiniteStats(wins: wins, losses: losses, streak: streak);
        }
      } else if (updatedGuesses.length >= maxAttempts) {
        nextStatus = GameStatus.lost;
        try {
          revealedWord = await repository.revealWord(state.targetWordId);
        } catch (_) {
          revealedWord = '';
        }
        if (state.mode == GameMode.infinite) {
          losses++;
          streak = 0;
          await repository.saveInfiniteStats(wins: wins, losses: losses, streak: streak);
        }
      }

      emit(state.copyWith(
        status: nextStatus,
        currentGuess: '',
        targetWord: revealedWord,
        guesses: updatedGuesses,
        keyboardColors: updatedKeyboard,
        infiniteWins: wins,
        infiniteLosses: losses,
        infiniteStreak: streak,
      ));

      if (state.mode == GameMode.daily) {
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
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await repository.saveDailyGame(
      date: today,
      wordId: state.targetWordId,
      word: state.targetWord,
      guesses: state.guesses,
      status: state.status,
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
}
