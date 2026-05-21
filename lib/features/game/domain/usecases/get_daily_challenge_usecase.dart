import '../entities/challenge.dart';
import '../repositories/game_repository.dart';

class GetDailyChallengeUseCase {
  final GameRepository repository;

  const GetDailyChallengeUseCase(this.repository);

  Future<Challenge> call() async {
    return await repository.getDailyChallenge();
  }
}
