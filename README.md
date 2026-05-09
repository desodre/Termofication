# Termofication App

MVP do jogo **Termo** (Wordle em português) para Flutter. Consome uma API FastAPI local para buscar palavras e validar palpites.

---

## Stack

- **Flutter / Dart** — framework principal
- **Provider** — gerenciamento de estado (`ChangeNotifier`)
- **GetStorage** — persistência local (dados do jogo diário e estatísticas)
- **http** — chamadas à API REST

---

## Pré-requisitos

- Flutter SDK `^3.11.5`
- API backend rodando em `http://127.0.0.1:8000` ([terminfication](../terminfication/README.md))

---

## Instalação e execução

```bash
# Instalar dependências
flutter pub get

# Rodar o app
flutter run
```

---

## Comandos úteis

```bash
# Análise estática (lint + tipos)
flutter analyze

# Todos os testes
flutter test

# Um único arquivo de teste
flutter test test/widget_test.dart

# Build release Android
flutter build apk --release

# Build release iOS
flutter build ipa --release
```

---

## Modos de jogo

| Modo | Descrição |
|---|---|
| **Palavra do Dia** | Uma palavra por dia. O progresso é salvo — fechar e reabrir o app retoma de onde parou. |
| **Modo Infinito** | Nova palavra a cada partida. Rastreia vitórias, derrotas e sequência atual. |

Ambos os modos usam palavras de **5 letras** e permitem **6 tentativas**.

---

## Arquitetura

```
lib/
├── main.dart                     # Inicialização: GetStorage.init + ChangeNotifierProvider
├── routes/
│   └── app_routes.dart           # Rotas nomeadas
├── models/
│   ├── game_enums.dart           # GameMode, GameStatus, LetterStatus
│   ├── letter_feedback.dart      # Feedback por letra (fromJson/toJson)
│   └── guess_result.dart         # Resultado de um palpite (fromJson/toJson)
├── services/
│   └── api_service.dart          # Chamadas HTTP à API
├── providers/
│   └── game_provider.dart        # Todo o estado do jogo
├── screens/
│   ├── home_screen.dart          # Tela inicial com seleção de modo
│   └── game_screen.dart          # Tela de jogo (compartilhada entre os modos)
└── widgets/
    ├── guess_grid.dart            # Grade 6×5 de palpites
    ├── letter_tile.dart           # Tile individual colorido
    └── keyboard_widget.dart       # Teclado QWERTY virtual
```

### Fluxo de uma jogada

```
KeyboardWidget (tap) → GameProvider.addLetter() / submitGuess()
                     → ApiService.submitGuess(guess, target)
                     → POST /game/guess
                     → GuessResult com feedback por letra
                     → notifyListeners() → GuessGrid + KeyboardWidget atualizam
```

### Gerenciamento de estado

Existe **um único `GameProvider`** montado na raiz do widget tree. Não há providers secundários. Todos os dados do jogo — palavra-alvo, palpites, estado do teclado, erros, estatísticas — ficam nele.

- **`context.watch<GameProvider>()`** — usado no `build()` para reagir a mudanças
- **`context.read<GameProvider>()`** — usado em callbacks e event handlers

### Navegação

Toda navegação usa rotas nomeadas via `Navigator.pushNamed`. As rotas estão centralizadas em `AppRoutes`:

| Constante | Rota | Tela |
|---|---|---|
| `AppRoutes.home` | `/` | `HomeScreen` |
| `AppRoutes.dailyGame` | `/game/daily` | `GameScreen(mode: GameMode.daily)` |
| `AppRoutes.infiniteGame` | `/game/infinite` | `GameScreen(mode: GameMode.infinite)` |

`GameScreen` é compartilhado entre os dois modos — o `GameMode` é passado como parâmetro e repassado para `GameProvider.startGame()`.

### Persistência (GetStorage)

**Modo diário:**

| Chave | Tipo | Descrição |
|---|---|---|
| `daily_date` | `String` | Data no formato `YYYY-MM-DD` |
| `daily_word` | `String` | Palavra sorteada para o dia |
| `daily_guesses` | `List` | Palpites feitos (JSON serializado) |
| `daily_status` | `String` | `playing`, `won` ou `lost` |

**Modo infinito:**

| Chave | Tipo | Descrição |
|---|---|---|
| `infinite_wins` | `int` | Total de vitórias |
| `infinite_losses` | `int` | Total de derrotas |
| `infinite_streak` | `int` | Sequência atual de vitórias |

> O modo diário usa uma palavra aleatória de 5 letras sorteada uma vez por dia e salva localmente. O endpoint `/game/daily-challenge/TERMO` não é utilizado pois não há como resolver `word_ids` em palavras sem um endpoint `GET /word/{id}`.

---

## API Reference

Backend em `http://127.0.0.1:8000`.

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/word/random/{length}` | Retorna uma palavra aleatória com o tamanho especificado |
| `GET` | `/validate/{word}` | Verifica se a palavra existe no dicionário |
| `POST` | `/game/guess` | Valida um palpite e retorna feedback letra a letra |

### `POST /game/guess`

**Request:**
```json
{ "guess": "carro", "target": "carta" }
```

**Response `200`:**
```json
{
  "guess": "carro",
  "is_correct": false,
  "feedback": [
    { "letter": "c", "status": "correct" },
    { "letter": "a", "status": "correct" },
    { "letter": "r", "status": "present" },
    { "letter": "r", "status": "absent" },
    { "letter": "o", "status": "absent" }
  ]
}
```

**Status por letra:**

| Status | Significado | Cor |
|---|---|---|
| `correct` | Letra na posição correta | 🟩 `#538D4E` |
| `present` | Letra existe, posição errada | 🟨 `#B59F3B` |
| `absent` | Letra não existe na palavra | ⬛ `#3A3A3C` |

> Retorna `422` se o palpite não existe no dicionário ou tem tamanho diferente da palavra-alvo.

---

## Paleta de cores

| Papel | Hex |
|---|---|
| Correto (verde) | `#538D4E` |
| Presente (amarelo) | `#B59F3B` |
| Ausente (cinza escuro) | `#3A3A3C` |
| Tecla desconhecida | `#818384` |
| Fundo do app | `#121213` |
| Painel de resultado | `#1A1A1B` |
