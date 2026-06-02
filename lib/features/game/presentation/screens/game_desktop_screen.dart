import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../domain/entities/game_enums.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../widgets/virtual_keyboard.dart';
import '../widgets/floating_toast.dart';
import '../widgets/boards_layout.dart';
import '../widgets/result_dialog.dart';
import '../../../../widgets/game_gradient_background.dart';

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
        return ResultDialog(state: state, parentContext: context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GameGradientBackground(
        mode: widget.mode,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              widget.mode == GameMode.infinite
                  ? 'MODO INFINITO'
                  : widget.mode.displayName.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: AppColors.textWhite,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
              onPressed: () {
                AudioService.playClick();
                Navigator.of(context).pop();
              },
            ),
            actions: [
              BlocBuilder<GameCubit, GameState>(
                builder: (context, state) {
                  if (widget.mode == GameMode.infinite) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.present.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.present.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '🔥 ${state.statsStreak}',
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
              return previous.status != current.status ||
                  previous.errorMessage != current.errorMessage;
            },
            listener: (context, state) {
              // Display floating toast for errors
              if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                FloatingToast.show(context, state.errorMessage!);
              }

              // Detect Game Over to trigger the Dialog
              final hasFinished =
                  state.status == GameStatus.won ||
                  state.status == GameStatus.lost;
              final wasPlaying =
                  _lastStatus == GameStatus.playing ||
                  _lastStatus == GameStatus.submitting ||
                  _lastStatus == GameStatus.loading;

              if (hasFinished && wasPlaying) {
                final currentCubit = context.read<GameCubit>();
                final delayMs = state.status == GameStatus.won ? 2000 : 1200;
                Future.delayed(Duration(milliseconds: delayMs), () {
                  if (!context.mounted) return;
                  if (currentCubit.state.status == GameStatus.won ||
                      currentCubit.state.status == GameStatus.lost) {
                    _showResultDialog(context, currentCubit.state);
                  }
                });
                if (state.status == GameStatus.won) {
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (!context.mounted) return;
                    if (currentCubit.state.status == GameStatus.won) {
                      AudioService.playVictory();
                    }
                  });
                } else if (state.status == GameStatus.lost) {
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (!context.mounted) return;
                    if (currentCubit.state.status == GameStatus.lost) {
                      AudioService.playDefeat();
                    }
                  });
                }
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

                final attemptsLimit = GameCubit.maxAttemptsForMode(state.mode);
                final isGameOver =
                    state.status == GameStatus.won ||
                    state.status == GameStatus.lost;

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: BoardsLayout(
                              mode: state.mode,
                              boardCompleted: state.boardCompleted,
                              maxAttempts: attemptsLimit,
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.correct,
                                foregroundColor: AppColors.textWhite,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: AppColors.correct.withValues(
                                  alpha: 0.3,
                                ),
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
      ),
    );
  }
}
