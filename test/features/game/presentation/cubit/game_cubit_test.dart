import 'package:flutter_test/flutter_test.dart';
import 'package:termofication_app/features/game/domain/entities/challenge.dart';
import 'package:termofication_app/features/game/domain/entities/game_enums.dart';
import 'package:termofication_app/features/game/domain/entities/guess_result.dart';
import 'package:termofication_app/features/game/domain/entities/letter_feedback.dart';
import 'package:termofication_app/features/game/domain/entities/game_stats.dart';
import 'package:termofication_app/features/game/domain/repositories/game_repository.dart';
import 'package:termofication_app/features/game/domain/usecases/get_random_word_usecase.dart';
import 'package:termofication_app/features/game/domain/usecases/submit_guess_usecase.dart';
import 'package:termofication_app/features/game/presentation/cubit/game_cubit.dart';

class MockGameRepository implements GameRepository {
  final Map<int, String> _words = {1: 'termo', 2: 'carta'};

  int nextWordId = 1;
  GuessResult? submitGuessResult;

  final Map<GameMode, Map<String, dynamic>> dailyGameData = {};
  final Map<GameMode, GameStats> mockStats = {};

  @override
  Future<Challenge> getDailyChallenge({GameMode mode = GameMode.daily}) async {
    return const Challenge(wordId: 1, length: 5);
  }

  @override
  Future<void> warmUp() async {}

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
  Future<GameStats> getStats({required GameMode mode}) async {
    return mockStats[mode] ?? GameStats.empty();
  }

  @override
  Future<void> saveStats({
    required GameMode mode,
    required GameStats stats,
  }) async {
    mockStats[mode] = stats;
  }

  @override
  Future<void> syncStats({required GameMode mode}) async {
    // Apenas simula sucesso
  }

  @override
  Future<void> recordGame({
    required GameMode mode,
    required bool won,
    required int attempts,
  }) async {
    final current = await getStats(mode: mode);
    final guessDist = Map<int, int>.from(current.guessDistribution);
    if (won) {
      guessDist[attempts] = (guessDist[attempts] ?? 0) + 1;
    }
    final updated = GameStats(
      gamesPlayed: current.gamesPlayed + 1,
      gamesWon: current.gamesWon + (won ? 1 : 0),
      currentStreak: won ? current.currentStreak + 1 : 0,
      maxStreak: won ? (current.currentStreak + 1 > current.maxStreak ? current.currentStreak + 1 : current.maxStreak) : current.maxStreak,
      guessDistribution: guessDist,
    );
    await saveStats(mode: mode, stats: updated);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
      expect(cubit.state.statsWins, 1);
      expect(cubit.state.statsStreak, 1);
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
      expect(cubit.state.statsLosses, 1);
      expect(cubit.state.statsStreak, 0);
    });

    test('deve mapear feedback com letras acentuadas para a tecla base correspondente no teclado virtual', () async {
      mockRepository.nextWordId = 1;
      await cubit.startGame(GameMode.infinite);

      // Simula feedback contendo 'É' acentuado
      mockRepository.submitGuessResult = const GuessResult(
        guess: 'ébano',
        isCorrect: false,
        feedback: [
          LetterFeedback(letter: 'É', status: LetterStatus.correct),
          LetterFeedback(letter: 'B', status: LetterStatus.absent),
          LetterFeedback(letter: 'A', status: LetterStatus.absent),
          LetterFeedback(letter: 'N', status: LetterStatus.absent),
          LetterFeedback(letter: 'O', status: LetterStatus.absent),
        ],
      );

      cubit.addLetter('e');
      cubit.addLetter('b');
      cubit.addLetter('a');
      cubit.addLetter('n');
      cubit.addLetter('o');

      await cubit.submitGuess();

      // A tecla base 'E' deve receber o status corretor, e não a acentuada 'É'
      expect(cubit.state.keyboardColors['E'], LetterStatus.correct);
      expect(cubit.state.keyboardColors['É'], isNull);
    });

    test('deve atualizar newlyCorrectBoardIndices e correctBoardNonce ao acertar a palavra, e resetá-los ao iniciar um novo jogo', () async {
      mockRepository.nextWordId = 1; // Maps to 'termo'
      await cubit.startGame(GameMode.infinite);

      expect(cubit.state.newlyCorrectBoardIndices, isEmpty);
      expect(cubit.state.correctBoardNonce, 0);

      cubit.addLetter('t');
      cubit.addLetter('e');
      cubit.addLetter('r');
      cubit.addLetter('m');
      cubit.addLetter('o');

      await cubit.submitGuess();

      expect(cubit.state.newlyCorrectBoardIndices, contains(0));
      expect(cubit.state.correctBoardNonce, 1);

      // Start new game should reset them
      await cubit.startGame(GameMode.infinite);

      expect(cubit.state.newlyCorrectBoardIndices, isEmpty);
      expect(cubit.state.correctBoardNonce, 0);
    });

    test('deve navegar para a próxima célula vazia ao digitar com seleção manual', () async {
      mockRepository.nextWordId = 1;
      await cubit.startGame(GameMode.infinite);

      // Digita 't' na posição 0. Cursor deve ir para 1. Palavra: "t    "
      cubit.addLetter('t');
      expect(cubit.state.cursorIndex, 1);
      expect(cubit.state.currentGuess, 't');

      // Seleciona manualmente a posição 3
      cubit.setCursor(3);
      expect(cubit.state.cursorIndex, 3);

      // Digita 'm' na posição 3 (palavra deve ficar "t  m ").
      // A próxima vazia à direita é a 4.
      cubit.addLetter('m');
      expect(cubit.state.currentGuess, 't  m');
      expect(cubit.state.cursorIndex, 4);

      // Digita 'o' na posição 4 (palavra deve ficar "t  mo").
      // Não há vazias à direita. A primeira vazia a partir do início é 1.
      cubit.addLetter('o');
      expect(cubit.state.currentGuess, 't  mo');
      expect(cubit.state.cursorIndex, 1);

      // Digita 'e' na posição 1 (palavra deve ficar "te mo").
      // A próxima vazia à direita é a 2.
      cubit.addLetter('e');
      expect(cubit.state.currentGuess, 'te mo');
      expect(cubit.state.cursorIndex, 2);

      // Digita 'r' na posição 2 (palavra fica "termo").
      // Linha cheia, deve manter cursor no final (4).
      cubit.addLetter('r');
      expect(cubit.state.currentGuess, 'termo');
      expect(cubit.state.cursorIndex, 4);
    });

    test('deve replicar letras verdes da tentativa anterior e ajustar cursor', () async {
      mockRepository.nextWordId = 1; // target is 'termo'
      await cubit.startGame(GameMode.infinite);

      // Digita e submete primeiro palpite: 'tarta'
      // target = 'termo'
      // Feedback: 't' (correto), 'a' (ausente), 'r' (correto), 't' (ausente), 'a' (ausente)
      cubit.addLetter('t');
      cubit.addLetter('a');
      cubit.addLetter('r');
      cubit.addLetter('t');
      cubit.addLetter('a');
      await cubit.submitGuess();

      expect(cubit.state.boardGuesses[0].length, 1);

      // Executa a replicação
      cubit.replicatePreviousGreenLetters(0);

      // Deve replicar apenas 't' no índice 0 e 'r' no índice 2
      // currentGuess deve ser "t r"
      expect(cubit.state.currentGuess, 't r');
      expect(cubit.state.lastReplicatedIndices, containsAll([0, 2]));
      expect(cubit.state.replicationNonce, 1);
      // Próxima célula vazia é 1
      expect(cubit.state.cursorIndex, 1);

      // Se limparmos ou digitarmos, lastReplicatedIndices deve resetar
      cubit.addLetter('e');
      expect(cubit.state.lastReplicatedIndices, isEmpty);
    });

    test('não deve fazer nada se não houver tentativas anteriores', () async {
      mockRepository.nextWordId = 1;
      await cubit.startGame(GameMode.infinite);

      cubit.replicatePreviousGreenLetters(0);

      expect(cubit.state.currentGuess, isEmpty);
      expect(cubit.state.lastReplicatedIndices, isEmpty);
      expect(cubit.state.replicationNonce, 0);
    });
  });
}
