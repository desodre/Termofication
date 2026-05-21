import '../repositories/game_repository.dart';

class RevealWordUseCase {
  final GameRepository repository;

  const RevealWordUseCase(this.repository);

  Future<String> call(int wordId) async {
    return await repository.revealWord(wordId);
  }
}
