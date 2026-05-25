import '../../domain/entities/challenge.dart';

class ChallengeModel extends Challenge {
  const ChallengeModel({
    required super.wordId,
    required super.length,
    super.wordIds = const [],
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      wordId: json['word_id'] as int,
      length: json['length'] as int,
      wordIds: json['word_ids'] != null
          ? (json['word_ids'] as List<dynamic>).map((e) => e as int).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'word_id': wordId,
    'length': length,
    'word_ids': wordIds,
  };
}
