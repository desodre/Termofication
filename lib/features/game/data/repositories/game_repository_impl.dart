import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/game_enums.dart';
import '../../domain/entities/guess_result.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/game_local_datasource.dart';
import '../models/guess_result_model.dart';

class GameRepositoryImpl implements GameRepository {
  final GameLocalDataSource localDataSource;
  final GetStorage storage;

  GameRepositoryImpl({required this.localDataSource, GetStorage? storage})
    : storage = storage ?? GetStorage();

  @override
  Future<Challenge> getDailyChallenge({GameMode mode = GameMode.daily}) async {
    return await localDataSource.getDailyChallenge(gameMode: mode.supabaseKey);
  }

  @override
  Future<Challenge> getRandomChallenge({int length = 5}) async {
    return await localDataSource.getRandomChallenge(length);
  }

  @override
  Future<GuessResult> submitGuess(String guess, int wordId) async {
    return await localDataSource.submitGuess(guess, wordId);
  }

  @override
  Future<String> revealWord(int wordId) async {
    return await localDataSource.revealWord(wordId);
  }

  @override
  Future<void> warmUp() async {
    await localDataSource.warmUp();
  }

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
    final prefix = 'daily_${mode.supabaseKey.toLowerCase()}';

    await storage.write('${prefix}_date', date);
    await storage.write('${prefix}_word_ids', wordIds);
    await storage.write('${prefix}_target_words', targetWords);
    await storage.write('${prefix}_board_completed', boardCompleted);
    await storage.write('${prefix}_status', status.name);
    await storage.write(
      '${prefix}_keyboard_colors',
      keyboardColors.map((k, v) => MapEntry(k, v.name)),
    );

    final serializedBoards = boardGuesses
        .map(
          (board) => board.map((g) {
            if (g is GuessResultModel) {
              return g.toJson();
            }
            return GuessResultModel(
              guess: g.guess,
              isCorrect: g.isCorrect,
              feedback: g.feedback,
            ).toJson();
          }).toList(),
        )
        .toList();

    await storage.write('${prefix}_board_guesses', serializedBoards);

    // Retrocompatibilidade para o modo TERMO legado
    if (mode == GameMode.daily) {
      await storage.write('daily_date', date);
      await storage.write(
        'daily_word_id',
        wordIds.isNotEmpty ? wordIds.first : 0,
      );
      await storage.write(
        'daily_word',
        targetWords.isNotEmpty ? targetWords.first : '',
      );
      await storage.write(
        'daily_guesses',
        serializedBoards.isNotEmpty ? serializedBoards.first : [],
      );
      await storage.write('daily_status', status.name);
    }
  }

  @override
  Future<Map<String, dynamic>?> getDailyGame({required GameMode mode}) async {
    final prefix = 'daily_${mode.supabaseKey.toLowerCase()}';
    String? date = storage.read<String>('${prefix}_date');

    if (mode == GameMode.daily && date == null) {
      date = storage.read<String>('daily_date');
    }
    if (date == null) return null;

    List<int> wordIds = [];
    final rawWordIds = storage.read<List>('${prefix}_word_ids');
    if (rawWordIds != null) {
      wordIds = rawWordIds.map((e) => e as int).toList();
    } else if (mode == GameMode.daily) {
      final legacyWordId = storage.read<int>('daily_word_id');
      if (legacyWordId != null) {
        wordIds = [legacyWordId];
      }
    }

    if (wordIds.isEmpty) return null;

    List<String> targetWords = [];
    final rawTargetWords = storage.read<List>('${prefix}_target_words');
    if (rawTargetWords != null) {
      targetWords = rawTargetWords.map((e) => e.toString()).toList();
    } else if (mode == GameMode.daily) {
      final legacyWord = storage.read<String>('daily_word') ?? '';
      targetWords = [legacyWord];
    }

    final rawBoardGuesses = storage.read<List>('${prefix}_board_guesses');
    List<List<GuessResult>> boardGuesses = [];
    if (rawBoardGuesses != null) {
      boardGuesses = rawBoardGuesses.map((board) {
        final boardList = board as List;
        return boardList
            .map(
              (g) => GuessResultModel.fromJson(
                Map<String, dynamic>.from(g as Map),
              ),
            )
            .toList();
      }).toList();
    } else if (mode == GameMode.daily) {
      final legacyGuesses = storage.read<List>('daily_guesses');
      final guesses = (legacyGuesses ?? [])
          .map(
            (g) =>
                GuessResultModel.fromJson(Map<String, dynamic>.from(g as Map)),
          )
          .toList();
      boardGuesses = [guesses];
    }

    List<bool> boardCompleted = [];
    final rawBoardCompleted = storage.read<List>('${prefix}_board_completed');
    if (rawBoardCompleted != null) {
      boardCompleted = rawBoardCompleted.map((e) => e as bool).toList();
    }

    final statusStr =
        storage.read<String>('${prefix}_status') ??
        (mode == GameMode.daily
            ? (storage.read<String>('daily_status') ?? 'playing')
            : 'playing');

    final rawKeyboard =
        storage.read<Map>('${prefix}_keyboard_colors') ?? <String, dynamic>{};
    final keyboardColors = <String, LetterStatus>{};
    for (final entry in rawKeyboard.entries) {
      final key = entry.key.toString();
      final value = entry.value.toString();
      keyboardColors[key] = _letterStatusFromString(value);
    }

    return {
      'date': date,
      'wordIds': wordIds,
      'targetWords': targetWords,
      'boardGuesses': boardGuesses,
      'boardCompleted': boardCompleted,
      'keyboardColors': keyboardColors,
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

    return {'wins': wins, 'losses': losses, 'streak': streak};
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

  LetterStatus _letterStatusFromString(String s) {
    switch (s) {
      case 'absent':
        return LetterStatus.absent;
      case 'present':
        return LetterStatus.present;
      case 'correct':
        return LetterStatus.correct;
      default:
        return LetterStatus.unknown;
    }
  }

  @override
  Future<void> syncInfiniteStats() async {
    developer.log('GameRepositoryImpl: syncInfiniteStats() started', name: 'GameRepository');
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      developer.log('GameRepositoryImpl: syncInfiniteStats: currentUser = ${user?.id}', name: 'GameRepository');
      if (user == null) {
        developer.log('GameRepositoryImpl: syncInfiniteStats: User is null, aborting remote sync', name: 'GameRepository');
        return;
      }
      
      developer.log('GameRepositoryImpl: syncInfiniteStats: Querying user_stats for ${user.id}...', name: 'GameRepository');
      final response = await supabase
          .from('user_stats')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      developer.log('GameRepositoryImpl: syncInfiniteStats: Query response = $response', name: 'GameRepository');
      if (response != null) {
        final played = response['games_played'] as int? ?? 0;
        final wins = response['games_won'] as int? ?? 0;
        final losses = played - wins;
        final streak = response['current_streak'] as int? ?? 0;
        
        developer.log('GameRepositoryImpl: syncInfiniteStats: Writing values to storage: wins=$wins, losses=$losses, streak=$streak', name: 'GameRepository');
        await storage.write('infinite_wins', wins);
        await storage.write('infinite_losses', losses);
        await storage.write('infinite_streak', streak);
      } else {
        developer.log('GameRepositoryImpl: syncInfiniteStats: No remote stats found for user.', name: 'GameRepository');
      }
    } catch (e, st) {
      developer.log(
        'GameRepositoryImpl: syncInfiniteStats ERROR: $e',
        error: e,
        stackTrace: st,
        name: 'GameRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> recordGame({
    required bool won,
    required int attempts,
  }) async {
    developer.log('GameRepositoryImpl: recordGame() started: won = $won, attempts = $attempts', name: 'GameRepository');
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      developer.log('GameRepositoryImpl: recordGame: currentUser = ${user?.id}', name: 'GameRepository');
      if (user == null) {
        developer.log('GameRepositoryImpl: recordGame: User is null, aborting remote recordGame', name: 'GameRepository');
        return;
      }
      
      developer.log('GameRepositoryImpl: recordGame: Querying current user_stats for ${user.id}...', name: 'GameRepository');
      final response = await supabase
          .from('user_stats')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      developer.log('GameRepositoryImpl: recordGame: Current user_stats = $response', name: 'GameRepository');

      int gamesPlayed = (response?['games_played'] as int?) ?? 0;
      int gamesWon = (response?['games_won'] as int?) ?? 0;
      int currentStreak = (response?['current_streak'] as int?) ?? 0;
      int maxStreak = (response?['max_streak'] as int?) ?? 0;
      Map<String, dynamic> guessDist = Map<String, dynamic>.from(response?['guess_distribution'] as Map? ?? {});

      gamesPlayed++;
      if (won) {
        gamesWon++;
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
        final key = attempts.toString();
        guessDist[key] = (guessDist[key] as int? ?? 0) + 1;
      } else {
        currentStreak = 0;
      }

      developer.log(
        'GameRepositoryImpl: recordGame: Performing upsert with: gamesPlayed=$gamesPlayed, gamesWon=$gamesWon, currentStreak=$currentStreak, maxStreak=$maxStreak, guessDist=$guessDist',
        name: 'GameRepository',
      );
      await supabase.from('user_stats').upsert({
        'user_id': user.id,
        'games_played': gamesPlayed,
        'games_won': gamesWon,
        'current_streak': currentStreak,
        'max_streak': maxStreak,
        'guess_distribution': guessDist,
      });
      developer.log('GameRepositoryImpl: recordGame: Remote upsert completed successfully', name: 'GameRepository');

      // Sobrescreve o local com a nova verdade remota
      final losses = gamesPlayed - gamesWon;
      developer.log('GameRepositoryImpl: recordGame: Writing values to storage: wins=$gamesWon, losses=$losses, streak=$currentStreak', name: 'GameRepository');
      await storage.write('infinite_wins', gamesWon);
      await storage.write('infinite_losses', losses);
      await storage.write('infinite_streak', currentStreak);
    } catch (e, st) {
      developer.log(
        'GameRepositoryImpl: recordGame ERROR: $e',
        error: e,
        stackTrace: st,
        name: 'GameRepository',
      );
      rethrow;
    }
  }
}
