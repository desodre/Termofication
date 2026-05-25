import '../../domain/entities/guess_result.dart';
import 'letter_feedback_model.dart';

class GuessResultModel extends GuessResult {
  const GuessResultModel({
    required super.guess,
    required super.isCorrect,
    required super.feedback,
  });

  factory GuessResultModel.fromJson(Map<String, dynamic> json) {
    return GuessResultModel(
      guess: json['guess'] as String,
      isCorrect: json['is_correct'] as bool,
      feedback: (json['feedback'] as List)
          .map(
            (f) => LetterFeedbackModel.fromJson(
              Map<String, dynamic>.from(f as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'guess': guess,
    'is_correct': isCorrect,
    'feedback': feedback
        .map(
          (f) =>
              LetterFeedbackModel(letter: f.letter, status: f.status).toJson(),
        )
        .toList(),
  };
}
