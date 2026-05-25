import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';
import 'dart:developer';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final supabaseUrl = env['SUPABASE_URL']!;
  final supabaseKey = env['SUPABASE_ANON_KEY']!;

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  final today = DateTime.now().toIso8601String().substring(0, 10);
  log('Today is: $today', name: 'test_db');

  try {
    final response = await client
        .from('daily_challenges')
        .select()
        .eq('play_date', today)
        .limit(1)
        .single();
    final wordIds = response['word_ids'];
    log('Type of word_ids: ${wordIds.runtimeType}', name: 'test_db');
    log('Value: $wordIds', name: 'test_db');
  } catch (e) {
    log('Error: $e', name: 'test_db', error: e);
  }
  exit(0);
}
