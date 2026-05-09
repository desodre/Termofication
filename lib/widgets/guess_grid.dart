import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_enums.dart';
import '../providers/game_provider.dart';
import 'letter_tile.dart';

class GuessGrid extends StatelessWidget {
  const GuessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final guesses = provider.guesses;
    final currentGuess = provider.currentGuess;
    const maxAttempts = GameProvider.maxAttempts;
    const wordLength = GameProvider.wordLength;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxAttempts, (row) {
        if (row < guesses.length) {
          final result = guesses[row];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(wordLength, (col) {
                final fb = result.feedback[col];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: LetterTile(
                    letter: fb.letter,
                    status: fb.status,
                  ),
                );
              }),
            ),
          );
        } else if (row == guesses.length &&
            provider.status == GameStatus.playing) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(wordLength, (col) {
                final letter =
                    col < currentGuess.length ? currentGuess[col] : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: LetterTile(
                    letter: letter,
                    status: LetterStatus.unknown,
                  ),
                );
              }),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(wordLength, (_) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: LetterTile(letter: ''),
                );
              }),
            ),
          );
        }
      }),
    );
  }
}
