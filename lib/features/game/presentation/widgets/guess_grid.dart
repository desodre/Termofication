import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/game_enums.dart';
import '../../domain/entities/guess_result.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import 'letter_tile.dart';
import 'shake_widget.dart';

class GuessGrid extends StatelessWidget {
  final int boardIndex;
  final int maxAttempts;
  final double tileSize;
  final double tilePadding;

  const GuessGrid({
    super.key,
    this.boardIndex = 0,
    this.maxAttempts = GameCubit.maxAttempts,
    this.tileSize = 56.0,
    this.tilePadding = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        final guesses = boardIndex < state.boardGuesses.length
            ? state.boardGuesses[boardIndex]
            : const <GuessResult>[];
        final boardCompleted = boardIndex < state.boardCompleted.length
            ? state.boardCompleted[boardIndex]
            : false;
        final currentGuess = state.currentGuess;
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
                      padding: EdgeInsets.symmetric(horizontal: tilePadding),
                      child: LetterTile(
                        letter: fb.letter,
                        status: fb.status,
                        size: tileSize,
                        animationDelay: Duration(milliseconds: col * 150),
                      ),
                    );
                  }),
                ),
              );
            } else if (row == guesses.length &&
                !boardCompleted &&
                (state.status == GameStatus.playing ||
                    state.status == GameStatus.submitting)) {
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
                        padding: EdgeInsets.symmetric(horizontal: tilePadding),
                        child: LetterTile(
                          letter: letter,
                          status: LetterStatus.unknown,
                          size: tileSize,
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
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: tilePadding),
                      child: LetterTile(letter: '', size: tileSize),
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
