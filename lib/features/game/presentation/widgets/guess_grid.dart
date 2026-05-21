import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/game_enums.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import 'letter_tile.dart';
import 'shake_widget.dart';

class GuessGrid extends StatelessWidget {
  const GuessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        final guesses = state.guesses;
        final currentGuess = state.currentGuess;
        const maxAttempts = GameCubit.maxAttempts;
        const wordLength = GameCubit.wordLength;

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
                        animationDelay: Duration(milliseconds: col * 150),
                      ),
                    );
                  }),
                ),
              );
            } else if (row == guesses.length &&
                (state.status == GameStatus.playing || state.status == GameStatus.submitting)) {
              return ShakeWidget(
                trigger: state.errorMessage,
                child: Padding(
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
      },
    );
  }
}
