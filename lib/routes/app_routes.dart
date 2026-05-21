import 'package:flutter/material.dart';
import '../features/game/domain/entities/game_enums.dart';
import '../features/game/presentation/screens/game_desktop_screen.dart';
import '../screens/home_screen.dart';

class AppRoutes {
  static const home = '/';
  static const dailyGame = '/game/daily';
  static const infiniteGame = '/game/infinite';

  static final routes = <String, WidgetBuilder>{
    home: (_) => const HomeScreen(),
    dailyGame: (_) => const GameDesktopScreen(mode: GameMode.daily),
    infiniteGame: (_) => const GameDesktopScreen(mode: GameMode.infinite),
  };
}
