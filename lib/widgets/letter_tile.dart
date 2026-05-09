import 'package:flutter/material.dart';
import '../models/game_enums.dart';

class LetterTile extends StatelessWidget {
  final String letter;
  final LetterStatus status;
  final double size;

  const LetterTile({
    super.key,
    required this.letter,
    this.status = LetterStatus.unknown,
    this.size = 56,
  });

  Color get _backgroundColor {
    switch (status) {
      case LetterStatus.correct:
        return const Color(0xFF538D4E);
      case LetterStatus.present:
        return const Color(0xFFB59F3B);
      case LetterStatus.absent:
        return const Color(0xFF3A3A3C);
      case LetterStatus.unknown:
        return Colors.transparent;
    }
  }

  Color get _borderColor {
    switch (status) {
      case LetterStatus.unknown:
        return letter.isEmpty
            ? const Color(0xFF3A3A3C)
            : const Color(0xFF565758);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border.all(color: _borderColor, width: 2),
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.43,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
