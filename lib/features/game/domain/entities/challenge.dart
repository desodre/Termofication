class Challenge {
  final int wordId;
  final int length;
  final List<int> wordIds;

  const Challenge({
    required this.wordId,
    required this.length,
    this.wordIds = const [],
  });
}
