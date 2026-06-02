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
            final isCompleted = row < guesses.length;
            final isActive = row == guesses.length &&
                !boardCompleted &&
                (state.status == GameStatus.playing ||
                    state.status == GameStatus.submitting);

            // 1. Determine letters, statuses, and tap handlers
            final List<String> letters = List.filled(wordLength, '');
            final List<LetterStatus> statuses = List.filled(wordLength, LetterStatus.unknown);
            final List<bool> selecteds = List.filled(wordLength, false);
            VoidCallback? Function(int col)? getOnTap;

            if (isCompleted) {
              final result = guesses[row];
              for (int col = 0; col < wordLength; col++) {
                final fb = result.feedback[col];
                letters[col] = fb.letter;
                statuses[col] = fb.status;
              }
            } else if (isActive) {
              for (int col = 0; col < wordLength; col++) {
                final char = col < currentGuess.length ? currentGuess[col] : ' ';
                letters[col] = char == ' ' ? '' : char;
                statuses[col] = LetterStatus.unknown;
                selecteds[col] = col == state.cursorIndex;
              }
              getOnTap = (col) => () => context.read<GameCubit>().setCursor(col);
            } else {
              // Empty row
            }

            final isBounceRow = isCompleted && row == _bounceRowIndex;

            Widget rowWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(wordLength, (col) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.tilePadding),
                  child: GestureDetector(
                    onTap: getOnTap?.call(col),
                    child: LetterTile(
                      letter: letters[col],
                      status: statuses[col],
                      size: widget.tileSize,
                      shouldBounce: isBounceRow,
                      isSelected: selecteds[col],
                      animationDelay: Duration(milliseconds: col * 150),
                      replicateNonce: state.replicationNonce,
                      shouldFlipHorizontal: isActive && state.lastReplicatedIndices.contains(col),
                    ),
                  ),
                );
              }),
            );

            rowWidget = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: isActive
                  ? () => context.read<GameCubit>().replicatePreviousGreenLetters(widget.boardIndex)
                  : null,
              child: rowWidget,
            );

            // 2. Build the unified widget tree to preserve LetterTileState
            return ShakeWidget(
              trigger: isActive ? state.errorMessage : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: rowWidget,
              ),
            );
          }),
        );
      },
    );
  }
}
