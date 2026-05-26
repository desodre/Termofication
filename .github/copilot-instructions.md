# Copilot Instructions — termofication_app

Flutter app do jogo **Termo** com arquitetura por features (Clean-ish) e estado com **BLoC/Cubit**.

> Importante: o `README.md` atual esta desatualizado em partes (ex.: mencoes a Provider/http). Para decisões tecnicas, priorize o codigo em `lib/`.

---

## Commands

```bash
# Dependencias
flutter pub get

# Rodar app
flutter run

# Analise estatica
flutter analyze

# Todos os testes
flutter test

# Teste especifico
flutter test test/widget_test.dart
```

---

## Arquitetura real (estado atual)

### Bootstrap e DI
- Entrada em `lib/main.dart`.
- Inicializa:
  - `GetStorage.init()`
  - `.env` via `flutter_dotenv`
  - `Supabase.initialize(url, anonKey)`
  - `AppMetadata` via `package_info_plus`
- DI manual:
  - `GameLocalDataSourceImpl` -> `GameRepositoryImpl`
  - `SubmitGuessUseCase` / `GetRandomWordUseCase`
  - `AuthCubit` e `GameCubit` em `MultiBlocProvider`

### Fluxo principal do jogo
```text
UI (BlocBuilder/BlocListener)
  -> GameCubit
  -> UseCases
  -> GameRepository
  -> GameLocalDataSource (SQLite asset words.db via sqflite)
```

### Navegacao
Fonte unica: `lib/routes/app_routes.dart` com `Navigator.pushNamed`.

Rotas:
- `/` -> `HomeScreen`
- `/game/daily/select` -> `DailyModeSelectionScreen`
- `/game/daily` -> `GameDesktopScreen(mode: daily)`
- `/game/daily/dueto` -> `GameDesktopScreen(mode: dailyDueto)`
- `/game/daily/quarteto` -> `GameDesktopScreen(mode: dailyQuarteto)`
- `/game/infinite` -> `GameDesktopScreen(mode: infinite)`

---

## Modos de jogo e regras

`GameMode`: `daily`, `dailyDueto`, `dailyQuarteto`, `infinite`.

- `wordLength` oficial: **5** (`GameCubit.wordLength`)
- Tentativas por modo (`GameCubit.maxAttemptsForMode`):
  - `daily` e `infinite`: **6**
  - `dailyDueto`: **7**
  - `dailyQuarteto`: **9**
- `wordCount` por modo:
  - `daily`/`infinite`: 1 tabuleiro
  - `dailyDueto`: 2 tabuleiros
  - `dailyQuarteto`: 4 tabuleiros

---

## Dados e persistencia

### Core do jogo (offline-first local)
- O dicionario e palavras-alvo vem de `assets/words.db`.
- `GameLocalDataSourceImpl` copia o DB de asset para armazenamento local (`words_v2.db`) e consulta a tabela `valid_words`.
- `submitGuess` valida palavra e feedback localmente (sem chamada HTTP para gameplay).
- Comparacao considera normalizacao de acentos (`normalizePortuguese`).

### GetStorage
- Diario por modo (prefixo `daily_${mode.supabaseKey.toLowerCase()}`):
  - `${prefix}_date`
  - `${prefix}_word_ids`
  - `${prefix}_target_words`
  - `${prefix}_board_guesses`
  - `${prefix}_board_completed`
  - `${prefix}_status`
  - `${prefix}_keyboard_colors`
- Retrocompatibilidade modo diario legado:
  - `daily_date`, `daily_word_id`, `daily_word`, `daily_guesses`, `daily_status`
- Infinito:
  - `infinite_wins`, `infinite_losses`, `infinite_streak`
- Configuracoes:
  - `victory_sound_enabled`, `click_sound_enabled`, `gradients_enabled`

---

## Supabase (uso atual)

Supabase **nao** e a fonte principal do gameplay atual. E usado para:

1. **Autenticacao**
   - `AuthCubit` escuta `onAuthStateChange`
   - login Google via `signInWithOAuth`
   - logout via `signOut`
   - redirect OAuth: `termofication://login-callback`

2. **Estatisticas remotas** (`user_stats`)
   - `GameRepositoryImpl.syncInfiniteStats()` puxa stats remotas para local
   - `GameRepositoryImpl.recordGame()` faz upsert em `user_stats`
   - `StatsDialog` tenta leitura remota; se falhar/anonimo, usa fallback local (GetStorage)

---

## Convencoes de implementacao

### Estado/UI
- Nao reintroduzir `Provider`/`ChangeNotifier` no fluxo principal.
- Usar `BlocBuilder` para render e `BlocListener` para side-effects.
- Em callbacks, usar `context.read<GameCubit>()` / `context.read<AuthCubit>()`.
- Em `GameDesktopScreen`, iniciar jogo com `startGame(mode)` via `addPostFrameCallback` no `initState`.

### Multi-board (dueto/quarteto)
- Respeitar estruturas por tabuleiro:
  - `boardGuesses`
  - `boardKeyboardColors`
  - `boardCompleted`
- Teclado virtual usa cor por letra por tabuleiro (split visual em 2/4 quadrantes).

### Prioridade de cor do teclado
Em `GameCubit._updateKeyboardColors()`:
- `correct` nunca sofre downgrade
- `present` nao vira `absent`

### Erros e mensagens
- Strings da UI em portugues (pt-BR).
- Erros de jogada aparecem em `FloatingToast`.
- Evitar silenciar erros sem ao menos logar quando houver padrao de logging no contexto.

### Componentizacao visual
- Componentes privados e especificos de tela ficam no mesmo arquivo (`_WidgetPrivado`).
- Manter estilo visual atual (glassmorphism, gradientes, etc.) quando editar UI existente.

---

## Cores oficiais
- `correct`: `#538D4E`
- `present`: `#B59F3B`
- `absent`: `#3A3A3C`
- `unknown`: `#818384`
- `background`: `#121213`
- `cardBg`: `#1A1A1B`

---

## Testes existentes
- `test/features/game/presentation/cubit/game_cubit_test.dart`:
  - fluxo principal do `GameCubit`
  - normalizacao de acentos no teclado
- `test/features/game/data/models/guess_result_model_test.dart`:
  - serializacao/desserializacao dos models
- `test/widget_test.dart`:
  - smoke test placeholder

---

## Notas de manutencao
- `ApiClient` e excecoes (`InvalidWordException`, `NetworkException`, `ServerException`) ainda existem em `core/network/api_client.dart`, mas o gameplay atual e majoritariamente local (SQLite).
- Ha comentarios legados no codigo mencionando `GameRemoteDataSourceImpl`; trate-os como historicos e nao como arquitetura vigente.
