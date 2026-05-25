import 'package:flutter_test/flutter_test.dart';
import 'package:termofication_app/features/game/domain/entities/challenge.dart';
import 'package:termofication_app/features/game/domain/entities/game_enums.dart';
import 'package:termofication_app/features/game/domain/entities/guess_result.dart';
import 'package:termofication_app/features/game/domain/entities/letter_feedback.dart';
import 'package:termofication_app/features/game/domain/repositories/game_repository.dart';
import 'package:termofication_app/features/game/domain/usecases/get_random_word_usecase.dart';
import 'package:termofication_app/features/game/domain/usecases/submit_guess_usecase.dart';
import 'package:termofication_app/features/game/presentation/cubit/game_cubit.dart';

class MockGameRepository implements GameRepository {
  final Map<int, String> _words = {1: 'termo', 2: 'carta'};

  int nextWordId = 1;
  GuessResult? submitGuessResult;

  final Map<GameMode, Map<String, dynamic>> dailyGameData = {};
  Map<String, int> infiniteStatsData = {'wins': 0, 'losses': 0, 'streak': 0};

  @override
  Future<Challenge> getDailyChallenge({GameMode mode = GameMode.daily}) async {
    return const Challenge(wordId: 1, length: 5);
  }

  @override
  Future<Challenge> getRandomChallenge({int length = 5}) async {
    return Challenge(wordId: nextWordId, length: length);
  }

  @override
  Future<String> revealWord(int wordId) async {
    return _words[wordId] ?? 'termo';
  }

  @override
  Future<GuessResult> submitGuess(String guess, int wordId) async {
    if (submitGuessResult != null) return submitGuessResult!;

    final target = _words[wordId] ?? 'termo';
    final isCorrect = guess == target;
    return GuessResult(
      guess: guess,
      isCorrect: isCorrect,
      feedback: List.generate(
        guess.length,
        (i) => LetterFeedback(
          letter: guess[i],
          status: guess[i] == target[i]
              ? LetterStatus.correct
              : (target.contains(guess[i])
                    ? LetterStatus.present
                    : LetterStatus.absent),
        ),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>?> getDailyGame({required GameMode mode}) async =>
      dailyGameData[mode];

  @override
  Future<void> saveDailyGame({
    required GameMode mode,
    required String date,
    required List<int> wordIds,
    required List<String> targetWords,
    required List<List<GuessResult>> boardGuesses,
    required List<bool> boardCompleted,
    required GameStatus status,
    required Map<String, LetterStatus> keyboardColors,
  }) async {
    dailyGameData[mode] = {
      'date': date,
      'wordIds': wordIds,
      'targetWords': targetWords,
      'boardGuesses': boardGuesses,
      'boardCompleted': boardCompleted,
      'keyboardColors': keyboardColors,
      'status': status,
    };
  }

  @override
  Future<Map<String, int>> getInfiniteStats() async => infiniteStatsData;

  @override
  Future<void> saveInfiniteStats({
    required int wins,
    required int losses,
    required int streak,
  }) async {
    infiniteStatsData = {'wins': wins, 'losses': losses, 'streak': streak};
  }

  @override
  Future<void> recordGame({
    required bool won,
    required int attempts,
    required String accessToken,
  }) {
    // TODO: implement recordGame
    throw UnimplementedError();
  }
}

void main() {
  late GameCubit cubit;
  late MockGameRepository mockRepository;
  late SubmitGuessUseCase submitGuessUseCase;
  late GetRandomWordUseCase getRandomWordUseCase;

  setUp(() {
    mockRepository = MockGameRepository();
    submitGuessUseCase = SubmitGuessUseCase(mockRepository);
    getRandomWordUseCase = GetRandomWordUseCase(mockRepository);
    cubit = GameCubit(
      submitGuessUseCase: submitGuessUseCase,
      getRandomWordUseCase: getRandomWordUseCase,
      repository: mockRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('GameCubit Lógica de Jogo', () {
    test('deve inicializar com o estado inicial padrão', () {
      expect(cubit.state.status, GameStatus.loading);
      expect(cubit.state.currentGuess, isEmpty);
      expect(cubit.state.guesses, isEmpty);
    });

    test('deve carregar jogo infinito com palavra-alvo sorteada', () async {
      mockRepository.nextWordId = 2; // Maps to 'carta'

      await cubit.startGame(GameMode.infinite);

      expect(cubit.state.status, GameStatus.playing);
      expect(cubit.state.targetWordId, 2);
      expect(
        cubit.state.targetWord,
        isEmpty,
      ); // Target word must not leak during play!
      expect(cubit.state.mode, GameMode.infinite);
    });

    test('deve adicionar letras até o limite da palavra', () async {
      await cubit.startGame(GameMode.infinite);

      cubit.addLetter('C');
      cubit.addLetter('a');
      cubit.addLetter('r');
      cubit.addLetter('r');
      cubit.addLetter('o');
      cubit.addLetter('s'); // Letra extra, deve ignorar

      expect(cubit.state.currentGuess, 'carro');
    });

    test('deve remover a última letra digitada', () async {
      await cubit.startGame(GameMode.infinite);

      cubit.addLetter('a');
      cubit.addLetter('m');
      cubit.addLetter('o');
      cubit.removeLetter();

      expect(cubit.state.currentGuess, 'am');
    });

    test('deve submeter palpite correto e vencer o jogo', () async {
      mockRepository.nextWordId = 1; // Maps to 'termo'
      await cubit.startGame(GameMode.infinite);

      cubit.addLetter('t');
      cubit.addLetter('e');
      cubit.addLetter('r');
      cubit.addLetter('m');
      cubit.addLetter('o');

      await cubit.submitGuess();

      expect(cubit.state.status, GameStatus.won);
      expect(cubit.state.guesses.length, 1);
      expect(cubit.state.guesses.first.isCorrect, isTrue);
      expect(cubit.state.targetWord, 'termo'); // Correct word revealed on win!
      expect(cubit.state.infiniteWins, 1);
      expect(cubit.state.infiniteStreak, 1);
    });

    test('deve perder o jogo após atingir limite de palpites', () async {
      mockRepository.nextWordId = 1; // Maps to 'termo'
      await cubit.startGame(GameMode.infinite);

      // Submete 6 palpites errados
      for (int i = 0; i < 6; i++) {
        cubit.addLetter('f');
        cubit.addLetter('a');
        cubit.addLetter('l');
        cubit.addLetter('h');
        cubit.addLetter('a');
        await cubit.submitGuess();
      }

      expect(cubit.state.status, GameStatus.lost);
      expect(cubit.state.guesses.length, 6);
      expect(cubit.state.targetWord, 'termo'); // Correct word revealed on loss!
      expect(cubit.state.infiniteLosses, 1);
      expect(cubit.state.infiniteStreak, 0);
    });
  });
}
