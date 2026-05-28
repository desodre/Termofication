import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../domain/entities/game_enums.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class ResultDialog extends StatelessWidget {
  final GameState state;
  final BuildContext parentContext;

  const ResultDialog({
    super.key,
    required this.state,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final won = state.status == GameStatus.won;
    final attemptsLimit = GameCubit.maxAttemptsForMode(state.mode);
    final usedAttempts = state.boardGuesses.isNotEmpty
        ? state.boardGuesses.first.length
        : 0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: AppColors.cardBg.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: won
                  ? AppColors.correct.withValues(alpha: 0.4)
                  : Colors.redAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (won ? AppColors.correct : Colors.redAccent).withValues(
                  alpha: 0.15,
                ),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (won ? AppColors.correct : Colors.redAccent)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (won ? AppColors.correct : Colors.redAccent)
                        .withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  won
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_very_dissatisfied_rounded,
                  color: won ? AppColors.correct : Colors.redAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                won ? '🎉 PARABÉNS!' : '😔 QUE PENA!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: won ? AppColors.correct : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              if (won) ...[
                Text(
                  state.targetWordIds.length > 1
                      ? 'Você completou todos os tabuleiros!'
                      : 'Você desvendou a palavra secreta!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textWhite.withValues(alpha: 0.9),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Acertou em $usedAttempts de $attemptsLimit tentativas.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ] else ...[
                const Text(
                  'Você esgotou suas tentativas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGray, fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Palavra(s) correta(s):',
                  style: TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children:
                      (state.targetWords.isNotEmpty
                              ? state.targetWords
                              : [state.targetWord])
                          .where((w) => w.isNotEmpty)
                          .map(
                            (word) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.present.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.present.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                word.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.present,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],

              // Stats for Infinite Mode
              if (state.mode == GameMode.infinite) ...[
                const SizedBox(height: 24),
                const Divider(color: AppColors.borderDefault, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatItem(
                      label: 'Vitórias',
                      value: '${state.infiniteWins}',
                      icon: Icons.check_circle_outline,
                    ),
                    StatItem(
                      label: 'Derrotas',
                      value: '${state.infiniteLosses}',
                      icon: Icons.highlight_off,
                    ),
                    StatItem(
                      label: 'Sequência',
                      value: '${state.infiniteStreak} 🔥',
                      icon: Icons.local_fire_department_outlined,
                      highlight: true,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // Actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.mode == GameMode.infinite) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AudioService.playClick();
                          Navigator.pop(context); // Close dialog
                          parentContext.read<GameCubit>().startGame(
                            state.mode,
                          ); // Restart
                        },
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text(
                          'NOVA PALAVRA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.correct,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              AudioService.playClick();
                              Navigator.pop(context);
                            }, // Close dialog to inspect grid
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.borderActive,
                              ),
                              foregroundColor: AppColors.textWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('TABULEIRO'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              AudioService.playClick();
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(parentContext); // Exit game
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.borderActive,
                              ),
                              foregroundColor: AppColors.textWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('MENU INICIAL'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: highlight ? AppColors.present : AppColors.textGray,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.present : AppColors.textWhite,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textGray),
        ),
      ],
    );
  }
}
