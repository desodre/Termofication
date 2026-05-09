import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_enums.dart';
import '../providers/game_provider.dart';

class KeyboardWidget extends StatelessWidget {
  const KeyboardWidget({super.key});

  static const _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final keyboardState = provider.keyboardState;
    final isPlaying = provider.status == GameStatus.playing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              final status =
                  keyboardState[key.toLowerCase()] ?? LetterStatus.unknown;
              return _KeyButton(
                label: key,
                status: status,
                enabled: isPlaying,
                onTap: () {
                  if (!isPlaying) return;
                  if (key == '⌫') {
                    provider.removeLetter();
                  } else if (key == 'ENTER') {
                    provider.submitGuess();
                  } else {
                    provider.addLetter(key);
                  }
                },
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
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

  Color get _bgColor {
    switch (status) {
      case LetterStatus.correct:
        return const Color(0xFF538D4E);
      case LetterStatus.present:
        return const Color(0xFFB59F3B);
      case LetterStatus.absent:
        return const Color(0xFF3A3A3C);
      case LetterStatus.unknown:
        return const Color(0xFF818384);
    }
  }

  bool get _isWide => label == 'ENTER' || label == '⌫';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isWide ? 56 : 34,
          height: 58,
          decoration: BoxDecoration(
            color: enabled ? _bgColor : _bgColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: _isWide ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
