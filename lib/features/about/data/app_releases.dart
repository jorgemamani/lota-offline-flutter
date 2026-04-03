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
        title: 'Modos de juego',
        description:
            'Selecciona Marcar Cartones, Bolillero o Cartones + Bolillero.',
      ),
      ReleaseNote(
        title: 'Recuperacion de partida',
        description: 'Retoma automaticamente una partida no terminada.',
      ),
      ReleaseNote(
        title: 'Experiencia visual',
        description:
            'Tema claro/oscuro/automatico y opcion para agrandar letras en cartones.',
      ),
    ],
  ),
];
