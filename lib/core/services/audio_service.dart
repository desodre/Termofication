import 'dart:developer' as developer;
import 'package:audioplayers/audioplayers.dart';
import 'package:get_storage/get_storage.dart';

class AudioService {
  static final AudioPlayer _clickPlayer = AudioPlayer();
  static final AudioPlayer _victoryPlayer = AudioPlayer();
  static final _storage = GetStorage();

  /// Toca o som de clique de botão. 
  /// Dá stop() primeiro para reiniciar o áudio caso seja clicado rapidamente.
  static Future<void> playClick() async {
    final bool clickEnabled = _storage.read<bool>('click_sound_enabled') ?? false;
    if (!clickEnabled) return;

    try {
      await _clickPlayer.stop();
      await _clickPlayer.play(AssetSource('sounds/click_sound.wav'));
    } catch (e) {
      // Ignora falhas de áudio silenciosamente em produção
      developer.log('AudioService: Erro ao tocar som de clique: $e', name: 'AudioService', error: e);
    }
  }

  /// Toca o som de vitória (Mission Complete).
  static Future<void> playVictory() async {
    final bool victoryEnabled = _storage.read<bool>('victory_sound_enabled') ?? true;
    if (!victoryEnabled) return;

    try {
      await _victoryPlayer.stop();
      await _victoryPlayer.play(AssetSource('sounds/mission_complete.wav'));
    } catch (e) {
      // Ignora falhas de áudio silenciosamente em produção
      developer.log('AudioService: Erro ao tocar som de vitória: $e', name: 'AudioService', error: e);
    }
  }
}
