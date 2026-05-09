import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_enums.dart';
import '../providers/game_provider.dart';
import '../widgets/guess_grid.dart';
import '../widgets/keyboard_widget.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;

  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startGame(widget.mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == GameMode.daily ? 'TERMO' : 'MODO INFINITO',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        actions: [
          if (widget.mode == GameMode.infinite)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '🔥 ${provider.currentStreak}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFF3A3A3C),
          ),
        ),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(GameProvider provider) {
    if (provider.status == GameStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF538D4E)),
      );
    }

    return Column(
      children: [
        if (provider.errorMessage != null)
          _ErrorBanner(message: provider.errorMessage!),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const GuessGrid(),
            ),
          ),
        ),
        if (provider.status == GameStatus.won ||
            provider.status == GameStatus.lost)
          _ResultBanner(provider: provider, mode: widget.mode)
        else
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: KeyboardWidget(),
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: const Color(0xFF818384),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final GameProvider provider;
  final GameMode mode;

  const _ResultBanner({required this.provider, required this.mode});

  @override
  Widget build(BuildContext context) {
    final won = provider.status == GameStatus.won;

    return Container(
      color: const Color(0xFF1A1A1B),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? '🎉 Parabéns!' : '😔 Que pena!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (!won)
              Text(
                'A palavra era: ${provider.targetWord.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFFB59F3B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (won)
              Text(
                'Em ${provider.guesses.length} tentativa${provider.guesses.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            if (mode == GameMode.infinite) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatItem(label: 'Vitórias', value: '${provider.infiniteWins}'),
                  const SizedBox(width: 24),
                  _StatItem(label: 'Derrotas', value: '${provider.infiniteLosses}'),
                  const SizedBox(width: 24),
                  _StatItem(label: 'Sequência', value: '${provider.currentStreak}🔥'),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (mode == GameMode.infinite)
              ElevatedButton.icon(
                onPressed: () => context.read<GameProvider>().startGame(mode),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'JOGAR NOVAMENTE',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF538D4E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '← Voltar ao menu',
                style: TextStyle(color: Color(0xFF818384)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}
