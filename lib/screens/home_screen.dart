import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/services/audio_service.dart';
import '../routes/app_routes.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Idle Floating Title Animation (Slow, soothing continuous vertical hover)
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3),
            radius: 1.3,
            colors: [
              Color(
                0xFF182315,
              ), // Deep ambient dark green glow in the center-top
              Color(0xFF121213), // Deep standard dark background
            ],
            stops: [0.0, 0.75],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Botão de menu (hamburger) ──
              Positioned(
                top: 12,
                left: 12,
                child: _MenuButton(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),

              // ── Conteúdo principal ──
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Floating Title
                        AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: child,
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TERMO',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textWhite,
                                  letterSpacing: 12,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.correct.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'FICATION',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textWhite.withValues(
                                    alpha: 0.8,
                                  ),
                                  letterSpacing: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Adivinhe a palavra em 6 tentativas',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGray.withValues(alpha: 0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 64),

                        // Interactive Glassmorphic Mode Cards
                        const _ModeCard(
                          label: 'PALAVRA DO DIA',
                          subtitle: 'Desafio único a cada 24 horas',
                          icon: Icons.calendar_today_rounded,
                          themeColor: AppColors.correct,
                          route: AppRoutes.dailyGameSelect,
                        ),
                        const SizedBox(height: 20),
                        const _ModeCard(
                          label: 'MODO INFINITO',
                          subtitle: 'Treine e jogue sem limites',
                          icon: Icons.all_inclusive_rounded,
                          themeColor: AppColors.present,
                          route: AppRoutes.infiniteGame,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botão de menu hamburger com glassmorphism ──
class _MenuButton extends StatefulWidget {
  final VoidCallback onTap;
  const _MenuButton({required this.onTap});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        AudioService.playClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.textWhite.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textWhite.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.menu_rounded,
            color: AppColors.textWhite,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── Card de seleção de modo de jogo ──
class _ModeCard extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color themeColor;
  final String route;

  const _ModeCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.themeColor,
    required this.route,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            AudioService.playClick();
            Navigator.pushNamed(context, widget.route);
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                // Semi-transparent dynamic gradient based on game theme color
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.themeColor.withValues(
                      alpha: _isHovered ? 0.25 : 0.15,
                    ),
                    widget.themeColor.withValues(
                      alpha: _isHovered ? 0.12 : 0.05,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? widget.themeColor.withValues(alpha: 0.6)
                      : widget.themeColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.themeColor.withValues(
                      alpha: _isHovered ? 0.18 : 0.05,
                    ),
                    blurRadius: _isHovered ? 20 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Symmetrical rounded backing for modern icons
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.themeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.themeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: widget.themeColor.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGray.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: widget.themeColor.withValues(alpha: 0.6),
                    size: 16,
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
