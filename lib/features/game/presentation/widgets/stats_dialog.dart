import 'dart:ui';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import 'package:get_storage/get_storage.dart';
import '../../domain/entities/game_stats.dart';
import '../../domain/entities/game_enums.dart';

class StatsDialog extends StatefulWidget {
  const StatsDialog({super.key});

  @override
  State<StatsDialog> createState() => _StatsDialogState();
}

class _StatsDialogState extends State<StatsDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, GameStats> _statsMap = {};
  String _selectedModeKey = 'DAILY';

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final authState = context.read<AuthCubit>().state;
    developer.log('StatsDialog: _fetchStats() initiated. authState = $authState', name: 'StatsDialog');

    // Inicializa o mapa local como fallback garantido
    _loadLocalStatsFallback();

    if (authState is UserAuthAuthenticated) {
      try {
        final supabase = Supabase.instance.client;
        final currentUser = supabase.auth.currentUser;
        developer.log(
          'StatsDialog: User is authenticated. authState.user.id = ${authState.user.id}, supabase.auth.currentUser.id = ${currentUser?.id}',
          name: 'StatsDialog',
        );
        
        developer.log('StatsDialog: Fetching user_stats from Supabase for user_id = ${authState.user.id}...', name: 'StatsDialog');
        final response = await supabase
            .from('user_stats')
            .select()
            .eq('user_id', authState.user.id);

        developer.log('StatsDialog: Fetch user_stats response = $response', name: 'StatsDialog');
        if (response.isNotEmpty) {
          setState(() {
            for (final row in response) {
              final modeKey = row['game_mode'] as String?;
              if (modeKey != null) {
                _statsMap[modeKey] = GameStats.fromJson(Map<String, dynamic>.from(row as Map));
              }
            }
            _isLoading = false;
          });
        } else {
          developer.log('StatsDialog: No remote stats found. Using local stats.', name: 'StatsDialog');
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e, st) {
        developer.log(
          'StatsDialog: ERROR fetching remote stats: $e',
          error: e,
          stackTrace: st,
          name: 'StatsDialog',
        );
        setState(() {
          _errorMessage = 'Falha ao sincronizar estatísticas remotas. Exibindo dados locais.';
          _isLoading = false;
        });
      }
    } else {
      developer.log('StatsDialog: User is NOT authenticated. Using local stats.', name: 'StatsDialog');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadLocalStatsFallback() {
    final storage = GetStorage();
    for (final mode in GameMode.values) {
      final key = 'stats_${mode.statsKey}';
      final data = storage.read(key);
      if (data != null) {
        _statsMap[mode.statsKey] = GameStats.fromJson(Map<String, dynamic>.from(data as Map));
      } else {
        if (mode == GameMode.infinite) {
          final oldWins = storage.read<int>('infinite_wins');
          final oldLosses = storage.read<int>('infinite_losses');
          final oldStreak = storage.read<int>('infinite_streak');
          if (oldWins != null || oldLosses != null || oldStreak != null) {
            _statsMap[mode.statsKey] = GameStats(
              gamesPlayed: (oldWins ?? 0) + (oldLosses ?? 0),
              gamesWon: oldWins ?? 0,
              currentStreak: oldStreak ?? 0,
              maxStreak: oldStreak ?? 0,
              guessDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0},
            );
            continue;
          }
        }
        _statsMap[mode.statsKey] = GameStats.empty();
      }
    }
    _statsMap['MULTIPLAYER'] = GameStats.empty();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statsMap[_selectedModeKey] ?? GameStats.empty();
    
    final dist = stats.guessDistribution;
    final gamesPlayed = stats.gamesPlayed;
    final gamesWon = stats.gamesWon;
    final currentStreak = stats.currentStreak;
    final maxStreak = stats.maxStreak;

    final winPercentage = gamesPlayed > 0
        ? ((gamesWon / gamesPlayed) * 100).round()
        : 0;

    int maxAttempts = 6;
    if (_selectedModeKey == 'DAILY_DUETO') {
      maxAttempts = 7;
    } else if (_selectedModeKey == 'DAILY_QUARTETO') {
      maxAttempts = 9;
    }

    // Encontra valor máximo para escalonar o gráfico de barras
    int maxBarValue = 1;
    dist.forEach((key, val) {
      if (val > maxBarValue) maxBarValue = val;
    });

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardBg.withValues(alpha: 0.8),
                AppColors.background.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.textWhite.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.correct),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ESTATÍSTICAS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.textWhite,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textGray,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // TabBar / Seletor de Modo de Jogo
                    DefaultTabController(
                      length: 5,
                      initialIndex: const ['DAILY', 'DAILY_DUETO', 'DAILY_QUARTETO', 'INFINITE', 'MULTIPLAYER'].indexOf(_selectedModeKey),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.center,
                            labelColor: AppColors.correct,
                            unselectedLabelColor: AppColors.textGray,
                            indicatorColor: AppColors.correct,
                            dividerColor: Colors.transparent,
                            onTap: (index) {
                              final keys = ['DAILY', 'DAILY_DUETO', 'DAILY_QUARTETO', 'INFINITE', 'MULTIPLAYER'];
                              setState(() {
                                _selectedModeKey = keys[index];
                              });
                            },
                            tabs: const [
                              Tab(text: 'TERMO'),
                              Tab(text: 'DUETO'),
                              Tab(text: 'QUARTETO'),
                              Tab(text: 'INFINITO'),
                              Tab(text: 'MULTIPLAYER'),
                            ],
                          ),
                          const Divider(
                            color: Color(0xFF2E2E32),
                            height: 16,
                            thickness: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid de estatísticas gerais
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(value: '$gamesPlayed', label: 'Jogos'),
                        _StatItem(value: '$winPercentage%', label: 'Vitórias'),
                        _StatItem(value: '$currentStreak', label: 'Seq. Atual'),
                        _StatItem(value: '$maxStreak', label: 'Max. Seq'),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DISTRIBUIÇÃO DE PALPITES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gráfico de Barras Horizontal Adaptável
                    if (_selectedModeKey == 'MULTIPLAYER')
                      const SizedBox(
                        height: 160,
                        child: Center(
                          child: Text(
                            'Sem dados. Modo em construção!',
                            style: TextStyle(
                              color: AppColors.textGray,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(maxAttempts, (index) {
                        final attemptNum = index + 1;
                        final count = dist[attemptNum] ?? 0;
                        final ratio = maxBarValue > 0
                            ? (count / maxBarValue)
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                '$attemptNum',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textWhite,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final maxWidth = constraints.maxWidth;
                                    final barWidth = ratio == 0.0
                                        ? 28.0 // largura mínima para renderizar o número 0
                                        : (maxWidth - 20) * ratio;

                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 600,
                                        ),
                                        curve: Curves.fastOutSlowIn,
                                        width: barWidth,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: ratio > 0.0
                                              ? AppColors.correct
                                              : AppColors.textGray.withValues(
                                                  alpha: 0.3,
                                                ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text(
                                          '$count',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textWhite,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textGray),
        ),
      ],
    );
  }
}
