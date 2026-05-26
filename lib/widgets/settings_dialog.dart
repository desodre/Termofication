import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../core/config/app_metadata.dart';
import '../core/theme/app_colors.dart';
import '../core/services/audio_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _storage = GetStorage();
  late bool _victorySound;
  late bool _clickSound;
  late bool _gradientsEnabled;

  @override
  void initState() {
    super.initState();
    _victorySound = _storage.read<bool>('victory_sound_enabled') ?? true;
    _clickSound = _storage.read<bool>('click_sound_enabled') ?? false;
    _gradientsEnabled = _storage.read<bool>('gradients_enabled') ?? true;
  }

  void _toggleVictorySound(bool value) {
    AudioService.playClick();
    setState(() {
      _victorySound = value;
      _storage.write('victory_sound_enabled', value);
    });
  }

  void _toggleClickSound(bool value) {
    setState(() {
      _clickSound = value;
      _storage.write('click_sound_enabled', value);
    });
    // Play sound immediately if turned on to give active feedback
    if (value) {
      AudioService.playClick();
    }
  }

  void _toggleGradients(bool value) {
    AudioService.playClick();
    setState(() {
      _gradientsEnabled = value;
      _storage.write('gradients_enabled', value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardBg.withValues(alpha: 0.85),
              AppColors.background.withValues(alpha: 0.98),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.textWhite.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Diálogo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CONFIGURAÇÕES',
                  style: TextStyle(
                    fontSize: 18,
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
                  onPressed: () {
                    AudioService.playClick();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Seção de Áudio
            const _SectionHeader(title: 'EFEITOS SONOROS'),
            const SizedBox(height: 8),
            _SettingSwitchTile(
              title: 'Som de Vitória',
              subtitle: 'Toca ao desvendar a palavra',
              value: _victorySound,
              onChanged: _toggleVictorySound,
              activeColor: AppColors.correct,
            ),
            _SettingSwitchTile(
              title: 'Som de Clique',
              subtitle: 'Sons de interação nos menus',
              value: _clickSound,
              onChanged: _toggleClickSound,
              activeColor: AppColors.present,
            ),
            const SizedBox(height: 20),

            // Seção Visual
            const _SectionHeader(title: 'VISUAL E APARÊNCIA'),
            const SizedBox(height: 8),
            _SettingSwitchTile(
              title: 'Gradientes Temáticos',
              subtitle: 'Fundo ambientado por modo',
              value: _gradientsEnabled,
              onChanged: _toggleGradients,
              activeColor: AppColors.correct,
            ),
            const SizedBox(height: 24),

            // Divisor
            Container(
              height: 1,
              width: double.infinity,
              color: AppColors.textWhite.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),

            // Créditos e Versão
            Center(
              child: Column(
                children: [
                  Text(
                    AppMetadata.appVersionLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Feito com 💚 por @_desodre',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textGray.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.correct,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _SettingSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withValues(alpha: 0.25),
            inactiveThumbColor: AppColors.textGray,
            inactiveTrackColor: AppColors.absent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
