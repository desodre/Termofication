import 'package:flutter/material.dart';
import 'package:termofication_app/widgets/build_in_mode_card.dart';
import 'package:termofication_app/widgets/help_button.dart';
import 'package:termofication_app/widgets/menu_button.dart';
import 'package:termofication_app/widgets/mode_card.dart';
import '../core/theme/app_colors.dart';
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
                child: MenuButton(
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
                        const ModeCard(
                          label: 'PALAVRA DO DIA',
                          subtitle: 'Desafio único a cada 24 horas',
                          icon: Icons.calendar_today_rounded,
                          themeColor: AppColors.correct,
                          route: AppRoutes.dailyGameSelect,
                        ),
                        const SizedBox(height: 20),
                        const ModeCard(
                          label: 'MODO INFINITO',
                          subtitle: 'Treine e jogue sem limites',
                          icon: Icons.all_inclusive_rounded,
                          themeColor: AppColors.present,
                          route: AppRoutes.infiniteGame,
                        ),
                        const SizedBox(height: 20),
                        const BuildInModeCard(
                          label: 'MULTIPLAYER',
                          subtitle: 'Jogue com amigos em tempo real',
                          icon: Icons.group_rounded,
                          themeColor: AppColors.multiplayerBackground,
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
      floatingActionButton: const HelpButton(),
    );
  }
}
