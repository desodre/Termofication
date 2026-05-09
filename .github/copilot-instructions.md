# Copilot Instructions — termofication_app

Flutter MVP of the **Termo** game (Portuguese Wordle). The app consumes a FastAPI backend (`http://127.0.0.1:8000`) for word fetching and guess validation.

---

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Analyze (lint + type check)
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

> Tests require a running API server at `http://127.0.0.1:8000`. The current test suite is a placeholder smoke test.

---

## Architecture

All game state lives in a **single `GameProvider`** (Provider/ChangeNotifier) mounted at the root in `main.dart`. There is no secondary provider — all screens consume `GameProvider` via `context.watch` / `context.read`.

**Request flow:**
```
Screen → context.read<GameProvider>() → ApiService → http://127.0.0.1:8000
```

**Persistence flow (GetStorage):**
```
GameProvider._startDailyGame() → reads/writes daily_date, daily_word, daily_guesses, daily_status
GameProvider._onGameEnd()      → reads/writes infinite_wins, infinite_losses, infinite_streak
```

**Navigation:**
`AppRoutes` is the single source of truth for named routes. All pushes use `Navigator.pushNamed`. `GameScreen` is shared between both modes — the `GameMode` enum value is passed as a constructor parameter and forwarded to `GameProvider.startGame()`.

---

## Key Conventions

### Provider usage
- Use `context.watch<GameProvider>()` in `build()` to rebuild on state changes.
- Use `context.read<GameProvider>()` inside callbacks/event handlers (not in `build`).

### Starting a game
`GameProvider.startGame(mode)` must always be called via `WidgetsBinding.instance.addPostFrameCallback` from `initState`, never directly in `initState`. This is the established pattern in `GameScreen`.

### Daily mode persistence
The daily word is a random 5-letter word fetched once per calendar day and cached in GetStorage under `daily_date` / `daily_word`. There is **no server-side daily word ID resolution** — the API's `/game/daily-challenge/TERMO` endpoint is not currently used. Do not attempt to resolve `word_ids` to actual words; the random-per-day approach is intentional.

### LetterStatus priority (keyboard coloring)
When updating the keyboard state after a guess, statuses only ever upgrade, never downgrade:
- `correct` is never overwritten.
- `present` is not overwritten by `absent`.
- This logic lives in `GameProvider._updateKeyboardState()`.

### Private widgets
Helper widgets used only within one screen or widget file are defined as private classes (prefixed `_`) in the **same file**. Do not extract them to `lib/widgets/` unless they are reused across files.

### Color palette
| Role | Hex |
|---|---|
| Correct (green) | `#538D4E` |
| Present (yellow) | `#B59F3B` |
| Absent (dark gray) | `#3A3A3C` |
| Unknown key (mid gray) | `#818384` |
| App background | `#121213` |
| Result panel background | `#1A1A1B` |

Always use these exact hex values. Do not introduce new color constants for the game board UI.

### Game constants
`GameProvider.maxAttempts = 6` and `GameProvider.wordLength = 5` are `static const`. Reference them from the class rather than hardcoding `6` or `5`.

### Language
All UI strings are in **Portuguese** (pt-BR). Keep new user-facing text in Portuguese.

### API error handling
`ApiService` throws on non-200 responses. `GameProvider` catches these and writes a Portuguese message to `_errorMessage`, which `GameScreen` renders as `_ErrorBanner`. The 422 status from `POST /game/guess` means the word is invalid or the wrong length — surface it as `'Palavra inválida ou não encontrada no dicionário'`.

---

## API Reference (backend at `http://127.0.0.1:8000`)

| Method | Path | Purpose |
|---|---|---|
| GET | `/word/random/{length}` | Fetch a random word of given length → `{id, words, length}` |
| GET | `/validate/{word}` | Check if word exists → `{is_valid}` |
| POST | `/game/guess` | Validate guess against target → `{guess, is_correct, feedback[]}` |

Feedback `status` values per letter: `correct`, `present`, `absent`.  
`POST /game/guess` returns 422 for invalid/mismatched-length words.
