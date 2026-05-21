import 'game_enums.dart';

class LetterFeedback {
  final String letter;
  final LetterStatus status;

  const LetterFeedback({
    required this.letter,
    required this.status,
  });
}
