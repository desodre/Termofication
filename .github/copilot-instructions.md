# Copilot Instructions — termofication_app

Flutter app do jogo **Termo** com arquitetura por features (Clean-ish) + **BLoC/Cubit**.  
Hoje o core do jogo usa **Supabase** (tabelas `daily_challenges` e `valid_words`) e persistência local com **GetStorage**.

---

## Commands

```bash
# Dependências
flutter pub get

# App
flutter run

# Análise estática
flutter analyze

# Testes
flutter test

# Teste específico
flutter test test/widget_test.dart
```

---

## Arquitetura atual

### Estado global e DI
- O app inicia em `lib/main.dart`.
- Providers globais:
  - `BlocProvider<GameCubit>`
  - `BlocProvider<AuthCubit>`
- Injeção manual de dependências em `main.dart`:
  - `ApiClient` → `GameRemoteDataSourceImpl` → `GameRepositoryImpl`
  - `SubmitGuessUseCase` / `GetRandomWordUseCase`

### Fluxo principal
```text
UI (BlocBuilder/BlocListener)
  → GameCubit
  → UseCases
  → GameRepository
  → GameRemoteDataSource (Supabase)
```

### Navegação
- Fonte única: `lib/routes/app_routes.dart`.
- Rotas nomeadas:
  - `/` (`HomeScreen`)
  - `/game/daily` (`GameDesktopScreen(mode: GameMode.daily)`)
  - `/game/infinite` (`GameDesktopScreen(mode: GameMode.infinite)`)
- `Navigator.pushNamed` é o padrão.

---

## Convenções importantes

### BLoC/Cubit (não Provider)
- Use `BlocBuilder` para render e `BlocListener` para efeitos colaterais.
- Em callbacks/eventos, use `context.read<GameCubit>()` / `context.read<AuthCubit>()`.
- Não reintroduzir `ChangeNotifier`/`Provider` para o fluxo principal.

### Inicialização de jogo
- Em `GameDesktopScreen`, `startGame(mode)` é chamado via `WidgetsBinding.instance.addPostFrameCallback` no `initState`.
- Mantenha esse padrão para evitar acesso prematuro ao contexto.

### Variáveis de ambiente (Supabase)
- `main.dart` carrega `.env` com `flutter_dotenv`.
- Chaves obrigatórias:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
- Se ausentes, o app lança `StateError` no bootstrap.

### Lógica de jogo
- Constantes oficiais:
  - `GameCubit.maxAttempts = 6`
  - `GameCubit.wordLength = 5`
- Prioridade de cor do teclado (nunca downgrade), em `_updateKeyboardColors()`:
  - `correct` nunca é sobrescrito
  - `present` não é substituído por `absent`

### Persistência local (GetStorage)
- Jogo diário:
  - `daily_date`, `daily_word_id`, `daily_word`, `daily_guesses`, `daily_status`
- Estatísticas infinito:
  - `infinite_wins`, `infinite_losses`, `infinite_streak`

### Modos de jogo
- `GameMode` possui: `daily`, `dailyDueto`, `dailyQuarteto`, `infinite`.
- UI/rotas expõem atualmente `daily` e `infinite`.
- `GameModeExtension.supabaseKey` mapeia:
  - `daily`/`infinite` → `TERMO`
  - `dailyDueto` → `DUETO`
  - `dailyQuarteto` → `QUARTETO`

### Idioma e UX
- Strings de UI em português (pt-BR).
- Componentes visuais privados e específicos devem ficar no mesmo arquivo (`_ClassePrivada`).

### Paleta
- `correct` `#538D4E`
- `present` `#B59F3B`
- `absent` `#3A3A3C`
- `unknown` `#818384`
- `background` `#121213`
- `cardBg` `#1A1A1B`

---

## Backends e integração

### Supabase (principal do jogo)
- Desafio diário: consulta `daily_challenges` por `play_date` + `game_mode`.
- Dicionário e alvo: tabela `valid_words`.
- `submitGuess` valida palavra no dicionário e aplica feedback localmente (`correct/present/absent`).

### FastAPI (uso pontual)
- `StatsDialog` busca estatísticas remotas em `GET http://127.0.0.1:8000/api/v1/stats` quando usuário autenticado.
- Para usuário anônimo, usa dados locais do GetStorage.

### ApiClient
- Base URL padrão:
  - Web/Desktop: `http://127.0.0.1:8000`
  - Android/iOS: `http://192.168.0.104:8000`
- Exceções padronizadas:
  - `InvalidWordException`
  - `NetworkException`
  - `ServerException`

---

## Testes

- `test/features/game/presentation/cubit/game_cubit_test.dart` cobre fluxo principal do `GameCubit`.
- `test/features/game/data/models/guess_result_model_test.dart` cobre serialização/desserialização de modelos.
- `test/widget_test.dart` é smoke test placeholder.
