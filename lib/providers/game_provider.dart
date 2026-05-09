import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import '../models/game_enums.dart';
import '../models/guess_result.dart';
import '../services/api_service.dart';

class GameProvider extends ChangeNotifier {
  final _api = ApiService();
  final _storage = GetStorage();

  GameMode _mode = GameMode.daily;
  GameStatus _status = GameStatus.loading;
  String _targetWord = '';
  String _currentGuess = '';
  List<GuessResult> _guesses = [];
  Map<String, LetterStatus> _keyboardState = {};
  String? _errorMessage;
  bool _isSubmitting = false;

  int _infiniteWins = 0;
  int _infiniteLosses = 0;
  int _currentStreak = 0;

  static const int maxAttempts = 6;
  static const int wordLength = 5;

  GameMode get mode => _mode;
  GameStatus get status => _status;
  String get targetWord => _targetWord;
  String get currentGuess => _currentGuess;
  List<GuessResult> get guesses => List.unmodifiable(_guesses);
  Map<String, LetterStatus> get keyboardState => Map.unmodifiable(_keyboardState);
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  int get infiniteWins => _infiniteWins;
  int get infiniteLosses => _infiniteLosses;
  int get currentStreak => _currentStreak;

  Future<void> startGame(GameMode mode) async {
    _mode = mode;
    _status = GameStatus.loading;
    _currentGuess = '';
    _guesses = [];
    _keyboardState = {};
    _errorMessage = null;
    _isSubmitting = false;
    notifyListeners();

    try {
      if (mode == GameMode.daily) {
        await _startDailyGame();
      } else {
        await _startInfiniteGame();
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar. Verifique a conexão com o servidor.';
      _status = GameStatus.playing;
      notifyListeners();
    }
  }

  Future<void> _startDailyGame() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = _storage.read<String>('daily_date');

    if (storedDate == today) {
      _targetWord = _storage.read<String>('daily_word') ?? '';
      final savedGuesses = _storage.read<List>('daily_guesses');
      if (savedGuesses != null && savedGuesses.isNotEmpty) {
        _guesses = savedGuesses
            .map((g) => GuessResult.fromJson(Map<String, dynamic>.from(g as Map)))
            .toList();
        _rebuildKeyboardState();
      }
      final savedStatus = _storage.read<String>('daily_status');
      _status = _statusFromString(savedStatus) ?? GameStatus.playing;
    } else {
      _targetWord = await _api.getRandomWord(length: wordLength);
      await _storage.write('daily_date', today);
      await _storage.write('daily_word', _targetWord);
      await _storage.write('daily_guesses', <dynamic>[]);
      await _storage.write('daily_status', 'playing');
      _status = GameStatus.playing;
    }
    notifyListeners();
  }

  Future<void> _startInfiniteGame() async {
    _targetWord = await _api.getRandomWord(length: wordLength);
    _infiniteWins = _storage.read<int>('infinite_wins') ?? 0;
    _infiniteLosses = _storage.read<int>('infinite_losses') ?? 0;
    _currentStreak = _storage.read<int>('infinite_streak') ?? 0;
    _status = GameStatus.playing;
    notifyListeners();
  }

  void addLetter(String letter) {
    if (_status != GameStatus.playing) return;
    if (_currentGuess.length >= wordLength) return;
    if (_isSubmitting) return;
    _currentGuess += letter.toLowerCase();
    _errorMessage = null;
    notifyListeners();
  }

  void removeLetter() {
    if (_currentGuess.isEmpty) return;
    if (_isSubmitting) return;
    _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> submitGuess() async {
    if (_status != GameStatus.playing) return;
    if (_currentGuess.length < wordLength) {
      _errorMessage = 'Palavra incompleta';
      notifyListeners();
      return;
    }
    if (_isSubmitting) return;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.submitGuess(_currentGuess, _targetWord);
      _guesses.add(result);
      _currentGuess = '';
      _updateKeyboardState(result);

      if (result.isCorrect) {
        _status = GameStatus.won;
        _onGameEnd(won: true);
      } else if (_guesses.length >= maxAttempts) {
        _status = GameStatus.lost;
        _onGameEnd(won: false);
      }

      if (_mode == GameMode.daily) {
        _saveDailyState();
      }
    } catch (e) {
      _errorMessage = 'Palavra inválida ou não encontrada no dicionário';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _onGameEnd({required bool won}) {
    if (_mode == GameMode.infinite) {
      if (won) {
        _infiniteWins++;
        _currentStreak++;
      } else {
        _infiniteLosses++;
        _currentStreak = 0;
      }
      _storage.write('infinite_wins', _infiniteWins);
      _storage.write('infinite_losses', _infiniteLosses);
      _storage.write('infinite_streak', _currentStreak);
    }
  }

  void _saveDailyState() {
    _storage.write('daily_guesses', _guesses.map((g) => g.toJson()).toList());
    _storage.write('daily_status', _status.name);
  }

  void _updateKeyboardState(GuessResult result) {
    for (final fb in result.feedback) {
      final current = _keyboardState[fb.letter];
      if (current == LetterStatus.correct) continue;
      if (current == LetterStatus.present && fb.status == LetterStatus.absent) {
        continue;
      }
      _keyboardState[fb.letter] = fb.status;
    }
  }

  void _rebuildKeyboardState() {
    _keyboardState = {};
    for (final guess in _guesses) {
      _updateKeyboardState(guess);
    }
  }

  GameStatus? _statusFromString(String? s) {
    switch (s) {
      case 'playing':
        return GameStatus.playing;
      case 'won':
        return GameStatus.won;
      case 'lost':
        return GameStatus.lost;
      default:
        return null;
    }
  }
}
