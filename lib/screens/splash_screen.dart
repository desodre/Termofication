import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_colors.dart';
import '../features/game/presentation/cubit/game_cubit.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  bool _isInitCompleted = false;

  @override
  void initState() {
    super.initState();

    // Setup micro-animations (fade-in & scale)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Start visual animations and async warm-up
    _controller.forward();
    _startWarmUp();
  }

  Future<void> _startWarmUp() async {
    final startTime = DateTime.now();

    try {
      // 1. Warm up the local SQLite database
      await context.read<GameCubit>().warmUp();
    } catch (e) {
      debugPrint('SplashScreen: Erro no warm-up do banco de dados: $e');
    }

    // Ensure splash screen remains visible for a minimum duration of 1800ms
    // to provide a premium feel and prevent screen flicker on fast devices.
    final elapsedTime = DateTime.now().difference(startTime);
    final remainingDelay = const Duration(milliseconds: 1800) - elapsedTime;

    if (remainingDelay > Duration.zero) {
      await Future.delayed(remainingDelay);
    }

    if (mounted) {
      setState(() {
        _isInitCompleted = true;
      });
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF1E1E24), // Subtle central glow
              AppColors.background,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Animated Brand Logo
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/icons/termofication_logo_clean.png',
                    width: 140,
                    height: 140,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Brand Text
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: child,
                  );
                },
                child: const Column(
                  children: [
                    Text(
                      'TERMO',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: AppColors.textWhite,
                      ),
                    ),
                    Text(
                      'FICATION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: AppColors.correct,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              // Minimalist Progress Indicator
              AnimatedOpacity(
                opacity: _isInitCompleted ? 0.0 : 0.6,
                duration: const Duration(milliseconds: 300),
                child: const Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 1.5,
                      child: LinearProgressIndicator(
                        color: AppColors.correct,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'CARREGANDO DICIONÁRIO...',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
