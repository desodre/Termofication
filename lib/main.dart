import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/config/app_metadata.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/game/data/datasources/game_local_datasource.dart';
import 'features/game/data/repositories/game_repository_impl.dart';
import 'features/game/domain/usecases/get_random_word_usecase.dart';
import 'features/game/domain/usecases/submit_guess_usecase.dart';
import 'features/game/presentation/cubit/game_cubit.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty) {
    throw StateError(
      'As variáveis SUPABASE_URL e SUPABASE_ANON_KEY precisam estar definidas no .env',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Injeção de Dependências (Manual e Limpa)
  final packageInfo = await PackageInfo.fromPlatform();
  AppMetadata.initialize(
    version: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
  );
  final localDataSource = GameLocalDataSourceImpl();
  final repository = GameRepositoryImpl(localDataSource: localDataSource);
  final submitGuessUseCase = SubmitGuessUseCase(repository);
  final getRandomWordUseCase = GetRandomWordUseCase(repository);
  final authCubit = AuthCubit();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider(
          create: (_) => GameCubit(
            submitGuessUseCase: submitGuessUseCase,
            getRandomWordUseCase: getRandomWordUseCase,
            repository: repository,
            authCubit: authCubit,
          ),
        ),
      ],
      child: const TermoApp(),
    ),
  );
}

class TermoApp extends StatelessWidget {
  const TermoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Termofication',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
