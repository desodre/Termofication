import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final supabaseUrl = env['SUPABASE_URL']!;
  final supabaseKey = env['SUPABASE_ANON_KEY']!;

  final client = SupabaseClient(supabaseUrl, supabaseKey);
  
  final today = DateTime.now().toIso8601String().substring(0, 10);
  print('Today is: ' + today);
  
  try {
    final response = await client
        .from('daily_challenges')
        .select()
        .eq('play_date', today)
        .limit(1)
        .single();
    final wordIds = response['word_ids'];
    print('Type of word_ids: ' + wordIds.runtimeType.toString());
    print('Value: ' + wordIds.toString());
  } catch (e) {
    print('Error: ' + e.toString());
  }
  exit(0);
}
