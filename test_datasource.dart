import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';
import 'dart:developer';

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  @override
  String toString() => message;
}

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final supabaseUrl = env['SUPABASE_URL']!;
  final supabaseKey = env['SUPABASE_ANON_KEY']!;

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  final gameMode = 'DUETO';
  final expectedWordCount = 2;
  final today = DateTime.now().toIso8601String().substring(0, 10);

  log(
    'Testing getDailyChallenge for \$gameMode on \$today',
    name: 'test_datasource',
  );

  try {
    final response = await client
        .from('daily_challenges')
        .select()
        .eq('play_date', today)
        .eq('game_mode', gameMode)
        .maybeSingle();

    log('Supabase response: $response', name: 'test_datasource');
    if (response != null) {
      final wordIds = (response['word_ids'] as List<dynamic>)
          .map((e) => e as int)
          .toList();
      log('Parsed wordIds: $wordIds', name: 'test_datasource');
      if (wordIds.isNotEmpty) {
        final selectedWordIds = wordIds.take(expectedWordCount).toList();
        final wordId = selectedWordIds[0];

        final wordResp = await client
            .from('valid_words')
            .select('length')
            .eq('id', wordId)
            .single();

        final length = wordResp['length'] as int;
        log(
          'Success! length: \$length, wordIds: \$selectedWordIds',
          name: 'test_datasource',
        );
        exit(0);
      }
    }
  } catch (e, st) {
    log(
      'Error caught during Supabase block: $e',
      name: 'test_datasource',
      error: e,
      stackTrace: st,
    );
  }

  log('Fell back to getRandomChallenge', name: 'test_datasource');

  try {
    final response = await client
        .from('valid_words')
        .select('id')
        .eq('length', 5)
        .eq('is_target', true);

    final List<dynamic> wordsList = response as List<dynamic>;
    if (wordsList.length < expectedWordCount) {
      throw ServerException('Palavras insuficientes.');
    }

    final nowSeed = DateTime.now().millisecondsSinceEpoch;
    final selectedWordIds = <int>[];
    final used = <int>{};
    var cursor = 0;
    while (selectedWordIds.length < expectedWordCount &&
        cursor < wordsList.length) {
      final idx = (nowSeed + cursor * 997) % wordsList.length;
      final id = wordsList[idx]['id'] as int;
      if (used.add(id)) {
        selectedWordIds.add(id);
      }
      cursor++;
    }

    log(
      'Success fallback! wordIds: \$selectedWordIds',
      name: 'test_datasource',
    );
  } catch (e, st) {
    log(
      'Fallback failed: $e',
      name: 'test_datasource',
      error: e,
      stackTrace: st,
    );
  }
  exit(0);
}
