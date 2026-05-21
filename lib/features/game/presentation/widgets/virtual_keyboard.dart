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
        final colors = state.keyboardColors;
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
              final status = colors[key.toLowerCase()] ?? LetterStatus.unknown;
              final isWide = key == 'ENTER' || key == '⌫';
              final flexVal = isWide ? 15 : 10;

              rowItems.add(
                Expanded(
                  flex: flexVal,
                  child: _KeyButton(
                    label: key,
                    status: status,
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
  final LetterStatus status;
  final bool enabled;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.status,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  Color get _bgColor {
    switch (widget.status) {
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

  @override
  Widget build(BuildContext context) {
    final double height = 54;

    Color buttonColor = widget.enabled ? _bgColor : _bgColor.withValues(alpha: 0.4);
    if (widget.enabled) {
      if (_isPressed) {
        buttonColor = buttonColor.withValues(alpha: 0.75);
      } else if (_isHovered) {
        buttonColor = buttonColor.withValues(alpha: 0.85);
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
            if (widget.enabled) {
              setState(() => _isPressed = true);
            }
          },
          onTapUp: (_) {
            if (widget.enabled) {
              setState(() => _isPressed = false);
            }
          },
          onTapCancel: () {
            if (widget.enabled) {
              setState(() => _isPressed = false);
            }
          },
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : (_isHovered && widget.enabled ? 1.05 : 1.0),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(6),
                border: _isHovered && widget.enabled
                    ? Border.all(color: AppColors.textWhite.withValues(alpha: 0.3), width: 1.5)
                    : null,
                boxShadow: _isHovered && widget.enabled
                    ? [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: _isWide ? 10 : 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
