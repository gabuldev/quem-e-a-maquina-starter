import 'package:flutter/material.dart';

/// Mesa de jogo: fundo escuro, cartas claras, um acento para a máquina.
abstract final class AppColors {
  static const table = Color(0xFF101828);
  static const felt = Color(0xFF1B2A41);
  static const card = Color(0xFFFFF8EC);
  static const ink = Color(0xFF1D1D1F);
  static const machine = Color(0xFF7C4DFF);
  static const human = Color(0xFF00B894);
  static const accent = Color(0xFFFFC857);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.machine,
    brightness: Brightness.dark,
    surface: AppColors.table,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.table,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // Altura fixa, largura mínima finita: `fromHeight` pede largura
        // infinita e quebra o layout quando o botão está numa `Row`.
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
