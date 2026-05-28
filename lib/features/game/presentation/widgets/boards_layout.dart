import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/game_enums.dart';
import 'guess_grid.dart';

class BoardsLayout extends StatelessWidget {
  final GameMode mode;
  final List<bool> boardCompleted;
  final int maxAttempts;

  const BoardsLayout({
    super.key,
    required this.mode,
    required this.boardCompleted,
    required this.maxAttempts,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        if (mode.wordCount == 1) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GuessGrid(boardIndex: 0, maxAttempts: maxAttempts),
          );
        }

        final maxBoardWidth = (availableWidth - 12) / 2;
        final innerWidth = maxBoardWidth - 20;
        double tileSize = (innerWidth - 30) / 5;

        tileSize = tileSize.clamp(20.0, 56.0);

        final exactBoardWidth = (tileSize * 5) + 30 + 20;

        final boards = List.generate(mode.wordCount, (index) {
          return SizedBox(
            width: exactBoardWidth,
            child: BoardPanel(
              title: 'PALAVRA ${index + 1}',
              completed: boardCompleted.length > index && boardCompleted[index],
              child: GuessGrid(
                boardIndex: index,
                maxAttempts: maxAttempts,
                tileSize: tileSize,
                tilePadding: 3.0,
              ),
            ),
          );
        });

        if (mode.wordCount == 2) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [boards[0], const SizedBox(width: 12), boards[1]],
          );
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [boards[0], const SizedBox(width: 12), boards[1]],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [boards[2], const SizedBox(width: 12), boards[3]],
            ),
          ],
        );
      },
    );
  }
}

class BoardPanel extends StatelessWidget {
  final String title;
  final bool completed;
  final Widget child;

  const BoardPanel({
    super.key,
    required this.title,
    required this.completed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? AppColors.correct.withValues(alpha: 0.6)
              : AppColors.borderDefault.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (completed) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.correct,
                  size: 16,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
