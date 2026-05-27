import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/game_enums.dart';
import '../../domain/entities/guess_result.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import 'letter_tile.dart';
import 'shake_widget.dart';

class GuessGrid extends StatefulWidget {
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
  State<GuessGrid> createState() => _GuessGridState();
}

class _GuessGridState extends State<GuessGrid> {
  int _lastCorrectNonce = 0;
  int _bounceRowIndex = -1;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listenWhen: (previous, current) =>
          current.correctBoardNonce != previous.correctBoardNonce,
      listener: (context, state) {
        if (state.correctBoardNonce == 0) {
          setState(() {
            _lastCorrectNonce = 0;
            _bounceRowIndex = -1;
          });
        } else if (state.correctBoardNonce > _lastCorrectNonce) {
          _lastCorrectNonce = state.correctBoardNonce;
          // Check if this board index is in newlyCorrectBoardIndices
          if (state.newlyCorrectBoardIndices.contains(widget.boardIndex)) {
            final guesses = widget.boardIndex < state.boardGuesses.length
                ? state.boardGuesses[widget.boardIndex]
                : const <GuessResult>[];
            if (guesses.isNotEmpty) {
              setState(() {
                _bounceRowIndex = guesses.length - 1;
              });
            }
          }
        }
      },
      builder: (context, state) {
        final guesses = widget.boardIndex < state.boardGuesses.length
            ? state.boardGuesses[widget.boardIndex]
            : const <GuessResult>[];
        final boardCompleted = widget.boardIndex < state.boardCompleted.length
            ? state.boardCompleted[widget.boardIndex]
            : false;
        final currentGuess = state.currentGuess;
        const wordLength = GameCubit.wordLength;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.maxAttempts, (row) {
            if (row < guesses.length) {
              final result = guesses[row];
              final isBounceRow = row == _bounceRowIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(wordLength, (col) {
                    final fb = result.feedback[col];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: widget.tilePadding),
                      child: LetterTile(
                        letter: fb.letter,
                        status: fb.status,
                        size: widget.tileSize,
                        shouldBounce: isBounceRow,
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
                      final char = col < currentGuess.length
                          ? currentGuess[col]
                          : ' ';
                      final letter = char == ' ' ? '' : char;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: widget.tilePadding),
                        child: GestureDetector(
                          onTap: () => context.read<GameCubit>().setCursor(col),
                          child: LetterTile(
                            letter: letter,
                            status: LetterStatus.unknown,
                            size: widget.tileSize,
                            isSelected: col == state.cursorIndex,
                          ),
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
                      padding: EdgeInsets.symmetric(horizontal: widget.tilePadding),
                      child: LetterTile(letter: '', size: widget.tileSize),
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
