import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:termofication_app/features/game/presentation/screens/game_desktop_screen.dart';
import 'package:termofication_app/features/game/presentation/widgets/result_dialog.dart';
import 'package:termofication_app/features/game/presentation/widgets/virtual_keyboard.dart';

// Self-contained Mock Repository for flow testing
class FlowMockGameRepository implements GameRepository {
  final Map<int, String> _words = {1: 'termo', 2: 'carta', 3: 'dueto', 4: 'porta'};

  int nextWordId = 1;
  GuessResult? submitGuessResult;

  final Map<GameMode, Map<String, dynamic>> dailyGameData = {};
  final Map<GameMode, GameStats> mockStats = {};

  @override
  Future<Challenge> getDailyChallenge({GameMode mode = GameMode.daily}) async {
    return const Challenge(wordId: 1, length: 5, wordIds: [1, 2]);
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
  }) async {}

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
  Future<void> syncStats({required GameMode mode}) async {}

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

  setUpAll(() async {
    HttpOverrides.global = null;
  });

  group('Eventos e Fluxo de Tela (Navegação & Regras)', () {
    late FlowMockGameRepository repository;
    late GetRandomWordUseCase getRandomWordUseCase;
    late SubmitGuessUseCase submitGuessUseCase;
    late GameCubit cubit;

    setUp(() {
      repository = FlowMockGameRepository();
      getRandomWordUseCase = GetRandomWordUseCase(repository);
      submitGuessUseCase = SubmitGuessUseCase(repository);
      cubit = GameCubit(
        getRandomWordUseCase: getRandomWordUseCase,
        submitGuessUseCase: submitGuessUseCase,
        repository: repository,
      );
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('Deve digitar palavra pelo teclado virtual, vencer a partida e disparar ResultDialog', (WidgetTester tester) async {
      // Configura o repositório para retornar 'termo' (wordId = 1) no modo Infinito
      repository.nextWordId = 1;
      await cubit.startGame(GameMode.infinite);

      // Renderiza a tela de gameplay
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GameCubit>.value(
            value: cubit,
            child: const GameDesktopScreen(mode: GameMode.infinite),
          ),
        ),
      );

      // Aguarda qualquer renderização inicial
      await tester.pumpAndSettle();

      // Simula cliques no teclado virtual: T, E, R, M, O
      await tester.tap(find.text('T'));
      await tester.pump();
      await tester.tap(find.text('E'));
      await tester.pump();
      await tester.tap(find.text('R'));
      await tester.pump();
      await tester.tap(find.text('M'));
      await tester.pump();
      await tester.tap(find.text('O'));
      await tester.pump();

      // Verifica se a palavra atual digitada no cubit é 'termo'
      expect(cubit.state.currentGuess, 'termo');

      // Clica em ENTER para enviar o palpite
      await tester.tap(find.text('ENTER'));
      
      // Aguarda processamento do palpite e as animações de revelação / popups
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      // Com a vitória, o ResultDialog deve aparecer na árvore de widgets
      expect(find.byType(ResultDialog), findsOneWidget);
      expect(find.text('🎉 PARABÉNS!'), findsOneWidget);
    });

    testWidgets('Teste de Regra de Negócio: Tabuleiro concluído (isSolved == true) ignora inputs adicionais', (WidgetTester tester) async {
      // 1. Simula jogo com múltiplos tabuleiros (DUETO: palavra 1 = 'termo', palavra 2 = 'carta')
      await cubit.startGame(GameMode.dailyDueto);

      // Vamos direto ao cubit enviar o palpite correto 'termo' para simular que o tabuleiro 0 foi ganho.
      cubit.addLetter('t');
      cubit.addLetter('e');
      cubit.addLetter('r');
      cubit.addLetter('m');
      cubit.addLetter('o');
      await cubit.submitGuess();

      // Verifica se o tabuleiro 0 está marcado como concluído (true) e possui 1 guess.
      expect(cubit.state.boardCompleted[0], isTrue);
      expect(cubit.state.boardGuesses[0].length, 1);
      
      // O tabuleiro 1 ainda não foi resolvido.
      expect(cubit.state.boardCompleted[1], isFalse);
      expect(cubit.state.boardGuesses[1].length, 1); // recebeu o palpite 'termo', mas está incorreto (target = 'carta')

      // 2. Agora, enviamos um novo palpite 'carta' para tentar resolver o tabuleiro 1.
      cubit.addLetter('c');
      cubit.addLetter('a');
      cubit.addLetter('r');
      cubit.addLetter('t');
      cubit.addLetter('a');
      await cubit.submitGuess();

      // REGRESSÃO:
      // O tabuleiro 0 (já concluído) deve IGNORAR o novo palpite. Suas tentativas devem continuar sendo 1!
      expect(cubit.state.boardCompleted[0], isTrue);
      expect(cubit.state.boardGuesses[0].length, 1); // Mantido em 1!

      // O tabuleiro 1 deve receber o novo palpite e ser concluído com sucesso (totalizando 2 palpites).
      expect(cubit.state.boardCompleted[1], isTrue);
      expect(cubit.state.boardGuesses[1].length, 2); // Incrementado para 2!
    });
  });
}
