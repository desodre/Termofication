import 'dart:developer' as developer;
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _clickPlayer = AudioPlayer();
  static final AudioPlayer _victoryPlayer = AudioPlayer();

  /// Toca o som de clique de botão. 
  /// Dá stop() primeiro para reiniciar o áudio caso seja clicado rapidamente.
  static Future<void> playClick() async {
    try {
      await _clickPlayer.stop();
      // await _clickPlayer.play(AssetSource('sounds/button_click.mp3'));
    } catch (e) {
      // Ignora falhas de áudio silenciosamente em produção
      developer.log('AudioService: Erro ao tocar som de clique: $e', name: 'AudioService', error: e);
    }
  }

  /// Toca o som de vitória (Mission Complete).
  static Future<void> playVictory() async {
    try {
      await _victoryPlayer.stop();
      await _victoryPlayer.play(AssetSource('sounds/mission_complete.mp3'));
    } catch (e) {
      // Ignora falhas de áudio silenciosamente em produção
      developer.log('AudioService: Erro ao tocar som de vitória: $e', name: 'AudioService', error: e);
    }
  }
}
