import 'package:get_storage/get_storage.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/game_enums.dart';
import '../../domain/entities/guess_result.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/game_remote_datasource.dart';
import '../models/guess_result_model.dart';

class GameRepositoryImpl implements GameRepository {
  final GameRemoteDataSource remoteDataSource;
  final GetStorage storage;

  GameRepositoryImpl({
    required this.remoteDataSource,
    GetStorage? storage,
  }) : storage = storage ?? GetStorage();

  @override
  Future<Challenge> getDailyChallenge() async {
    return await remoteDataSource.getDailyChallenge();
  }

  @override
  Future<Challenge> getRandomChallenge({int length = 5}) async {
    return await remoteDataSource.getRandomChallenge(length);
  }

  @override
  Future<GuessResult> submitGuess(String guess, int wordId) async {
    return await remoteDataSource.submitGuess(guess, wordId);
  }

  @override
  Future<String> revealWord(int wordId) async {
    return await remoteDataSource.revealWord(wordId);
  }

  @override
  Future<void> saveDailyGame({
    required String date,
    required int wordId,
    required String word,
    required List<GuessResult> guesses,
    required GameStatus status,
  }) async {
    await storage.write('daily_date', date);
    await storage.write('daily_word_id', wordId);
    await storage.write('daily_word', word);
    
    final serializedGuesses = guesses.map((g) {
      if (g is GuessResultModel) {
        return g.toJson();
      }
      return GuessResultModel(
        guess: g.guess,
        isCorrect: g.isCorrect,
        feedback: g.feedback,
      ).toJson();
    }).toList();
    
    await storage.write('daily_guesses', serializedGuesses);
    await storage.write('daily_status', status.name);
  }

  @override
  Future<Map<String, dynamic>?> getDailyGame() async {
    final date = storage.read<String>('daily_date');
    if (date == null) return null;
    
    final wordId = storage.read<int>('daily_word_id') ?? 0;
    final word = storage.read<String>('daily_word') ?? '';
    final savedGuesses = storage.read<List>('daily_guesses');
    final statusStr = storage.read<String>('daily_status') ?? 'playing';
    
    List<GuessResult> guesses = [];
    if (savedGuesses != null) {
      guesses = savedGuesses
          .map((g) => GuessResultModel.fromJson(Map<String, dynamic>.from(g as Map)))
          .toList();
    }
    
    return {
      'date': date,
      'wordId': wordId,
      'word': word,
      'guesses': guesses,
      'status': _statusFromString(statusStr),
    };
  }

  @override
  Future<void> saveInfiniteStats({
    required int wins,
    required int losses,
    required int streak,
  }) async {
    await storage.write('infinite_wins', wins);
    await storage.write('infinite_losses', losses);
    await storage.write('infinite_streak', streak);
  }

  @override
  Future<Map<String, int>> getInfiniteStats() async {
    final wins = storage.read<int>('infinite_wins') ?? 0;
    final losses = storage.read<int>('infinite_losses') ?? 0;
    final streak = storage.read<int>('infinite_streak') ?? 0;
    
    return {
      'wins': wins,
      'losses': losses,
      'streak': streak,
    };
  }

  GameStatus _statusFromString(String s) {
    switch (s) {
      case 'loading':
        return GameStatus.loading;
      case 'submitting':
        return GameStatus.submitting;
      case 'won':
        return GameStatus.won;
      case 'lost':
        return GameStatus.lost;
      case 'error':
        return GameStatus.error;
      default:
        return GameStatus.playing;
    }
  }
}
