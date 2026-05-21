import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/game_enums.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../widgets/guess_grid.dart';
import '../widgets/virtual_keyboard.dart';
import '../widgets/floating_toast.dart';

class GameDesktopScreen extends StatefulWidget {
  final GameMode mode;

  const GameDesktopScreen({super.key, required this.mode});

  @override
  State<GameDesktopScreen> createState() => _GameDesktopScreenState();
}

class _GameDesktopScreenState extends State<GameDesktopScreen> {
  final FocusNode _focusNode = FocusNode();
  GameStatus _lastStatus = GameStatus.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameCubit>().startGame(widget.mode);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final cubit = context.read<GameCubit>();
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.backspace) {
      cubit.removeLetter();
    } else if (key == LogicalKeyboardKey.enter) {
      cubit.submitGuess();
    } else {
      final label = event.character;
      if (label != null && RegExp(r'^[a-zA-Z]$').hasMatch(label)) {
        cubit.addLetter(label);
      }
    }
  }

  void _showResultDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        return _ResultDialog(state: state, parentContext: context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            widget.mode == GameMode.daily ? 'TERMO' : 'MODO INFINITO',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: AppColors.textWhite,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            BlocBuilder<GameCubit, GameState>(
              builder: (context, state) {
                if (widget.mode == GameMode.infinite) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.present.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.present.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '🔥 ${state.infiniteStreak}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.present,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocListener<GameCubit, GameState>(
          listenWhen: (previous, current) {
            return previous.status != current.status || previous.errorMessage != current.errorMessage;
          },
          listener: (context, state) {
            // Display floating toast for errors
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              FloatingToast.show(context, state.errorMessage!);
            }

            // Detect Game Over to trigger the Dialog
            final hasFinished = state.status == GameStatus.won || state.status == GameStatus.lost;
            final wasPlaying = _lastStatus == GameStatus.playing ||
                _lastStatus == GameStatus.submitting ||
                _lastStatus == GameStatus.loading;

            if (hasFinished && wasPlaying) {
              _showResultDialog(context, state);
            }

            _lastStatus = state.status;
          },
          child: BlocBuilder<GameCubit, GameState>(
            builder: (context, state) {
              if (state.status == GameStatus.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.correct),
                );
              }

              final isGameOver = state.status == GameStatus.won || state.status == GameStatus.lost;

              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: const GuessGrid(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isGameOver)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: () => _showResultDialog(context, state),
                            icon: const Icon(Icons.analytics_rounded),
                            label: const Text(
                              'VER RESULTADOS & ESTATÍSTICAS',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.correct,
                              foregroundColor: AppColors.textWhite,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.correct.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: const VirtualKeyboard(),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final GameState state;
  final BuildContext parentContext;

  const _ResultDialog({
    required this.state,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final won = state.status == GameStatus.won;

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
                color: (won ? AppColors.correct : Colors.redAccent).withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
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
                  color: (won ? AppColors.correct : Colors.redAccent).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (won ? AppColors.correct : Colors.redAccent).withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  won ? Icons.emoji_events_rounded : Icons.sentiment_very_dissatisfied_rounded,
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
                  'Você desvendou a palavra secreta!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textWhite.withValues(alpha: 0.9), fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Acertou em ${state.guesses.length} de 6 tentativas.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                ),
              ] else ...[
                const Text(
                  'Você esgotou suas tentativas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGray, fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A palavra correta era:',
                  style: TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  state.targetWord.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    color: AppColors.present,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
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
                    _StatItem(label: 'Vitórias', value: '${state.infiniteWins}', icon: Icons.check_circle_outline),
                    _StatItem(label: 'Derrotas', value: '${state.infiniteLosses}', icon: Icons.highlight_off),
                    _StatItem(
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
                          Navigator.pop(context); // Close dialog
                          parentContext.read<GameCubit>().startGame(state.mode); // Restart
                        },
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('NOVA PALAVRA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.correct,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            onPressed: () => Navigator.pop(context), // Close dialog to inspect grid
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.borderActive),
                              foregroundColor: AppColors.textWhite,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(parentContext); // Exit game
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.borderActive),
                              foregroundColor: AppColors.textWhite,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatItem({
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
