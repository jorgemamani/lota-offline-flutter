# Lota — Bingo 90 Argentino

App offline para jugar Lota Argentina (Bingo 90). Primera versión 100% local, sin backend.

## Stack

| Capa | Librería |
|------|----------|
| Navegación | `go_router` |
| Estado | `flutter_bloc` (Bloc + Cubit) |
| DI | `get_it` |
| HTTP | `dio` (listo para v2) |
| Storage | `flutter_secure_storage` |
| Entorno | `flutter_dotenv` |
| UI | Material 3 + `google_fonts` |

## Modos de juego

| Modo | Descripción |
|------|-------------|
| **Marcar Cartón** | Seleccionás cartones y los marcás a mano mientras alguien canta externamente |
| **Bolillero** | Sorteo automático de números 1–90. Ideal para ser el cantador |
| **Juego Completo** | Selección de cartones + bolillero integrado en modal + marcado automático |

## Estructura de pantallas

```
Splash (auto → home)
  └── Home (3 opciones)
        ├── Bolillero (standalone)
        ├── Selección de Cartones (markOnly)
        │     └── GamePlayPage (solo marcado)
        └── Selección de Cartones (combined)
              └── GamePlayPage (marcado + bolillero modal)
```

## Estructura del proyecto

```
lib/
├── main.dart                        # init env + DI + runApp
├── app.dart                         # MaterialApp.router + GameBloc global
├── dependency_injection.dart        # GetIt
├── config/environment/              # BaseConfig / DevConfig / ProdConfig
├── core/
│   ├── errors/app_exception.dart
│   ├── http_client/                 # IHttpClient + ApiHttpClient (Dio)
│   └── local_storage/              # ILocalStorage + SecureLocalStorage
├── routing/
│   ├── route_names.dart
│   ├── go_router_refresh_stream.dart
│   └── app_router.dart
├── features/
│   ├── splash/                      # SplashPage
│   ├── home/                        # HomePage (3 opciones de juego)
│   ├── bolillero/
│   │   ├── pages/bolillero_page.dart
│   │   └── widgets/bolillero_widget.dart  ← reutilizable en modal
│   └── game/
│       ├── domain/models/
│       │   ├── carton.dart          # Modelo de cartón (3×9)
│       │   ├── game_mode.dart       # Enum GameMode
│       │   └── game_result.dart     # Premio: Línea / Lota
│       ├── data/carton_generator.dart  ← placeholder (reemplazar con algo propio)
│       └── presentation/
│           ├── bloc/game_bloc.dart  # GameBloc (event/state con part)
│           ├── pages/
│           │   ├── carton_select_page.dart
│           │   └── game_play_page.dart
│           └── widgets/carton_widget.dart  ← placeholder (reemplazar con algo propio)
└── shared/widgets/loading_indicator.dart
```

## GameBloc — estados

```dart
sealed class GameState { ... }
final class GameIdle        extends GameState   // sin partida activa
final class GameInProgress  extends GameState   // partida en curso
final class GameOver        extends GameState   // lota o números agotados
```

## Eventos del GameBloc

| Evento | Descripción |
|--------|-------------|
| `GameStarted` | Inicia partida con cartones y modo |
| `RandomNumberDrawn` | Saca número aleatorio del bolillero |
| `ManualNumberDrawn` | Ingresa número manual (modo markOnly) |
| `NumberToggled` | Marca/desmarca número en un cartón |
| `LinePrizeClaimed` | Reclama premio de línea |
| `LotaPrizeClaimed` | Reclama lota → emite GameOver |
| `GameReset` | Reinicia a GameIdle |

## Setup

```bash
# 1. Generar archivos de plataforma (primera vez)
fvm flutter create . --org com.tuempresa --project-name lota_offline

# 2. Instalar dependencias
fvm flutter pub get

# 3. Generar l10n
fvm flutter gen-l10n

# 4. Correr
fvm flutter run --dart-define=ENVIRONMENT=dev
```

## Tests

```bash
fvm flutter test
```

## TODOs para la próxima iteración

- [ ] Reemplazar `CartonGenerator._generateGrid()` con el algoritmo real del usuario
- [ ] Reemplazar `CartonWidget` con el componente visual del usuario
- [ ] Persistir historial de partidas con `shared_preferences`
- [ ] Modo oscuro/claro desde settings
- [ ] Soporte para múltiples cartones en modo combinado con scroll horizontal
