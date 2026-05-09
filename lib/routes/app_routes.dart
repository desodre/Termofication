import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/game_screen.dart';
import '../models/game_enums.dart';

class AppRoutes {
  static const home = '/';
  static const dailyGame = '/game/daily';
  static const infiniteGame = '/game/infinite';

  static final routes = <String, WidgetBuilder>{
    home: (_) => const HomeScreen(),
    dailyGame: (_) => const GameScreen(mode: GameMode.daily),
    infiniteGame: (_) => const GameScreen(mode: GameMode.infinite),
  };
}
