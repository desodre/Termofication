import 'package:flutter_test/flutter_test.dart';
import 'package:termofication_app/features/game/data/models/guess_result_model.dart';
import 'package:termofication_app/features/game/data/models/letter_feedback_model.dart';
import 'package:termofication_app/features/game/domain/entities/game_enums.dart';

void main() {
  group('GuessResultModel & LetterFeedbackModel', () {
    test('deve desserializar LetterFeedbackModel corretamente', () {
      final json = {
        'letter': 'c',
        'status': 'correct',
      };

      final model = LetterFeedbackModel.fromJson(json);

      expect(model.letter, 'c');
      expect(model.status, LetterStatus.correct);
    });

    test('deve serializar LetterFeedbackModel para JSON corretamente', () {
      const model = LetterFeedbackModel(
        letter: 'a',
        status: LetterStatus.present,
      );

      final json = model.toJson();

      expect(json['letter'], 'a');
      expect(json['status'], 'present');
    });

    test('deve desserializar GuessResultModel corretamente', () {
      final json = {
        'guess': 'carta',
        'is_correct': true,
        'feedback': [
          {'letter': 'c', 'status': 'correct'},
          {'letter': 'a', 'status': 'correct'},
          {'letter': 'r', 'status': 'correct'},
          {'letter': 't', 'status': 'correct'},
          {'letter': 'a', 'status': 'correct'},
        ],
      };

      final model = GuessResultModel.fromJson(json);

      expect(model.guess, 'carta');
      expect(model.isCorrect, isTrue);
      expect(model.feedback.length, 5);
      expect(model.feedback[0].status, LetterStatus.correct);
    });

    test('deve serializar GuessResultModel para JSON corretamente', () {
      const model = GuessResultModel(
        guess: 'carro',
        isCorrect: false,
        feedback: [
          LetterFeedbackModel(letter: 'c', status: LetterStatus.correct),
          LetterFeedbackModel(letter: 'a', status: LetterStatus.correct),
          LetterFeedbackModel(letter: 'r', status: LetterStatus.present),
          LetterFeedbackModel(letter: 'r', status: LetterStatus.absent),
          LetterFeedbackModel(letter: 'o', status: LetterStatus.absent),
        ],
      );

      final json = model.toJson();

      expect(json['guess'], 'carro');
      expect(json['is_correct'], isFalse);
      expect(json['feedback'], isA<List>());
      expect((json['feedback'] as List).length, 5);
    });
  });
}
