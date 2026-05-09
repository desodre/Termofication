import 'letter_feedback.dart';

class GuessResult {
  final String guess;
  final bool isCorrect;
  final List<LetterFeedback> feedback;

  const GuessResult({
    required this.guess,
    required this.isCorrect,
    required this.feedback,
  });

  factory GuessResult.fromJson(Map<String, dynamic> json) {
    return GuessResult(
      guess: json['guess'] as String,
      isCorrect: json['is_correct'] as bool,
      feedback: (json['feedback'] as List)
          .map((f) => LetterFeedback.fromJson(Map<String, dynamic>.from(f)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'guess': guess,
        'is_correct': isCorrect,
        'feedback': feedback.map((f) => f.toJson()).toList(),
      };
}
