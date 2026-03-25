import 'package:flutter/material.dart';

import '../enums/snack_bar_type_enum.dart';
import '../widgets/bottom_sheets/confirm_bottom_sheet.dart';
import '../widgets/bottom_sheets/info_bottom_sheet.dart';

export '../enums/snack_bar_type_enum.dart';
export '../widgets/bottom_sheets/confirm_bottom_sheet.dart'
    show SheetOption, SheetOptionStyle;

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
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Entradas activas del overlay superior (notificaciones de premio).
  static final List<OverlayEntry> _topEntries = [];

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

  // ── Notificación superior (overlay) ──────────────────────────────────────

  /// Muestra un SnackBar flotante en la parte SUPERIOR de la pantalla.
  ///
  /// A diferencia del [SnackBar] estándar, se renderiza directamente en el
  /// overlay del navigator, por lo que aparece por encima de bottom sheets
  /// y modales. Útil para notificaciones de premios durante el juego.
  static void showTopSnackBar({
    required String message,
    SnackBarTypeEnum type = SnackBarTypeEnum.info,
    Duration? duration,
  }) {
    final overlay = _navigatorKey?.currentState?.overlay;
    if (overlay == null) return;

    _clearTopSnackBars();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopNotificationOverlay(
        message: message,
        type: type,
        duration: duration ?? type.defaultDuration,
        onComplete: () {
          entry.remove();
          _topEntries.remove(entry);
        },
      ),
    );

    _topEntries.add(entry);
    overlay.insert(entry);
  }

  /// Atajo para [showTopSnackBar] con tipo [SnackBarTypeEnum.success].
  static void showTopSnackBarSuccess({
    required String message,
    Duration? duration,
  }) =>
      showTopSnackBar(
        message: message,
        type: SnackBarTypeEnum.success,
        duration: duration,
      );

  static void _clearTopSnackBars() {
    for (final e in _topEntries) {
      e.remove();
    }
    _topEntries.clear();
  }

  // ── Toast ─────────────────────────────────────────────────────────────────
  // TODO: implementar con paquete de Toast (ej. fluttertoast o toastification)
  // static void showToast(String message, { ToastTypeEnum type, Duration? duration }) { ... }

  // ── Dialog informativo ────────────────────────────────────────────────────
  // TODO: implementar usando _navigatorKey para mostrar sin context
  // static Future<void> showInfoDialog({ required String title, required String message }) { ... }

  // ── Dialog de confirmación ────────────────────────────────────────────────
  // TODO: retorna Future<bool> — true si el usuario confirmó
  // static Future<bool> showConfirmDialog({ required String title, required String message, String confirmLabel, String cancelLabel }) { ... }

  // ── Bottom Sheet informativo ──────────────────────────────────────────────

  /// Muestra un bottom sheet con ícono opcional, título y mensaje.
  ///
  /// Solo tiene un botón de cierre cuyo label se puede personalizar
  /// con [closeLabel] (default: "Entendido"). No retorna valor.
  ///
  /// ```dart
  /// AlertManager.showInfoSheet(
  ///   title: 'Cartón guardado',
  ///   message: 'Podés encontrarlo en la sección de Favoritos.',
  ///   icon: Icons.check_circle_outline,
  /// );
  /// ```
  static Future<void> showInfoSheet({
    required String title,
    required String message,
    IconData? icon,
    String closeLabel = 'Entendido',
  }) {
    assert(
      _navigatorKey != null,
      'AlertManager.setup() debe llamarse antes de showInfoSheet().',
    );

    final context = _navigatorKey?.currentContext;
    if (context == null) return Future.value();

    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InfoBottomSheet(
        title: title,
        message: message,
        icon: icon,
        closeLabel: closeLabel,
      ),
    );
  }

  // ── Bottom Sheet de confirmación ──────────────────────────────────────────

  /// Muestra un bottom sheet con título, descripción y entre 2 y 3 opciones.
  ///
  /// Cada opción cierra el sheet antes de ejecutar su callback.
  /// El estilo de cada botón se controla con [SheetOption.style] e
  /// [SheetOption.isDestructive].
  ///
  /// ```dart
  /// AlertManager.showConfirmSheet(
  ///   title: '¿Eliminar favorito?',
  ///   description: 'Esta acción no se puede deshacer.',
  ///   options: [
  ///     SheetOption(
  ///       label: 'Eliminar',
  ///       onTap: () => cubit.removeFavorite(id),
  ///       isDestructive: true,
  ///     ),
  ///     SheetOption(
  ///       label: 'Cancelar',
  ///       onTap: () {},
  ///       style: SheetOptionStyle.outlined,
  ///     ),
  ///   ],
  /// );
  /// ```
  static Future<void> showConfirmSheet({
    required String title,
    required String description,
    required List<SheetOption> options,
  }) {
    assert(
      _navigatorKey != null,
      'AlertManager.setup() debe llamarse antes de showConfirmSheet().',
    );
    assert(
      options.length >= 2 && options.length <= 3,
      'showConfirmSheet requiere entre 2 y 3 opciones.',
    );

    final context = _navigatorKey?.currentContext;
    if (context == null) return Future.value();

    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ConfirmBottomSheet(
        title: title,
        description: description,
        options: options,
      ),
    );
  }

  // ── Bottom Sheet personalizado ────────────────────────────────────────────

  /// Muestra un bottom sheet con contenido completamente personalizado.
  ///
  /// El [child] puede ser cualquier widget. Para obtener el valor de retorno,
  /// usa `Navigator.of(context).pop(value)` desde dentro del widget.
  ///
  /// [isDismissible]: si se puede cerrar tocando fuera. Default: `true`.
  /// [enableDrag]: si se puede arrastrar hacia abajo para cerrar. Default: `true`.
  /// [isScrollControlled]: si el sheet puede ocupar más del 50% de la pantalla.
  ///   Activalo si el child contiene un formulario o lista larga. Default: `false`.
  ///
  /// ```dart
  /// final result = await AlertManager.showCustomSheet<String>(
  ///   child: MyPickerWidget(),
  /// );
  /// ```
  static Future<T?> showCustomSheet<T>({
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
  }) {
    assert(
      _navigatorKey != null,
      'AlertManager.setup() debe llamarse antes de showCustomSheet().',
    );

    final context = _navigatorKey?.currentContext;
    if (context == null) return Future.value(null);

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => child,
    );
  }
}

// ── Widget privado: notificación superior animada ─────────────────────────────

class _TopNotificationOverlay extends StatefulWidget {
  const _TopNotificationOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onComplete,
  });

  final String message;
  final SnackBarTypeEnum type;
  final Duration duration;
  final VoidCallback onComplete;

  @override
  State<_TopNotificationOverlay> createState() =>
      _TopNotificationOverlayState();
}

class _TopNotificationOverlayState extends State<_TopNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) async {
      await Future<void>.delayed(widget.duration);
      if (mounted) {
        await _controller.reverse();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.type.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.type.icon,
                      color: widget.type.foregroundColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.type.foregroundColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
