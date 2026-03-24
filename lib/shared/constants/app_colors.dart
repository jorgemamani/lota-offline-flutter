import 'package:flutter/material.dart';

/// Paleta centralizada de colores de la aplicación.
///
/// ── Dos capas ────────────────────────────────────────────────────────────
///
/// 1. [Paleta primitiva] — naming por familia + shade (inspirado en Tailwind).
///    Agnóstica al contexto: `blue600`, `emerald600`, `red600`, etc.
///    Son los únicos lugares donde aparecen valores `Color(0x...)`.
///
/// 2. [Tokens semánticos] — aliases con nombre de uso (`primary`, `statusError`,
///    `favorite`). Siempre referencian la paleta; nunca definen hex propios.
///
/// ── Reglas ───────────────────────────────────────────────────────────────
///
/// • Las transparencias se aplican en el call site:
///     `AppColors.primary.withValues(alpha: 0.12)` ✓
///     `static const primaryLight = Color(0x1F2563EB)` ✗
///
/// • Los colores del tema (surface, onPrimary, etc.) los provee [ColorScheme].
abstract final class AppColors {
  // ════════════════════════════════════════════════════════════════════════
  // PALETA PRIMITIVA
  // ════════════════════════════════════════════════════════════════════════

  // ── Slate ────────────────────────────────────────────────────────────────
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);

  // ── Blue ─────────────────────────────────────────────────────────────────
  static const blue600 = Color(0xFF2563EB);

  // ── Indigo ───────────────────────────────────────────────────────────────
  static const indigo600 = Color(0xFF4338CA);

  // ── Violet ───────────────────────────────────────────────────────────────
  static const violet600 = Color(0xFF7C3AED);

  // ── Cyan ─────────────────────────────────────────────────────────────────
  static const cyan600 = Color(0xFF0891B2);

  // ── Emerald ──────────────────────────────────────────────────────────────
  static const emerald600 = Color(0xFF059669);

  // ── Rose ─────────────────────────────────────────────────────────────────
  static const rose600 = Color(0xFFE11D48);

  // ── Amber ────────────────────────────────────────────────────────────────
  static const amber300 = Color(0xFFFFD54F);
  static const amber500 = Color(0xFFFFC107);
  static const amber600 = Color(0xFFD97706);
  static const amber700 = Color(0xFFFFA000);
  static const amber800 = Color(0xFFFF8F00);
  static const amberBg  = Color(0xFFFFF8E1);

  // ── Red ──────────────────────────────────────────────────────────────────
  static const red600 = Color(0xFFDC2626);

  // ── Green (Material — para chips de premios) ──────────────────────────────
  static const green500 = Color(0xFF4CAF50);
  static const green200 = Color(0xFFA5D6A7);
  static const greenBg  = Color(0xFFE8F5E9);

  // ════════════════════════════════════════════════════════════════════════
  // TOKENS SEMÁNTICOS
  // ════════════════════════════════════════════════════════════════════════

  // ── Marca ────────────────────────────────────────────────────────────────
  static const primary = blue600;

  // ── Modos de juego ────────────────────────────────────────────────────────
  static const gameModeMarkOnly  = primary;
  static const gameModeBolillero = violet600;
  static const gameModeCombined  = emerald600;

  // ── Estado / alertas ─────────────────────────────────────────────────────
  static const statusInfo    = slate700;
  static const statusSuccess = emerald600;
  static const statusWarning = amber600;
  static const statusError   = red600;

  // ── Favorito ─────────────────────────────────────────────────────────────
  static const favorite = amber600;

  // ── Premios de partida ───────────────────────────────────────────────────
  static const prizeLineaBackground = greenBg;
  static const prizeLineaBorder     = green200;
  static const prizeLineaLabel      = green500;
  static const prizeLotaButton      = amber700;
  static const prizeLotaBackground  = amberBg;
  static const prizeLotaBorder      = amber300;
  static const prizeLotaLabel       = amber800;
}
