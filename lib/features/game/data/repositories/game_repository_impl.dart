import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/game_enums.dart';
import '../../domain/entities/guess_result.dart';
import '../../domain/entities/game_stats.dart';
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
  Future<GameStats> getStats({required GameMode mode}) async {
    final key = 'stats_${mode.statsKey}';
    final data = storage.read(key);
    
    if (data != null) {
      return GameStats.fromJson(Map<String, dynamic>.from(data as Map));
    }

    // Se estiver vazio e for modo infinito, tenta fazer migração local das chaves antigas
    if (mode == GameMode.infinite) {
      final oldWins = storage.read<int>('infinite_wins');
      final oldLosses = storage.read<int>('infinite_losses');
      final oldStreak = storage.read<int>('infinite_streak');

      if (oldWins != null || oldLosses != null || oldStreak != null) {
        final wins = oldWins ?? 0;
        final losses = oldLosses ?? 0;
        final streak = oldStreak ?? 0;
        
        final migratedStats = GameStats(
          gamesPlayed: wins + losses,
          gamesWon: wins,
          currentStreak: streak,
          maxStreak: streak,
          guessDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0},
        );

        await saveStats(mode: mode, stats: migratedStats);
        return migratedStats;
      }
    }

    return GameStats.empty();
  }

  @override
  Future<void> saveStats({required GameMode mode, required GameStats stats}) async {
    final key = 'stats_${mode.statsKey}';
    await storage.write(key, stats.toJson());
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
  Future<void> syncStats({required GameMode mode}) async {
    developer.log('GameRepositoryImpl: syncStats() started for mode = ${mode.name}', name: 'GameRepository');
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      developer.log('GameRepositoryImpl: syncStats: currentUser = ${user?.id}', name: 'GameRepository');
      if (user == null) {
        developer.log('GameRepositoryImpl: syncStats: User is null, aborting remote sync', name: 'GameRepository');
        return;
      }
      
      developer.log('GameRepositoryImpl: syncStats: Querying user_stats for ${user.id} and mode ${mode.statsKey}...', name: 'GameRepository');
      final response = await supabase
          .from('user_stats')
          .select()
          .eq('user_id', user.id)
          .eq('game_mode', mode.statsKey)
          .maybeSingle();
      
      developer.log('GameRepositoryImpl: syncStats: Query response = $response', name: 'GameRepository');
      if (response != null) {
        final stats = GameStats.fromJson(Map<String, dynamic>.from(response as Map));
        await saveStats(mode: mode, stats: stats);
      } else {
        developer.log('GameRepositoryImpl: syncStats: No remote stats found for user and mode ${mode.statsKey}.', name: 'GameRepository');
      }
    } catch (e, st) {
      developer.log(
        'GameRepositoryImpl: syncStats ERROR: $e',
        error: e,
        stackTrace: st,
        name: 'GameRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> recordGame({
    required GameMode mode,
    required bool won,
    required int attempts,
  }) async {
    developer.log('GameRepositoryImpl: recordGame() started: mode = ${mode.name}, won = $won, attempts = $attempts', name: 'GameRepository');
    try {
      // 1. Atualiza localmente primeiro
      final currentStats = await getStats(mode: mode);
      
      int gamesPlayed = currentStats.gamesPlayed + 1;
      int gamesWon = currentStats.gamesWon;
      int currentStreak = currentStats.currentStreak;
      int maxStreak = currentStats.maxStreak;
      final guessDist = Map<int, int>.from(currentStats.guessDistribution);

      if (won) {
        gamesWon++;
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
        guessDist[attempts] = (guessDist[attempts] ?? 0) + 1;
      } else {
        currentStreak = 0;
      }

      final updatedStats = GameStats(
        gamesPlayed: gamesPlayed,
        gamesWon: gamesWon,
        currentStreak: currentStreak,
        maxStreak: maxStreak,
        guessDistribution: guessDist,
      );

      await saveStats(mode: mode, stats: updatedStats);

      // 2. Tenta enviar para o Supabase se autenticado
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        developer.log('GameRepositoryImpl: recordGame: User is null, skipping remote upsert', name: 'GameRepository');
        return;
      }

      final payload = {
        'user_id': user.id,
        'game_mode': mode.statsKey,
        ...updatedStats.toJson(),
      };

      developer.log('GameRepositoryImpl: recordGame: Performing upsert on user_stats: $payload', name: 'GameRepository');
      await supabase.from('user_stats').upsert(payload);
      developer.log('GameRepositoryImpl: recordGame: Remote upsert completed successfully', name: 'GameRepository');
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
