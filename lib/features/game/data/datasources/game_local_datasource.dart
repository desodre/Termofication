import 'dart:io';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/string_utils.dart';
import '../models/challenge_model.dart';
import '../models/guess_result_model.dart';
import '../models/letter_feedback_model.dart';

abstract class GameLocalDataSource {
  Future<ChallengeModel> getDailyChallenge({String gameMode = 'TERMO'});
  Future<ChallengeModel> getRandomChallenge(int length);
  Future<GuessResultModel> submitGuess(String guess, int wordId);
  Future<String> revealWord(int wordId);
}

// Versão do banco de dados local. Incrementar ao alterar o esquema da tabela
// para forçar re-cópia do asset no próximo lançamento do app.
const int _dbVersion = 2;

class GameLocalDataSourceImpl implements GameLocalDataSource {
  Database? _database;

  Future<Database> _getDatabase() async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "words_v$_dbVersion.db");

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      developer.log(
        "GameLocalDataSource: Copying words.db from assets to local app storage (v$_dbVersion)...",
        name: 'GameLocalDataSource',
      );
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      final data = await rootBundle.load("assets/words.db");
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Write to file
      await File(path).writeAsBytes(bytes, flush: true);
      developer.log(
        "GameLocalDataSource: Successfully copied words.db.",
        name: 'GameLocalDataSource',
      );
    } else {
      developer.log(
        "GameLocalDataSource: Opening existing words.db database (v$_dbVersion).",
        name: 'GameLocalDataSource',
      );
    }

    _database = await openDatabase(path, readOnly: true);
    return _database!;
  }

  List<Map<String, dynamic>> _evaluateGuess(String guess, String secret) {
    // Normaliza ambos para comparação sem acentos
    final guessNormalized = normalizePortuguese(guess.trim()).toUpperCase();
    final secretNormalized = normalizePortuguese(secret.trim()).toUpperCase();

    final length = secretNormalized.length;
    final List<String> feedbackStatuses = List.filled(length, 'absent');

    // Count frequencies of normalized letters in secret
    final Map<String, int> secretCounts = {};
    for (int i = 0; i < length; i++) {
      final char = secretNormalized[i];
      secretCounts[char] = (secretCounts[char] ?? 0) + 1;
    }

    // First pass: correct matches (using normalized letters)
    for (int i = 0; i < length; i++) {
      if (guessNormalized[i] == secretNormalized[i]) {
        feedbackStatuses[i] = 'correct';
        secretCounts[guessNormalized[i]] =
            secretCounts[guessNormalized[i]]! - 1;
      }
    }

    // Second pass: present matches (using normalized letters)
    for (int i = 0; i < length; i++) {
      if (feedbackStatuses[i] != 'correct') {
        final char = guessNormalized[i];
        if ((secretCounts[char] ?? 0) > 0) {
          feedbackStatuses[i] = 'present';
          secretCounts[char] = secretCounts[char]! - 1;
        }
      }
    }

    // Revela a letra com acento original se estiver na posição correta (verde),
    // caso contrário, mantém a letra sem acento digitada pelo usuário.
    final secretOriginal = secret.trim().toUpperCase();
    return List.generate(
      length,
      (i) => {
        'letter': feedbackStatuses[i] == 'correct'
            ? secretOriginal[i]
            : guessNormalized[i],
        'status': feedbackStatuses[i],
      },
    );
  }

  int _getDateSeed() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  @override
  Future<ChallengeModel> getDailyChallenge({String gameMode = 'TERMO'}) async {
    final db = await _getDatabase();

    try {
      // 1. Get all target words of length 5 ordered by ID
      final List<Map<String, dynamic>> targetWords = await db.query(
        'valid_words',
        columns: ['id'],
        where: 'length = ? AND is_target = 1',
        whereArgs: [5],
        orderBy: 'id ASC',
      );

      if (targetWords.length < 7) {
        throw ServerException('Palavras-alvo insuficientes no banco local.');
      }

      // 2. Deterministic dateseed based selection
      final seed = _getDateSeed();
      final rand = Random(seed);

      // Sorteia as 7 palavras exclusivas do dia garantindo unicidade
      final dailyWordIds = <int>[];
      while (dailyWordIds.length < 7) {
        final idx = rand.nextInt(targetWords.length);
        final id = targetWords[idx]['id'] as int;
        if (!dailyWordIds.contains(id)) {
          dailyWordIds.add(id);
        }
      }

      // Distribuição por modo de jogo
      final String mode = gameMode.trim().toUpperCase();
      List<int> selectedWordIds;
      if (mode == 'DUETO') {
        selectedWordIds = dailyWordIds.sublist(1, 3);
      } else if (mode == 'QUARTETO') {
        selectedWordIds = dailyWordIds.sublist(3, 7);
      } else { // TERMO
        selectedWordIds = dailyWordIds.sublist(0, 1);
      }

      return ChallengeModel(
        wordId: selectedWordIds.first,
        length: 5,
        wordIds: selectedWordIds,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Falha ao gerar desafio diário local para $gameMode: $e',
      );
    }
  }

  @override
  Future<ChallengeModel> getRandomChallenge(int length) async {
    final db = await _getDatabase();

    try {
      // Find all target words of the given length
      final List<Map<String, dynamic>> targets = await db.query(
        'valid_words',
        columns: ['id'],
        where: 'length = ? AND is_target = 1',
        whereArgs: [length],
        orderBy: 'id ASC',
      );

      List<Map<String, dynamic>> finalList = targets;
      if (targets.isEmpty) {
        // Fallback to all words of that length
        finalList = await db.query(
          'valid_words',
          columns: ['id'],
          where: 'length = ?',
          whereArgs: [length],
          orderBy: 'id ASC',
        );
      }

      if (finalList.isEmpty) {
        throw ServerException(
          'Dicionário de palavras para o comprimento $length está vazio.',
        );
      }

      final randomIdx = Random().nextInt(finalList.length);
      final wordId = finalList[randomIdx]['id'] as int;

      return ChallengeModel(wordId: wordId, length: length, wordIds: [wordId]);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Erro ao buscar desafio aleatório local: $e');
    }
  }

  @override
  Future<GuessResultModel> submitGuess(String guess, int wordId) async {
    final cleanGuess = guess.trim().toLowerCase();
    final normalizedGuess = normalizePortuguese(cleanGuess);
    final db = await _getDatabase();

    try {
      // 1. Validate if word exists in local database.
      //    Primeiro tenta busca exata (com acento), depois pela coluna normalizada.
      List<Map<String, dynamic>> dictCheck = await db.query(
        'valid_words',
        columns: ['id'],
        where: 'words = ?',
        whereArgs: [cleanGuess],
      );

      if (dictCheck.isEmpty) {
        // Busca pela versão normalizada (sem acento)
        dictCheck = await db.query(
          'valid_words',
          columns: ['id'],
          where: 'normalized = ?',
          whereArgs: [normalizedGuess],
        );
      }

      if (dictCheck.isEmpty) {
        throw InvalidWordException(
          '"$guess" não é uma palavra válida no dicionário oficial do jogo.',
        );
      }

      // 2. Fetch target word text to perform evaluation
      final List<Map<String, dynamic>> targetWordResp = await db.query(
        'valid_words',
        columns: ['words', 'normalized'],
        where: 'id = ?',
        whereArgs: [wordId],
      );

      if (targetWordResp.isEmpty) {
        throw ServerException(
          'Palavra de referência inválida ou não encontrada no banco local.',
        );
      }

      final targetWord = targetWordResp.first['words'] as String;
      final targetNormalized = targetWordResp.first['normalized'] as String;

      // 3. Evaluate matching statuses locally (comparação normalizada)
      final feedback = _evaluateGuess(cleanGuess, targetWord);

      // 4. Verifica vitória comparando as versões normalizadas
      final isCorrect =
          normalizedGuess.toUpperCase() == targetNormalized.toUpperCase();

      return GuessResultModel(
        guess: cleanGuess,
        isCorrect: isCorrect,
        feedback: feedback.map((f) => LetterFeedbackModel.fromJson(f)).toList(),
      );
    } catch (e) {
      if (e is InvalidWordException || e is ServerException) rethrow;
      throw ServerException('Erro ao processar validação no banco local: $e');
    }
  }

  @override
  Future<String> revealWord(int wordId) async {
    final db = await _getDatabase();

    try {
      final List<Map<String, dynamic>> response = await db.query(
        'valid_words',
        columns: ['words'],
        where: 'id = ?',
        whereArgs: [wordId],
      );

      if (response.isEmpty) {
        throw ServerException('Palavra secreta não encontrada no banco local.');
      }

      return response.first['words'] as String;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Erro ao revelar palavra secreta: $e');
    }
  }
}
