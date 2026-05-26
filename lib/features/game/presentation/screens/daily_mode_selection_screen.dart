import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../../../widgets/game_gradient_background.dart';

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
                _DailyModeCard(
                  route: AppRoutes.dailyGame,
                  icon: Icons.looks_one_rounded,
                  color: AppColors.correct,
                  title: 'TERMO',
                  subtitle: '1 palavra • Clássico',
                ),
                SizedBox(height: 14),
                _DailyModeCard(
                  route: AppRoutes.dailyDuetoGame,
                  icon: Icons.looks_two_rounded,
                  color: AppColors.present,
                  title: 'DUETO',
                  subtitle: '2 palavras simultâneas',
                ),
                SizedBox(height: 14),
                _DailyModeCard(
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

class _DailyModeCard extends StatefulWidget {
  final String route;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _DailyModeCard({
    required this.route,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_DailyModeCard> createState() => _DailyModeCardState();
}

class _DailyModeCardState extends State<_DailyModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        Navigator.pushNamed(context, widget.route);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withValues(alpha: 0.22),
                widget.color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: AppColors.textGray.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.color.withValues(alpha: 0.8),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
