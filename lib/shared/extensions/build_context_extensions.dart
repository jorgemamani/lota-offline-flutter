import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/breakpoints.dart';

extension BuildContextX on BuildContext {
  /// true cuando la app corre en web Y la pantalla es más ancha que el
  /// frame móvil — indica que hay que aplicar el layout centrado.
  bool get isWeb =>
      kIsWeb && MediaQuery.of(this).size.width > Breakpoints.mobileFrame;
}
