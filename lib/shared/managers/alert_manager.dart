import 'package:flutter/material.dart';

import '../enums/snack_bar_type_enum.dart';

export '../enums/snack_bar_type_enum.dart';

/// Manager centralizado de mensajes y overlays de UI.
///
/// Cubre: SnackBar · Toast (futuro) · Dialog · BottomSheet.
///
/// ── Inicialización ────────────────────────────────────────────────────────
/// Llamar [setup] una sola vez en [LotaApp.build], antes de cualquier
/// método `show*`. Eso registra las claves globales y evita pasar [BuildContext]
/// en cada call site — los métodos pueden invocarse desde cualquier lugar,
/// incluso desde un Cubit o BLoC.
///
/// ```dart
/// // En app.dart
/// AlertManager.setup(
///   scaffoldMessengerKey: _scaffoldMessengerKey,
///   navigatorKey: rootNavigatorKey,
/// );
/// ```
///
/// ── Uso ───────────────────────────────────────────────────────────────────
/// ```dart
/// AlertManager.showSnackBar('Guardado');
/// AlertManager.showSnackBar('Error', type: SnackBarTypeEnum.error);
/// AlertManager.showSnackBarSuccess('Favorito guardado');
/// AlertManager.showSnackBarWarning('Máximo 3 cartones');
/// AlertManager.showSnackBarError('No se pudo conectar');
/// ```
///
/// Convención del proyecto: todos los managers terminan en `_manager.dart`.
abstract final class AlertManager {
  static GlobalKey<ScaffoldMessengerState>? _messengerKey;
  // ignore: unused_field — se usará cuando se implementen Dialog y BottomSheet
  static GlobalKey<NavigatorState>? _navigatorKey;

  // ── Setup ────────────────────────────────────────────────────────────────

  /// Registra las claves globales necesarias para operar sin [BuildContext].
  ///
  /// Debe llamarse una única vez, en [LotaApp.build], antes de cualquier
  /// método `show*`.
  static void setup({
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    _messengerKey = scaffoldMessengerKey;
    _navigatorKey = navigatorKey;
  }

  // ── SnackBar ─────────────────────────────────────────────────────────────

  /// Muestra un SnackBar flotante.
  ///
  /// Parámetros obligatorios: [message].
  ///
  /// Parámetros opcionales:
  /// - [type]: determina color e ícono. Default: [SnackBarTypeEnum.info].
  /// - [duration]: sobrescribe la duración por defecto del tipo.
  /// - [fontSize]: tamaño del texto. Default: 14.
  /// - [action]: botón de acción opcional.
  static void showSnackBar({
    required String message,
    SnackBarTypeEnum type = SnackBarTypeEnum.info,
    Duration? duration,
    double fontSize = 14,
    SnackBarAction? action,
  }) {
    assert(
      _messengerKey != null,
      'AlertManager.setup() debe llamarse antes de showSnackBar().',
    );

    _messengerKey!.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(type.icon, color: type.foregroundColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: type.foregroundColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: type.backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: duration ?? type.defaultDuration,
          action: action,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  /// Atajo para [SnackBarTypeEnum.success].
  static void showSnackBarSuccess({
    required String message,
    Duration? duration,
    double fontSize = 14,
    SnackBarAction? action,
  }) =>
      showSnackBar(
          message: message,
          type: SnackBarTypeEnum.success,
          duration: duration,
          fontSize: fontSize,
          action: action);

  /// Atajo para [SnackBarTypeEnum.error].
  static void showSnackBarError({
    required String message,
    Duration? duration,
    double fontSize = 14,
    SnackBarAction? action,
  }) =>
      showSnackBar(
          message: message,
          type: SnackBarTypeEnum.error,
          duration: duration,
          fontSize: fontSize,
          action: action);

  /// Atajo para [SnackBarTypeEnum.warning].
  static void showSnackBarWarning({
    required String message,
    Duration? duration,
    double fontSize = 14,
    SnackBarAction? action,
  }) =>
      showSnackBar(
          message: message,
          type: SnackBarTypeEnum.warning,
          duration: duration,
          fontSize: fontSize,
          action: action);

  // ── Toast ─────────────────────────────────────────────────────────────────
  // TODO: implementar con paquete de Toast (ej. fluttertoast o toastification)
  // static void showToast(String message, { ToastTypeEnum type, Duration? duration }) { ... }

  // ── Dialog informativo ────────────────────────────────────────────────────
  // TODO: implementar usando _navigatorKey para mostrar sin context
  // static Future<void> showInfoDialog({ required String title, required String message }) { ... }

  // ── Dialog de confirmación ────────────────────────────────────────────────
  // TODO: retorna Future<bool> — true si el usuario confirmó
  // static Future<bool> showConfirmDialog({ required String title, required String message, String confirmLabel, String cancelLabel }) { ... }

  // ── Bottom Sheet informativo ─────────────────────────────────────────────
  // Muestra información estática: título, mensaje, ícono opcional y un botón
  // de cierre. No retorna valor.
  // TODO: implementar usando _navigatorKey para mostrar sin context
  // static Future<void> showInfoSheet({ required String title, required String message, IconData? icon }) { ... }

  // ── Bottom Sheet de confirmación ──────────────────────────────────────────
  // Presenta una acción destructiva o irreversible con dos botones.
  // Retorna Future<bool> — true si el usuario confirmó, false si canceló.
  // TODO: implementar usando _navigatorKey para mostrar sin context
  // static Future<bool> showConfirmSheet({ required String title, required String message, String confirmLabel, String cancelLabel, bool isDestructive }) { ... }

  // ── Bottom Sheet con contenido personalizado ──────────────────────────────
  // Recibe cualquier widget como contenido. Útil para formularios, listas,
  // selección de opciones, etc. Retorna el valor que el sheet decida pasar
  // al cerrar via Navigator.pop(context, value).
  // TODO: implementar usando _navigatorKey para mostrar sin context
  // static Future<T?> showCustomSheet<T>({ required WidgetBuilder builder, bool isDismissible = true, bool enableDrag = true }) { ... }
}
