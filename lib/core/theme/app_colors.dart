import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Cores do Jogo Termo
  static const Color correct = Color(0xFF538D4E); // Verde clássico do Termo
  static const Color present = Color(0xFFB59F3B); // Amarelo
  static const Color absent = Color(0xFF3A3A3C); // Cinza escuro (ausente)
  static const Color unknown = Color(
    0xFF818384,
  ); // Cinza médio (não descoberto)

  // Multiplayer
  static const Color playerOne = Color(0xFF1E88E5); // Azul vibrante
  static const Color playerTwo = Color(0xFFD32F2F); // Vermelho vibrante
  static const Color playerThree = Color(0xFFFFC107); // Amarelo vibrante
  static const Color playerFour = Color(0xFF4CAF50); // Verde vibrante

  static const Color multiplayerBackground = Color(0x4A616D7E); // Fundo escuro para multiplayer
  // Cores do App
  static const Color background = Color(0xFF121213); // Fundo escuro premium
  static const Color cardBg = Color(0xFF1A1A1B); // Fundo do card de resultados
  static const Color borderDefault = Color(
    0xFF3A3A3C,
  ); // Borda de células vazias
  static const Color borderActive = Color(
    0xFF565758,
  ); // Borda de células ativas

  // Botões e Textos
  static const Color textWhite = Colors.white;
  static const Color textGray = Color(0xFF818384);
}
