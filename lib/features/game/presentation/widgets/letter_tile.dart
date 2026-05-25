import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/game_enums.dart';

class LetterTile extends StatefulWidget {
  final String letter;
  final LetterStatus status;
  final double size;
  final Duration? animationDelay;
  final bool isSelected;

  const LetterTile({
    super.key,
    required this.letter,
    this.status = LetterStatus.unknown,
    this.size = 56,
    this.animationDelay,
    this.isSelected = false,
  });

  @override
  State<LetterTile> createState() => _LetterTileState();
}

class _LetterTileState extends State<LetterTile> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  late AnimationController _popController;
  late Animation<double> _popAnimation;

  @override
  void initState() {
    super.initState();

    // Flip Animation (3D Y-Axis Rotation)
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Typing Pop Animation (Scale Pop)
    _popController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _popAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_popController);

    // If game loads with pre-existing feedback, display it flipped immediately
    if (widget.status != LetterStatus.unknown) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant LetterTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. Trigger Flip animation when status changes from unknown to correct/present/absent
    if (oldWidget.status == LetterStatus.unknown &&
        widget.status != LetterStatus.unknown) {
      Future.delayed(widget.animationDelay ?? Duration.zero, () {
        if (mounted) {
          _flipController.forward(from: 0.0);
        }
      });
    }
    // 2. Trigger Typing Pop when a letter is newly entered
    else if (oldWidget.letter.isEmpty &&
        widget.letter.isNotEmpty &&
        widget.status == LetterStatus.unknown) {
      _popController.forward(from: 0.0);
    }
    // 3. Reset state if status changes back to unknown (e.g. game restart)
    else if (widget.status == LetterStatus.unknown &&
        oldWidget.status != LetterStatus.unknown) {
      _flipController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flipAnimation, _popAnimation]),
      builder: (context, child) {
        final flipVal = _flipAnimation.value;
        final isFront = flipVal <= 0.5;

        // 3D rotation angle
        final angle = isFront
            ? flipVal * 3.141592653589793
            : (1.0 - flipVal) * 3.141592653589793;

        // Effective status based on whether we are front or back during the flip
        final currentStatus = isFront ? LetterStatus.unknown : widget.status;

        Color backgroundColor;
        Color borderColor;

        switch (currentStatus) {
          case LetterStatus.correct:
            backgroundColor = AppColors.correct;
            borderColor = Colors.transparent;
            break;
          case LetterStatus.present:
            backgroundColor = AppColors.present;
            borderColor = Colors.transparent;
            break;
          case LetterStatus.absent:
            backgroundColor = AppColors.absent;
            borderColor = Colors.transparent;
            break;
          case LetterStatus.unknown:
            backgroundColor = Colors.transparent;
            borderColor = widget.letter.isEmpty
                ? AppColors.borderDefault
                : AppColors.borderActive;
            break;
        }

        final double scaleVal = _popAnimation.value;

        return Transform.scale(
          scale: scaleVal,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // 3D Perspective!
              ..rotateY(angle),
            alignment: Alignment.center,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.isSelected && currentStatus == LetterStatus.unknown
                      ? AppColors.textWhite
                      : borderColor,
                  width: widget.isSelected && currentStatus == LetterStatus.unknown ? 3 : 2,
                ),
                boxShadow: currentStatus != LetterStatus.unknown
                    ? [
                        BoxShadow(
                          color: backgroundColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: backgroundColor.withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.letter.toUpperCase(),
                  style: TextStyle(
                    fontSize: widget.size * 0.45,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
