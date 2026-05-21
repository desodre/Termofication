import '../entities/guess_result.dart';
import '../repositories/game_repository.dart';

class SubmitGuessUseCase {
  final GameRepository repository;

  const SubmitGuessUseCase(this.repository);

  Future<GuessResult> call(String guess, int wordId) async {
    final cleanGuess = guess.trim().toLowerCase();
    return await repository.submitGuess(cleanGuess, wordId);
  }
}
