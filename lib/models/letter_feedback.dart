import 'game_enums.dart';

class LetterFeedback {
  final String letter;
  final LetterStatus status;

  const LetterFeedback({required this.letter, required this.status});

  factory LetterFeedback.fromJson(Map<String, dynamic> json) {
    return LetterFeedback(
      letter: json['letter'] as String,
      status: _statusFromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'letter': letter,
        'status': status.name,
      };

  static LetterStatus _statusFromString(String s) {
    switch (s) {
      case 'correct':
        return LetterStatus.correct;
      case 'present':
        return LetterStatus.present;
      default:
        return LetterStatus.absent;
    }
  }
}
