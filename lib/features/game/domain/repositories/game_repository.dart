import '../entities/challenge.dart';
import '../entities/game_enums.dart';
import '../entities/guess_result.dart';
import '../entities/game_stats.dart';

abstract class GameRepository {
  Future<Challenge> getDailyChallenge({GameMode mode = GameMode.daily});
  Future<Challenge> getRandomChallenge({int length = 5});
  Future<GuessResult> submitGuess(String guess, int wordId);
  Future<String> revealWord(int wordId);
  Future<void> warmUp();

  // Persistência local (GetStorage ou similar)
  Future<void> saveDailyGame({
    required GameMode mode,
    required String date,
    required List<int> wordIds,
    required List<String> targetWords,
    required List<List<GuessResult>> boardGuesses,
    required List<bool> boardCompleted,
    required GameStatus status,
    required Map<String, LetterStatus> keyboardColors,
  });

  Future<Map<String, dynamic>?> getDailyGame({required GameMode mode});

  Future<GameStats> getStats({required GameMode mode});

  Future<void> saveStats({
    required GameMode mode,
    required GameStats stats,
  });

  Future<void> syncStats({required GameMode mode});

  Future<void> recordGame({
    required GameMode mode,
    required bool won,
    required int attempts,
  });
}
