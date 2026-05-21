import 'package:flutter_test/flutter_test.dart';
import 'package:termofication_app/features/game/presentation/cubit/game_cubit.dart';
import 'package:termofication_app/features/game/domain/entities/game_enums.dart';
import 'package:termofication_app/features/game/data/repositories/game_repository_impl.dart';
import 'package:termofication_app/features/game/data/datasources/game_remote_datasource.dart';
import 'package:termofication_app/core/network/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dotenv/dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:termofication_app/features/game/domain/usecases/submit_guess_usecase.dart';
import 'package:termofication_app/features/game/domain/usecases/get_random_word_usecase.dart';

void main() {
  test('Test GameCubit startGame', () async {
    var env = DotEnv(includePlatformEnvironment: true)..load();
    final supabaseUrl = env['SUPABASE_URL']!;
    final supabaseKey = env['SUPABASE_ANON_KEY']!;

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
    GetStorage.init();

    final dataSource = GameRemoteDataSourceImpl(ApiClient());
    final repository = GameRepositoryImpl(remoteDataSource: dataSource);
    
    final submitGuessUseCase = SubmitGuessUseCase(repository);
    final getRandomWordUseCase = GetRandomWordUseCase(repository);

    final cubit = GameCubit(
      submitGuessUseCase: submitGuessUseCase,
      getRandomWordUseCase: getRandomWordUseCase,
      repository: repository,
    );

    print('Calling startGame');
    await cubit.startGame(GameMode.dailyDueto);
    print('State after startGame: \${cubit.state.status}');
    if (cubit.state.status == GameStatus.error) {
      print('Error message: \${cubit.state.errorMessage}');
    }
  });
}
