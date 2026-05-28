import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/services/audio_service.dart';

class MenuButton extends StatefulWidget {
  final VoidCallback onTap;
  const MenuButton({super.key, required this.onTap});

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        AudioService.playClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.textWhite.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textWhite.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.menu_rounded,
            color: AppColors.textWhite,
            size: 22,
          ),
        ),
      ),
    );
  }
}
