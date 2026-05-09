import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/guess_result.dart';

class ApiService {
  static const _base = 'http://127.0.0.1:8000';
  final _client = http.Client();

  Future<String> getRandomWord({int length = 5}) async {
    final resp = await _client
        .get(Uri.parse('$_base/word/random/$length'))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['words'] as String;
    }
    throw Exception('Failed to fetch random word: ${resp.statusCode}');
  }

  Future<bool> validateWord(String word) async {
    final resp = await _client
        .get(Uri.parse('$_base/validate/$word'))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['is_valid'] as bool;
    }
    return false;
  }

  Future<GuessResult> submitGuess(String guess, String target) async {
    final resp = await _client
        .post(
          Uri.parse('$_base/game/guess'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'guess': guess, 'target': target}),
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      return GuessResult.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Invalid guess');
  }
}
