import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:termofication_app/features/game/data/datasources/game_local_datasource.dart';
import 'package:termofication_app/core/network/api_client.dart';
import 'package:termofication_app/features/game/domain/entities/game_enums.dart';

// Create a Mock database class using mocktail
class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabase mockDatabase;
  late GameLocalDataSourceImpl dataSource;

  setUp(() {
    mockDatabase = MockDatabase();
    dataSource = GameLocalDataSourceImpl(database: mockDatabase);
  });

  group('getDailyChallenge', () {
    final mockTargetWords = List.generate(
      10,
      (index) => {'id': index + 100},
    );

    test('should query the secret_words table for target words', () async {
      when(() => mockDatabase.query(
            'secret_words',
            columns: ['id'],
            where: 'length = ? AND is_target = 1',
            whereArgs: [5],
            orderBy: 'id ASC',
          )).thenAnswer((_) async => mockTargetWords);

      final challenge = await dataSource.getDailyChallenge(gameMode: 'TERMO');

      expect(challenge.length, equals(5));
      expect(challenge.wordIds.length, equals(1));
      verify(() => mockDatabase.query(
            'secret_words',
            columns: ['id'],
            where: 'length = ? AND is_target = 1',
            whereArgs: [5],
            orderBy: 'id ASC',
          )).called(1);
    });

    test('should return 1 word for TERMO mode', () async {
      when(() => mockDatabase.query(
            any(),
            columns: any(named: 'columns'),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
            orderBy: any(named: 'orderBy'),
          )).thenAnswer((_) async => mockTargetWords);

      final challenge = await dataSource.getDailyChallenge(gameMode: 'TERMO');

      expect(challenge.wordIds.length, equals(1));
    });

    test('should return 2 words for DUETO mode', () async {
      when(() => mockDatabase.query(
            any(),
            columns: any(named: 'columns'),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
            orderBy: any(named: 'orderBy'),
          )).thenAnswer((_) async => mockTargetWords);

      final challenge = await dataSource.getDailyChallenge(gameMode: 'DUETO');

      expect(challenge.wordIds.length, equals(2));
    });

    test('should return 4 words for QUARTETO mode', () async {
      when(() => mockDatabase.query(
            any(),
            columns: any(named: 'columns'),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
            orderBy: any(named: 'orderBy'),
          )).thenAnswer((_) async => mockTargetWords);

      final challenge = await dataSource.getDailyChallenge(gameMode: 'QUARTETO');

      expect(challenge.wordIds.length, equals(4));
    });

    test('should throw ServerException when target words are insufficient', () async {
      when(() => mockDatabase.query(
            any(),
            columns: any(named: 'columns'),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
            orderBy: any(named: 'orderBy'),
          )).thenAnswer((_) async => [{'id': 1}]); // Less than 7 target words

      expect(
        () => dataSource.getDailyChallenge(gameMode: 'TERMO'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getRandomChallenge', () {
    test('should select random target word from secret_words when length is 5', () async {
      when(() => mockDatabase.query(
            'secret_words',
            columns: ['id'],
            where: 'length = ? AND is_target = 1',
            whereArgs: [5],
            orderBy: 'id ASC',
          )).thenAnswer((_) async => [{'id': 42}]);

      final challenge = await dataSource.getRandomChallenge(5);

      expect(challenge.wordId, equals(42));
      expect(challenge.wordIds, equals([42]));
      verify(() => mockDatabase.query(
            'secret_words',
            columns: ['id'],
            where: 'length = ? AND is_target = 1',
            whereArgs: [5],
            orderBy: 'id ASC',
          )).called(1);
    });

    test('should fallback to valid_words when targets in secret_words are empty', () async {
      // Query secret_words returns empty
      when(() => mockDatabase.query(
            'secret_words',
            columns: ['id'],
            where: 'length = ? AND is_target = 1',
            whereArgs: [6],
            orderBy: 'id ASC',
          )).thenAnswer((_) async => []);

      // Query valid_words fallback returns words
      when(() => mockDatabase.query(
            'valid_words',
            columns: ['id'],
            where: 'length = ?',
            whereArgs: [6],
            orderBy: 'id ASC',
          )).thenAnswer((_) async => [{'id': 99}]);

      final challenge = await dataSource.getRandomChallenge(6);

      expect(challenge.wordId, equals(99));
      verify(() => mockDatabase.query(
            'secret_words',
            columns: ['id'],
            where: 'length = ? AND is_target = 1',
            whereArgs: [6],
            orderBy: 'id ASC',
          )).called(1);
      verify(() => mockDatabase.query(
            'valid_words',
            columns: ['id'],
            where: 'length = ?',
            whereArgs: [6],
            orderBy: 'id ASC',
          )).called(1);
    });
  });

  group('submitGuess', () {
    test('should validate guess in valid_words and return correct feedback', () async {
      // Stub check exact word in valid_words
      when(() => mockDatabase.query(
            'valid_words',
            columns: ['id'],
            where: 'words = ?',
            whereArgs: ['termo'],
          )).thenAnswer((_) async => [{'id': 10}]);

      // Stub fetch secret word text in valid_words
      when(() => mockDatabase.query(
            'valid_words',
            columns: ['words', 'normalized'],
            where: 'id = ?',
            whereArgs: [10],
          )).thenAnswer((_) async => [{'words': 'termo', 'normalized': 'termo'}]);

      final result = await dataSource.submitGuess('termo', 10);

      expect(result.guess, equals('termo'));
      expect(result.isCorrect, isTrue);
      expect(result.feedback.length, equals(5));
      expect(result.feedback.every((f) => f.status == LetterStatus.correct), isTrue);

      verify(() => mockDatabase.query(
            'valid_words',
            columns: ['id'],
            where: 'words = ?',
            whereArgs: ['termo'],
          )).called(1);
      verify(() => mockDatabase.query(
            'valid_words',
            columns: ['words', 'normalized'],
            where: 'id = ?',
            whereArgs: [10],
          )).called(1);
    });

    test('should validate guess in valid_words and return non-exact matching feedback', () async {
      // Stub check exact word
      when(() => mockDatabase.query(
            'valid_words',
            columns: ['id'],
            where: 'words = ?',
            whereArgs: ['porta'],
          )).thenAnswer((_) async => [{'id': 20}]);

      // Stub fetch secret word text
      when(() => mockDatabase.query(
            'valid_words',
            columns: ['words', 'normalized'],
            where: 'id = ?',
            whereArgs: [30],
          )).thenAnswer((_) async => [{'words': 'parto', 'normalized': 'parto'}]);

      final result = await dataSource.submitGuess('porta', 30);

      expect(result.guess, equals('porta'));
      expect(result.isCorrect, isFalse);
      
      // 'porta' vs 'parto'
      // p: correct (correct)
      // o: present (present in 'parto' at index 4)
      // r: correct (correct)
      // t: present (present in 'parto' at index 3)
      // a: present (present in 'parto' at index 1)
      expect(result.feedback[0].status, equals(LetterStatus.correct)); // p
      expect(result.feedback[1].status, equals(LetterStatus.present)); // o
      expect(result.feedback[2].status, equals(LetterStatus.correct)); // r
      expect(result.feedback[3].status, equals(LetterStatus.correct)); // t
      expect(result.feedback[4].status, equals(LetterStatus.present)); // a
    });

    test('should throw InvalidWordException when word does not exist in valid_words', () async {
      when(() => mockDatabase.query(
            'valid_words',
            columns: ['id'],
            where: 'words = ?',
            whereArgs: ['xxxxx'],
          )).thenAnswer((_) async => []);

      when(() => mockDatabase.query(
            'valid_words',
            columns: ['id'],
            where: 'normalized = ?',
            whereArgs: ['xxxxx'],
          )).thenAnswer((_) async => []);

      expect(
        () => dataSource.submitGuess('xxxxx', 10),
        throwsA(isA<InvalidWordException>()),
      );
    });
  });

  group('revealWord', () {
    test('should fetch word text by ID from valid_words', () async {
      when(() => mockDatabase.query(
            'valid_words',
            columns: ['words'],
            where: 'id = ?',
            whereArgs: [42],
          )).thenAnswer((_) async => [{'words': 'sagaz'}]);

      final word = await dataSource.revealWord(42);

      expect(word, equals('sagaz'));
      verify(() => mockDatabase.query(
            'valid_words',
            columns: ['words'],
            where: 'id = ?',
            whereArgs: [42],
          )).called(1);
    });
  });
}
