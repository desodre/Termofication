import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../core/theme/app_colors.dart';
import '../features/game/domain/entities/game_enums.dart';

class GameGradientBackground extends StatelessWidget {
  final GameMode? mode;
  final Widget child;

  const GameGradientBackground({
    super.key,
    this.mode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    final bool gradientsEnabled = storage.read<bool>('gradients_enabled') ?? true;

    if (!gradientsEnabled) {
      return Container(
        color: AppColors.background,
        child: child,
      );
    }

    Color glowColor;
    if (mode == null) {
      // Neutro / Seleção de Modos - Roxo Escuro Premium
      glowColor = const Color(0xFF171322);
    } else {
      switch (mode!) {
        case GameMode.daily:
        case GameMode.infinite:
          // Termo (Verde Escuro)
          glowColor = const Color(0xFF132212);
          break;
        case GameMode.dailyDueto:
          // Dueto (Dourado/Âmbar Mudo)
          glowColor = const Color(0xFF221F13);
          break;
        case GameMode.dailyQuarteto:
          // Quarteto (Terracota/Laranja Mudo)
          glowColor = const Color(0xFF261713);
          break;
      }
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.35),
          radius: 1.3,
          colors: [
            glowColor,
            AppColors.background,
          ],
          stops: const [0.0, 0.75],
        ),
      ),
      child: child,
    );
  }
}
