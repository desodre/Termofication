import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/game_enums.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class VirtualKeyboard extends StatelessWidget {
  const VirtualKeyboard({super.key});

  static const List<List<String>> _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        final boardColors = state.boardKeyboardColors;
        final wordCount = state.mode.wordCount;
        final enabled = state.status == GameStatus.playing;
        final cubit = context.read<GameCubit>();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_rows.length, (rowIndex) {
            final row = _rows[rowIndex];
            final List<Widget> rowItems = [];

            // Add side spacing to the middle row to keep letter keys perfectly aligned with row 1
            if (rowIndex == 1) {
              rowItems.add(const Spacer(flex: 5));
            }

            for (final key in row) {
              final isWide = key == 'ENTER' || key == '⌫';
              
              final List<LetterStatus> statuses = [];
              for (int i = 0; i < wordCount; i++) {
                final boardColorMap = i < boardColors.length ? boardColors[i] : <String, LetterStatus>{};
                // fb.letter is UPPERCASE from GameRemoteDataSourceImpl
                statuses.add(boardColorMap[key.toUpperCase()] ?? LetterStatus.unknown);
              }

              final flexVal = isWide ? 15 : 10;

              rowItems.add(
                Expanded(
                  flex: flexVal,
                  child: _KeyButton(
                    label: key,
                    statuses: statuses,
                    enabled: enabled,
                    onTap: () {
                      if (!enabled) return;
                      if (key == '⌫') {
                        cubit.removeLetter();
                      } else if (key == 'ENTER') {
                        cubit.submitGuess();
                      } else {
                        cubit.addLetter(key);
                      }
                    },
                  ),
                ),
              );
            }

            if (rowIndex == 1) {
              rowItems.add(const Spacer(flex: 5));
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: rowItems,
              ),
            );
          }),
        );
      },
    );
  }
}

class _KeyButton extends StatefulWidget {
  final String label;
  final List<LetterStatus> statuses;
  final bool enabled;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.statuses,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  Color _getColor(LetterStatus status) {
    switch (status) {
      case LetterStatus.correct:
        return AppColors.correct;
      case LetterStatus.present:
        return AppColors.present;
      case LetterStatus.absent:
        return AppColors.absent;
      case LetterStatus.unknown:
        return AppColors.unknown;
    }
  }

  bool get _isWide => widget.label == 'ENTER' || widget.label == '⌫';

  Widget _buildBackground() {
    final count = widget.statuses.length;
    
    if (_isWide || count <= 1) {
      final status = count > 0 ? widget.statuses.first : LetterStatus.unknown;
      return Container(color: _getColor(status));
    }

    final dividerColor = AppColors.background.withValues(alpha: 0.5);

    if (count == 2) {
      return Row(
        children: [
          Expanded(child: Container(color: _getColor(widget.statuses[0]))),
          Container(width: 2, color: dividerColor),
          Expanded(child: Container(color: _getColor(widget.statuses[1]))),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: Container(color: _getColor(widget.statuses[0]))),
              Expanded(child: Container(color: _getColor(widget.statuses[1]))),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: Container(color: _getColor(widget.statuses.length > 2 ? widget.statuses[2] : LetterStatus.unknown))),
              Expanded(child: Container(color: _getColor(widget.statuses.length > 3 ? widget.statuses[3] : LetterStatus.unknown))),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double height = 54;

    Color overlayColor = Colors.transparent;
    if (!widget.enabled) {
      overlayColor = AppColors.background.withValues(alpha: 0.6);
    } else {
      if (_isPressed) {
        overlayColor = Colors.black.withValues(alpha: 0.25);
      } else if (_isHovered) {
        overlayColor = Colors.white.withValues(alpha: 0.15);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: (_) {
            if (widget.enabled) setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            if (widget.enabled) setState(() => _isPressed = false);
          },
          onTapCancel: () {
            if (widget.enabled) setState(() => _isPressed = false);
          },
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : (_isHovered && widget.enabled ? 1.05 : 1.0),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: SizedBox(
              width: double.infinity,
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildBackground(),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: overlayColor,
                        borderRadius: BorderRadius.circular(6),
                        border: _isHovered && widget.enabled
                            ? Border.all(color: AppColors.textWhite.withValues(alpha: 0.3), width: 1.5)
                            : null,
                        boxShadow: _isHovered && widget.enabled
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: _isWide ? 10 : 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
