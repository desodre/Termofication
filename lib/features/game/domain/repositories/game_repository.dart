import '../entities/challenge.dart';
import '../entities/game_enums.dart';
import '../entities/guess_result.dart';

abstract class GameRepository {
  Future<Challenge> getDailyChallenge({GameMode mode = GameMode.daily});
  Future<Challenge> getRandomChallenge({int length = 5});
  Future<GuessResult> submitGuess(String guess, int wordId);
  Future<String> revealWord(int wordId);
  
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
  
  Future<void> saveInfiniteStats({
    required int wins,
    required int losses,
    required int streak,
  });
  
  Future<Map<String, int>> getInfiniteStats();

  Future<void> recordGame({
    required bool won,
    required int attempts,
    required String accessToken,
  });
}
