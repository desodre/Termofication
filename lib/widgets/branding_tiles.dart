import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/audio_service.dart';
import '../features/game/domain/entities/game_enums.dart';
import '../features/game/presentation/widgets/letter_tile.dart';

class BrandingTiles extends StatefulWidget {
  final double tileSize;
  final double tilePadding;

  const BrandingTiles({
    super.key,
    this.tileSize = 48.0,
    this.tilePadding = 4.0,
  });

  @override
  State<BrandingTiles> createState() => _BrandingTilesState();
}

class _BrandingTilesState extends State<BrandingTiles> {
  final List<String> _letters = const ['t', 'e', 'r', 'm', 'o'];
  
  late List<LetterStatus> _statuses;
  late List<bool> _shouldBounce;
  
  int _clickCount = 0;
  Timer? _resetTimer;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  void _resetState() {
    _statuses = [
      LetterStatus.correct,
      LetterStatus.absent,
      LetterStatus.absent,
      LetterStatus.absent,
      LetterStatus.absent,
    ];
    _shouldBounce = [false, false, false, false, false];
    _isAnimating = false;
  }

  void _handleTap() {
    if (_isAnimating) return;

    // Play standard click sound
    AudioService.playClick();

    // Cancel existing reset timer
    _resetTimer?.cancel();

    _clickCount++;

    if (_clickCount == 7) {
      _triggerEasterEgg();
    } else {
      // Start timer to reset click count after 1.5 seconds of inactivity
      _resetTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _clickCount = 0;
        }
      });
    }
  }

  void _triggerEasterEgg() {
    setState(() {
      _isAnimating = true;
      _clickCount = 0;
    });

    // Play victory sound
    AudioService.playVictory();

    // Trigger the bounce and correct status sequentially in a wave
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          setState(() {
            _statuses[i] = LetterStatus.correct;
            _shouldBounce[i] = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.tilePadding),
            child: LetterTile(
              letter: _letters[index],
              status: _statuses[index],
              size: widget.tileSize,
              shouldBounce: _shouldBounce[index],
              animationDelay: Duration.zero,
            ),
          );
        }),
      ),
    );
  }
}
