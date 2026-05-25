import '../../domain/entities/game_enums.dart';
import '../../domain/entities/letter_feedback.dart';

class LetterFeedbackModel extends LetterFeedback {
  const LetterFeedbackModel({required super.letter, required super.status});

  factory LetterFeedbackModel.fromJson(Map<String, dynamic> json) {
    return LetterFeedbackModel(
      letter: json['letter'] as String,
      status: _statusFromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() => {'letter': letter, 'status': status.name};

  static LetterStatus _statusFromString(String s) {
    switch (s.trim().toLowerCase()) {
      case 'correct':
        return LetterStatus.correct;
      case 'present':
        return LetterStatus.present;
      case 'absent':
        return LetterStatus.absent;
      default:
        return LetterStatus.unknown;
    }
  }
}
