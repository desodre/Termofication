import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import 'package:get_storage/get_storage.dart';

class StatsDialog extends StatefulWidget {
  const StatsDialog({super.key});

  @override
  State<StatsDialog> createState() => _StatsDialogState();
}

class _StatsDialogState extends State<StatsDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final authState = context.read<AuthCubit>().state;
    
    if (authState is UserAuthAuthenticated) {
      // Busca estatísticas do FastAPI
      try {
        final dio = Dio();
        final response = await dio.get(
          '${ApiClient.baseUrl}/api/v1/stats',
          options: Options(
            headers: {'Authorization': 'Bearer ${authState.accessToken}'},
          ),
        );
        setState(() {
          _stats = response.data as Map<String, dynamic>;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Falha ao sincronizar estatísticas remotas.';
          _isLoading = false;
        });
      }
    } else {
      // Busca estatísticas locais do GetStorage (Modo Anônimo)
      final storage = GetStorage();
      final int wins = storage.read<int>('infinite_wins') ?? 0;
      final int losses = storage.read<int>('infinite_losses') ?? 0;
      final int streak = storage.read<int>('infinite_streak') ?? 0;
      
      setState(() {
        _stats = {
          "games_played": wins + losses,
          "games_won": wins,
          "current_streak": streak,
          "max_streak": streak,
          "guess_distribution": {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0, "6": 0}
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dist = _stats['guess_distribution'] as Map<dynamic, dynamic>? ?? {};
    final gamesPlayed = _stats['games_played'] as int? ?? 0;
    final gamesWon = _stats['games_won'] as int? ?? 0;
    final currentStreak = _stats['current_streak'] as int? ?? 0;
    final maxStreak = _stats['max_streak'] as int? ?? 0;
    
    final winPercentage = gamesPlayed > 0 ? ((gamesWon / gamesPlayed) * 100).round() : 0;
    
    // Encontra valor máximo para escalonar o gráfico de barras
    int maxBarValue = 1;
    dist.forEach((key, val) {
      final int v = int.tryParse(val.toString()) ?? 0;
      if (v > maxBarValue) maxBarValue = v;
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
              )
            ],
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(color: AppColors.correct)),
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
                          icon: const Icon(Icons.close_rounded, color: AppColors.textGray),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    
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
                    
                    // Gráfico de Barras Horizontal
                    ...List.generate(6, (index) {
                      final attemptNum = '${index + 1}';
                      final count = int.tryParse(dist[attemptNum]?.toString() ?? '0') ?? 0;
                      final ratio = maxBarValue > 0 ? (count / maxBarValue) : 0.0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              attemptNum,
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
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.fastOutSlowIn,
                                      width: barWidth,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: ratio > 0.0 ? AppColors.correct : AppColors.textGray.withValues(alpha: 0.3),
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
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}
