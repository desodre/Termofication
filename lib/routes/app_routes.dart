import 'package:flutter/material.dart';
import '../features/game/domain/entities/game_enums.dart';
import '../features/game/presentation/screens/daily_mode_selection_screen.dart';
import '../features/game/presentation/screens/game_desktop_screen.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const dailyGameSelect = '/game/daily/select';
  static const dailyGame = '/game/daily';
  static const dailyDuetoGame = '/game/daily/dueto';
  static const dailyQuartetoGame = '/game/daily/quarteto';
  static const infiniteGame = '/game/infinite';

  static final routes = <String, WidgetBuilder>{
    splash: (_) => const SplashScreen(),
    home: (_) => const HomeScreen(),
    dailyGameSelect: (_) => const DailyModeSelectionScreen(),
    dailyGame: (_) => const GameDesktopScreen(mode: GameMode.daily),
    dailyDuetoGame: (_) => const GameDesktopScreen(mode: GameMode.dailyDueto),
    dailyQuartetoGame: (_) =>
        const GameDesktopScreen(mode: GameMode.dailyQuarteto),
    infiniteGame: (_) => const GameDesktopScreen(mode: GameMode.infinite),
  };
}
