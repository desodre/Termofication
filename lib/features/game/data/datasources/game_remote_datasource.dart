import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../models/challenge_model.dart';
import '../models/guess_result_model.dart';
import '../models/letter_feedback_model.dart';

abstract class GameRemoteDataSource {
  Future<ChallengeModel> getDailyChallenge({String gameMode = 'TERMO'});
  Future<ChallengeModel> getRandomChallenge(int length);
  Future<GuessResultModel> submitGuess(String guess, int wordId);
  Future<String> revealWord(int wordId);
}

class GameRemoteDataSourceImpl implements GameRemoteDataSource {
  final ApiClient? client;

  GameRemoteDataSourceImpl([this.client]);

  List<Map<String, dynamic>> _evaluateGuess(String guess, String secret) {
    final guessCleaned = guess.trim().toUpperCase();
    final secretCleaned = secret.trim().toUpperCase();

    final length = secretCleaned.length;
    final List<String> feedbackStatuses = List.filled(length, 'absent');

    // Count frequencies of letters in secret
    final Map<String, int> secretCounts = {};
    for (int i = 0; i < length; i++) {
      final char = secretCleaned[i];
      secretCounts[char] = (secretCounts[char] ?? 0) + 1;
    }

    // First pass: correct matches
    for (int i = 0; i < length; i++) {
      if (guessCleaned[i] == secretCleaned[i]) {
        feedbackStatuses[i] = 'correct';
        secretCounts[guessCleaned[i]] = secretCounts[guessCleaned[i]]! - 1;
      }
    }

    // Second pass: present matches
    for (int i = 0; i < length; i++) {
      if (feedbackStatuses[i] != 'correct') {
        final char = guessCleaned[i];
        if ((secretCounts[char] ?? 0) > 0) {
          feedbackStatuses[i] = 'present';
          secretCounts[char] = secretCounts[char]! - 1;
        }
      }
    }

    return List.generate(length, (i) => {
      'letter': guessCleaned[i],
      'status': feedbackStatuses[i],
    });
  }

  @override
  Future<ChallengeModel> getDailyChallenge({String gameMode = 'TERMO'}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final expectedWordCount = _expectedWordCountForMode(gameMode);
    try {
      final response = await Supabase.instance.client
          .from('daily_challenges')
          .select()
          .eq('play_date', today)
          .eq('game_mode', gameMode)
          .maybeSingle();

      if (response != null) {
        final wordIds = (response['word_ids'] as List<dynamic>)
            .map((e) => e as int)
            .toList();
        if (wordIds.isNotEmpty) {
          final selectedWordIds = wordIds.take(expectedWordCount).toList();
          final wordId = selectedWordIds[0];
          
          final wordResp = await Supabase.instance.client
              .from('valid_words')
              .select('length')
              .eq('id', wordId)
              .single();
          
          final length = wordResp['length'] as int;
          return ChallengeModel(
            wordId: wordId,
            length: length,
            wordIds: selectedWordIds,
          );
        }
      }
    } catch (e, st) {
      print('Error in getDailyChallenge primary query: \$e');
      print(st);
      // Fallback in case of database or connection errors
    }

    if (expectedWordCount == 1) {
      return await getRandomChallenge(5);
    }

    try {
      final response = await Supabase.instance.client
          .from('valid_words')
          .select('id')
          .eq('length', 5)
          .eq('is_target', true);

      final List<dynamic> wordsList = response as List<dynamic>;
      if (wordsList.length < expectedWordCount) {
        throw ServerException('Palavras insuficientes para gerar o desafio diário.');
      }

      final nowSeed = DateTime.now().millisecondsSinceEpoch;
      final selectedWordIds = <int>[];
      final used = <int>{};
      var cursor = 0;
      while (selectedWordIds.length < expectedWordCount && cursor < wordsList.length) {
        final idx = (nowSeed + cursor * 997) % wordsList.length;
        final id = wordsList[idx]['id'] as int;
        if (used.add(id)) {
          selectedWordIds.add(id);
        }
        cursor++;
      }

      return ChallengeModel(
        wordId: selectedWordIds.first,
        length: 5,
        wordIds: selectedWordIds,
      );
    } catch (e) {
      throw ServerException('Falha ao carregar desafio diário para $gameMode.');
    }
  }

  @override
  Future<ChallengeModel> getRandomChallenge(int length) async {
    try {
      final response = await Supabase.instance.client
          .from('valid_words')
          .select('id')
          .eq('length', length)
          .eq('is_target', true);

      final List<dynamic> wordsList = response as List<dynamic>;
      if (wordsList.isEmpty) {
        final fallbackResponse = await Supabase.instance.client
            .from('valid_words')
            .select('id')
            .eq('length', length);
        
        final List<dynamic> fallbackList = fallbackResponse as List<dynamic>;
        if (fallbackList.isEmpty) {
          throw ServerException('Dicionário de palavras está vazio.');
        }
        
        final randomIndex = DateTime.now().millisecondsSinceEpoch % fallbackList.length;
        final wordId = fallbackList[randomIndex]['id'] as int;
        return ChallengeModel(wordId: wordId, length: length, wordIds: [wordId]);
      }

      final randomIndex = DateTime.now().millisecondsSinceEpoch % wordsList.length;
      final wordId = wordsList[randomIndex]['id'] as int;
      return ChallengeModel(wordId: wordId, length: length, wordIds: [wordId]);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Falha ao conectar com o banco de dados Supabase: ' + e.toString());
    }
  }

  @override
  Future<GuessResultModel> submitGuess(String guess, int wordId) async {
    final cleanGuess = guess.trim().toLowerCase();

    try {
      // 1. Validate if word exists in the Supabase dictionary
      final dictCheck = await Supabase.instance.client
          .from('valid_words')
          .select('id')
          .eq('words', cleanGuess)
          .maybeSingle();

      if (dictCheck == null) {
        throw InvalidWordException('"$guess" não é uma palavra válida no dicionário oficial do jogo.');
      }

      // 2. Fetch target word text to perform evaluation
      final targetWordResp = await Supabase.instance.client
          .from('valid_words')
          .select('words')
          .eq('id', wordId)
          .single();

      final targetWord = targetWordResp['words'] as String;

      // 3. Evaluate matching statuses locally
      final feedback = _evaluateGuess(cleanGuess, targetWord);
      final isCorrect = cleanGuess.toUpperCase() == targetWord.toUpperCase();

      return GuessResultModel(
        guess: cleanGuess,
        isCorrect: isCorrect,
        feedback: feedback
            .map((f) => LetterFeedbackModel.fromJson(f))
            .toList(),
      );
    } catch (e) {
      if (e is InvalidWordException) rethrow;
      throw ServerException('Erro ao processar validação no Supabase: ${e.toString()}');
    }
  }

  @override
  Future<String> revealWord(int wordId) async {
    try {
      final response = await Supabase.instance.client
          .from('valid_words')
          .select('words')
          .eq('id', wordId)
          .single();

      return response['words'] as String;
    } catch (e) {
      throw ServerException('Erro ao revelar palavra secreta: ${e.toString()}');
    }
  }

  int _expectedWordCountForMode(String gameMode) {
    switch (gameMode.trim().toUpperCase()) {
      case 'DUETO':
        return 2;
      case 'QUARTETO':
        return 4;
      default:
        return 1;
    }
  }
}
