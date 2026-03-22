import 'dart:developer' as dev;

import 'package:flutter/material.dart';

/// Retorna `true` si [text] no es null y contiene al menos un carácter
/// que no sea espacio en blanco.
bool isNotNullAndNotEmpty({required String? text}) {
  if (text == null) return false;
  return text.trim().isNotEmpty;
}

/// Retorna `true` si [text] es null o está vacío (inverso de [isNotNullAndNotEmpty]).
bool isNullOrEmpty({required String? text}) => !isNotNullAndNotEmpty(text: text);

/// Cierra el teclado virtual quitando el foco del campo activo.
void hideKeyboard(BuildContext context) {
  try {
    FocusScope.of(context).requestFocus(FocusNode());
  } catch (e) {
    dev.log('Error en hideKeyboard: $e');
  }
}

/// Capitaliza la primera letra de [text] y pone el resto en minúsculas.
///
/// Retorna `''` si [text] es null o vacío.
String capitalize(String? text) {
  if (isNullOrEmpty(text: text)) return '';
  final trimmed = text!.trim();
  return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
}
