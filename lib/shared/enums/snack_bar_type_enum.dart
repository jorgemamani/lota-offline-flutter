import 'package:flutter/material.dart';

enum SnackBarTypeEnum { info, success, warning, error }

Map<String, dynamic> _generateMapSnackBarTypeEnum({
  required Color backgroundColor,
  required Color foregroundColor,
  required IconData icon,
  required Duration defaultDuration,
}) {
  return {
    'backgroundColor': backgroundColor,
    'foregroundColor': foregroundColor,
    'icon': icon,
    'defaultDuration': defaultDuration,
  };
}

extension SnackBarTypeEnumExtension on SnackBarTypeEnum {
  static final Map<SnackBarTypeEnum, Map<String, dynamic>> states = {
    SnackBarTypeEnum.info: _generateMapSnackBarTypeEnum(
      backgroundColor: const Color(0xFF334155),
      foregroundColor: Colors.white,
      icon: Icons.info_outline_rounded,
      defaultDuration: const Duration(seconds: 3),
    ),
    SnackBarTypeEnum.success: _generateMapSnackBarTypeEnum(
      backgroundColor: const Color(0xFF059669),
      foregroundColor: Colors.white,
      icon: Icons.check_circle_outline_rounded,
      defaultDuration: const Duration(seconds: 3),
    ),
    SnackBarTypeEnum.warning: _generateMapSnackBarTypeEnum(
      backgroundColor: const Color(0xFFD97706),
      foregroundColor: Colors.white,
      icon: Icons.warning_amber_rounded,
      defaultDuration: const Duration(seconds: 3),
    ),
    SnackBarTypeEnum.error: _generateMapSnackBarTypeEnum(
      backgroundColor: const Color(0xFFDC2626),
      foregroundColor: Colors.white,
      icon: Icons.error_outline_rounded,
      defaultDuration: const Duration(seconds: 4),
    ),
  };

  Color get backgroundColor => states[this]!['backgroundColor'] as Color;
  Color get foregroundColor => states[this]!['foregroundColor'] as Color;
  IconData get icon => states[this]!['icon'] as IconData;
  Duration get defaultDuration => states[this]!['defaultDuration'] as Duration;
}
