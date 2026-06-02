import 'dart:developer' as developer;
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:get_storage/get_storage.dart';

class AudioService {
  static final AudioPlayer _clickPlayer = AudioPlayer();
  static final AudioPlayer _victoryPlayer = AudioPlayer();
  static final AudioPlayer _defeatPlayer = AudioPlayer();
  static final AudioPlayer _typingPlayer = AudioPlayer();
  static final AudioPlayer _backspacePlayer = AudioPlayer();
  static final AudioPlayer _snapPlayer = AudioPlayer();
  static final AudioPlayer _errorPlayer = AudioPlayer();

  static bool _readBool(String key, bool defaultValue) {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return defaultValue;
      }
      return GetStorage().read<bool>(key) ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Toca o som de clique de botão. 
  /// Dá stop() primeiro para reiniciar o áudio caso seja clicado rapidamente.
  static Future<void> playClick() async {
    final bool clickEnabled = _readBool('click_sound_enabled', true);
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
    final bool victoryEnabled = _readBool('victory_sound_enabled', true);
    if (!victoryEnabled) return;

    try {
      await _victoryPlayer.stop();
      await _victoryPlayer.play(AssetSource('sounds/mission_complete.wav'));
    } catch (e) {
      // Ignora falhas de áudio silenciosamente em produção
      developer.log('AudioService: Erro ao tocar som de vitória: $e', name: 'AudioService', error: e);
    }
  }

  /// Toca o som de derrota.
  static Future<void> playDefeat() async {
    final bool victoryEnabled = _readBool('defeat_sound_enabled', true);
    if (!victoryEnabled) return;

    try {
      await _defeatPlayer.stop();
      await _defeatPlayer.play(AssetSource('sounds/defeat.wav'));
    } catch (e) {
      // Ignora falhas de áudio silenciosamente em produção
      developer.log('AudioService: Erro ao tocar som de derrota: $e', name: 'AudioService', error: e);
    }
  }

  /// Toca o som de digitação rápida de letra.
  static Future<void> playTyping() async {
    final bool clickEnabled = _readBool('typing_sound_enabled', true);
    if (!clickEnabled) return;

    try {
      await _typingPlayer.stop();
      await _typingPlayer.play(AssetSource('sounds/typing_tap.wav'));
    } catch (e) {
      // Ignora falhas de áudio silenciosamente em produção
      developer.log('AudioService: Erro ao tocar som de digitação: $e', name: 'AudioService', error: e);
    }
  }

  /// Toca o som de apagar letra (Backspace).
  static Future<void> playBackspace() async {
    final bool clickEnabled = _readBool('backspace_sound_enabled', true);
    if (!clickEnabled) return;

    try {
      await _backspacePlayer.stop();
      await _backspacePlayer.play(AssetSource('sounds/backspace.wav'));
    } catch (e) {
      // Ignora falhas de áudio silenciosamente em produção
      developer.log('AudioService: Erro ao tocar som de backspace: $e', name: 'AudioService', error: e);
    }
  }

  /// Toca o som de encaixe de letras (Replicação com duplo clique).
  static Future<void> playSnap() async {
    final bool clickEnabled = _readBool('snap_sound_enabled', true);
    if (!clickEnabled) return;

    try {
      await _snapPlayer.stop();
      await _snapPlayer.play(AssetSource('sounds/snap.wav'));
    } catch (e) {
      // Ignora falhas de áudio silenciosamente em produção
      developer.log('AudioService: Erro ao tocar som de snap: $e', name: 'AudioService', error: e);
    }
  }

  /// Toca o som de erro (Buzz de palavra incompleta/inválida).
  static Future<void> playError() async {
    final bool clickEnabled = _readBool('error_sound_enabled', true);
    if (!clickEnabled) return;

    try {
      await _errorPlayer.stop();
      await _errorPlayer.play(AssetSource('sounds/error.wav'));
    } catch (e) {
      // Ignora falhas de áudio silenciosamente em produção
      developer.log('AudioService: Erro ao tocar som de erro: $e', name: 'AudioService', error: e);
    }
  }
}
