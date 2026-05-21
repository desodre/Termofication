import '../entities/challenge.dart';
import '../entities/game_enums.dart';
import '../entities/guess_result.dart';

abstract class GameRepository {
  Future<Challenge> getDailyChallenge();
  Future<Challenge> getRandomChallenge({int length = 5});
  Future<GuessResult> submitGuess(String guess, int wordId);
  Future<String> revealWord(int wordId);
  
  // Persistência local (GetStorage ou similar)
  Future<void> saveDailyGame({
    required String date,
    required int wordId,
    required String word,
    required List<GuessResult> guesses,
    required GameStatus status,
  });
  
  Future<Map<String, dynamic>?> getDailyGame();
  
  Future<void> saveInfiniteStats({
    required int wins,
    required int losses,
    required int streak,
  });
  
  Future<Map<String, int>> getInfiniteStats();
}
