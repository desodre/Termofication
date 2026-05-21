import '../entities/challenge.dart';
import '../repositories/game_repository.dart';

class GetRandomWordUseCase {
  final GameRepository repository;

  const GetRandomWordUseCase(this.repository);

  Future<Challenge> call({int length = 5}) async {
    return await repository.getRandomChallenge(length: length);
  }
}
