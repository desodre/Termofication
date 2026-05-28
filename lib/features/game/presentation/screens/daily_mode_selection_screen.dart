import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../../../widgets/game_gradient_background.dart';
import '../widgets/daily_mode_card.dart';

class DailyModeSelectionScreen extends StatelessWidget {
  const DailyModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GameGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'PALAVRA DO DIA',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                DailyModeCard(
                  route: AppRoutes.dailyGame,
                  icon: Icons.looks_one_rounded,
                  color: AppColors.correct,
                  title: 'TERMO',
                  subtitle: '1 palavra • Clássico',
                ),
                SizedBox(height: 14),
                DailyModeCard(
                  route: AppRoutes.dailyDuetoGame,
                  icon: Icons.looks_two_rounded,
                  color: AppColors.present,
                  title: 'DUETO',
                  subtitle: '2 palavras simultâneas',
                ),
                SizedBox(height: 14),
                DailyModeCard(
                  route: AppRoutes.dailyQuartetoGame,
                  icon: Icons.looks_4_rounded,
                  color: Color(0xFFE07C4F),
                  title: 'QUARTETO',
                  subtitle: '4 palavras simultâneas',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
