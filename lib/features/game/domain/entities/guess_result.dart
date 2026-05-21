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
}
