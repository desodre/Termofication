import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/config/app_metadata.dart';
import '../core/theme/app_colors.dart';
import '../core/services/audio_service.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/game/presentation/widgets/stats_dialog.dart';
import '../routes/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xE6161618), // 90% opaque dark
                Color(0xF2101012), // 95% opaque darker
              ],
            ),
            border: Border(
              right: BorderSide(
                color: AppColors.correct.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header com branding ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.correct.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.correct.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Text(
                          'T',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.correct,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TERMOFICATION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textWhite,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Jogo de Palavras',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textGray.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Divider sutil ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.textGray.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Seção de Conta / Auth ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BlocBuilder<AuthCubit, UserAuthState>(
                    builder: (context, state) {
                      if (state is UserAuthLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.correct,
                              ),
                            ),
                          ),
                        );
                      }

                      if (state is UserAuthAuthenticated) {
                        return _AuthenticatedSection(state: state);
                      }

                      return _UnauthenticatedSection(state: state);
                    },
                  ),
                ),

                // ── Divider ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.textGray.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Navegação ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      _DrawerNavItem(
                        icon: Icons.home_rounded,
                        label: 'Início',
                        subtitle: 'Tela principal',
                        themeColor: AppColors.correct,
                        onTap: () {
                          AudioService.playClick();
                          Navigator.pop(context); // fecha drawer
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.home,
                            (route) => false,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      _DrawerNavItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'Estatísticas',
                        subtitle: 'Seu desempenho geral',
                        themeColor: AppColors.present,
                        onTap: () {
                          AudioService.playClick();
                          Navigator.pop(context); // fecha drawer
                          showDialog(
                            context: context,
                            builder: (_) => const StatsDialog(),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      _DrawerNavItem(
                        icon: Icons.settings_rounded,
                        label: 'Configurações',
                        subtitle: 'Preferências do app',
                        themeColor: AppColors.unknown,
                        onTap: () {
                          AudioService.playClick();
                          Navigator.pop(context);
                          // TODO: Navegar para tela de configurações
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Configurações em breve!',
                                style: .new(color: AppColors.textWhite),
                              ),
                              backgroundColor: AppColors.absent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Rodapé ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Text(
                    '${AppMetadata.appVersionLabel} • Feito com 💚 por @_desodre',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textGray.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Seção do usuário autenticado ──
class _AuthenticatedSection extends StatelessWidget {
  final UserAuthAuthenticated state;
  const _AuthenticatedSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = state.user.userMetadata?['avatar_url'] as String?;
    final fullName =
        state.user.userMetadata?['full_name'] as String? ?? 'Jogador';
    final email = state.user.email ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.correct.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.correct.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                backgroundColor: AppColors.correct.withValues(alpha: 0.2),
                child: avatarUrl == null
                    ? const Icon(
                        Icons.person_rounded,
                        size: 22,
                        color: AppColors.textWhite,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textGray.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                AudioService.playClick();
                Navigator.pop(context);
                context.read<AuthCubit>().logout();
              },
              icon: Icon(
                Icons.logout_rounded,
                size: 16,
                color: Colors.redAccent.withValues(alpha: 0.8),
              ),
              label: Text(
                'Sair da Conta',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent.withValues(alpha: 0.8),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seção de usuário não autenticado ──
class _UnauthenticatedSection extends StatelessWidget {
  final UserAuthState state;
  const _UnauthenticatedSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textGray.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textGray.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Avatar placeholder
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.textGray.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 28,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Jogador Anônimo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Entre para salvar estatísticas',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textGray.withValues(alpha: 0.7),
            ),
          ),
          if (state is UserAuthError) ...[
            const SizedBox(height: 8),
            Text(
              (state as UserAuthError).message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),

          // Botão Google Login
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                AudioService.playClick();
                Navigator.pop(context);
                context.read<AuthCubit>().loginWithGoogle();
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ENTRAR COM GOOGLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/icons/Google _G_ Logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Jogar anônimo
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                AudioService.playClick();
                context.read<AuthCubit>().playAnonymously();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: AppColors.textGray.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: const Text(
                'Jogar Anônimo',
                style: TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item de navegação do drawer ──
class _DrawerNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color themeColor;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.themeColor,
    required this.onTap,
  });

  @override
  State<_DrawerNavItem> createState() => _DrawerNavItemState();
}

class _DrawerNavItemState extends State<_DrawerNavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.themeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: widget.themeColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textGray.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGray.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
