import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/services/audio_service.dart';
import 'help_sheet.dart';

class HelpButton extends StatefulWidget {
  const HelpButton({super.key});

  @override
  State<HelpButton> createState() => _HelpButtonState();
}

class _HelpButtonState extends State<HelpButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Soothing continuous vertical float animation for idle state
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: FloatingActionButton(
        onPressed: () {
          AudioService.playClick();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withValues(alpha: 0.5),
            builder: (context) => const HelpSheet(),
          );
        },
        backgroundColor: AppColors.cardBg.withValues(alpha: 0.85),
        foregroundColor: AppColors.textWhite,
        elevation: 6,
        shape: CircleBorder(
          side: BorderSide(
            color: AppColors.correct.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.help_outline_rounded,
          size: 26,
        ),
      ),
    );
  }
}