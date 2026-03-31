import '../domain/models/app_release.dart';
import '../domain/models/release_note.dart';

/// Lista de cambios por version.
///
/// Mantener siempre el release mas reciente al inicio de la lista.
const appReleases = <AppRelease>[
  AppRelease(
    version: '1.0.0',
    notes: [
      ReleaseNote(
        title: 'Nuevos modos de juego',
        description: 'Selecciona Marcar Carton, Bolillero o Juego Completo.',
      ),
      ReleaseNote(
        title: 'Recuperacion de partida',
        description: 'Retoma automaticamente una partida no terminada.',
      ),
      ReleaseNote(
        title: 'Mejor experiencia visual',
        description:
            'Tema claro/oscuro/automatico y opcion para agrandar letras en cartones.',
      ),
    ],
  ),
];
