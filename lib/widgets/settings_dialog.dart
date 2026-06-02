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
  late bool _defeatSound;
  late bool _typingSound;
  late bool _backspaceSound;
  late bool _clickSound;
  late bool _snapSound;
  late bool _errorSound;
  late bool _gradientsEnabled;
  late bool _animationsEnabled;

  @override
  void initState() {
    super.initState();
    _victorySound = _storage.read<bool>('victory_sound_enabled') ?? true;
    _defeatSound = _storage.read<bool>('defeat_sound_enabled') ?? true;
    _typingSound = _storage.read<bool>('typing_sound_enabled') ?? true;
    _backspaceSound = _storage.read<bool>('backspace_sound_enabled') ?? true;
    _clickSound = _storage.read<bool>('click_sound_enabled') ?? true;
    _snapSound = _storage.read<bool>('snap_sound_enabled') ?? true;
    _errorSound = _storage.read<bool>('error_sound_enabled') ?? true;
    _gradientsEnabled = _storage.read<bool>('gradients_enabled') ?? true;
    _animationsEnabled = _storage.read<bool>('animations_enabled') ?? true;
  }

  void _toggleVictorySound(bool value) {
    AudioService.playClick();
    setState(() {
      _victorySound = value;
      _storage.write('victory_sound_enabled', value);
    });
  }

  void _toggleDefeatSound(bool value) {
    AudioService.playClick();
    setState(() {
      _defeatSound = value;
      _storage.write('defeat_sound_enabled', value);
    });
  }

  void _toggleTypingSound(bool value) {
    setState(() {
      _typingSound = value;
      _storage.write('typing_sound_enabled', value);
    });
    if (value) {
      AudioService.playTyping();
    }
  }

  void _toggleBackspaceSound(bool value) {
    setState(() {
      _backspaceSound = value;
      _storage.write('backspace_sound_enabled', value);
    });
    if (value) {
      AudioService.playBackspace();
    }
  }

  void _toggleClickSound(bool value) {
    setState(() {
      _clickSound = value;
      _storage.write('click_sound_enabled', value);
    });
    if (value) {
      AudioService.playClick();
    }
  }

  void _toggleSnapSound(bool value) {
    setState(() {
      _snapSound = value;
      _storage.write('snap_sound_enabled', value);
    });
    if (value) {
      AudioService.playSnap();
    }
  }

  void _toggleErrorSound(bool value) {
    setState(() {
      _errorSound = value;
      _storage.write('error_sound_enabled', value);
    });
    if (value) {
      AudioService.playError();
    }
  }

  void _toggleGradients(bool value) {
    AudioService.playClick();
    setState(() {
      _gradientsEnabled = value;
      _storage.write('gradients_enabled', value);
    });
  }

  void _toggleAnimations(bool value) {
    AudioService.playClick();
    setState(() {
      _animationsEnabled = value;
      _storage.write('animations_enabled', value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 380,
        height: 520, // Limita altura máxima para visualização responsiva
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
            const SizedBox(height: 12),

            // Corpo com scroll para evitar overflow
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      title: 'Som de Derrota',
                      subtitle: 'Toca ao esgotar as tentativas',
                      value: _defeatSound,
                      onChanged: _toggleDefeatSound,
                      activeColor: AppColors.absent,
                    ),
                    _SettingSwitchTile(
                      title: 'Som de Digitação',
                      subtitle: 'Bip sutil ao inserir letras',
                      value: _typingSound,
                      onChanged: _toggleTypingSound,
                      activeColor: AppColors.present,
                    ),
                    _SettingSwitchTile(
                      title: 'Som de Backspace',
                      subtitle: 'Bip sutil ao apagar letras',
                      value: _backspaceSound,
                      onChanged: _toggleBackspaceSound,
                      activeColor: AppColors.present,
                    ),
                    _SettingSwitchTile(
                      title: 'Som de Clique (Menus)',
                      subtitle: 'Sons de navegação nos botões',
                      value: _clickSound,
                      onChanged: _toggleClickSound,
                      activeColor: AppColors.present,
                    ),
                    _SettingSwitchTile(
                      title: 'Som de Replicação',
                      subtitle: 'Sons de duplo clique nos tabuleiros',
                      value: _snapSound,
                      onChanged: _toggleSnapSound,
                      activeColor: AppColors.correct,
                    ),
                    _SettingSwitchTile(
                      title: 'Som de Alerta (Erro)',
                      subtitle: 'Som de alerta ao errar palpite',
                      value: _errorSound,
                      onChanged: _toggleErrorSound,
                      activeColor: AppColors.absent,
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
                    _SettingSwitchTile(
                      title: 'Animações de Acerto',
                      subtitle: 'Efeito de salto nas letras ao acertar',
                      value: _animationsEnabled,
                      onChanged: _toggleAnimations,
                      activeColor: AppColors.correct,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
