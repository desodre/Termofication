import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termofication_app/features/game/domain/entities/game_enums.dart';
import 'package:termofication_app/features/game/presentation/widgets/letter_tile.dart';
import 'package:termofication_app/features/game/presentation/widgets/shake_widget.dart';

void main() {
  setUpAll(() async {
    // Avoid path provider MissingPluginException during tests
    HttpOverrides.global = null;
  });

  group('Testes de Animação (Microinterações)', () {
    testWidgets('Deve validar a animação de revelação Flip 3D (Y-Axis)', (WidgetTester tester) async {
      // 1. Renderiza o LetterTile em estado inicial desconhecido (unknown)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LetterTile(
              letter: 'T',
              status: LetterStatus.unknown,
              animationDelay: Duration.zero,
            ),
          ),
        ),
      );

      // Encontra os 3 Transform widgets do LetterTile (translate, scale, rotate)
      final transformFinder = find.descendant(
        of: find.byType(LetterTile),
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsNWidgets(3));

      // Rotação inicial (o 3º Transform, índice 2) deve ser 0.0, cos(0) = 1.0
      var rotateTransform = tester.widget<Transform>(transformFinder.at(2));
      expect(rotateTransform.transform.entry(0, 0), closeTo(1.0, 0.001));

      // 2. Re-render com status correto para disparar o didUpdateWidget e agendar o Future.delayed
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LetterTile(
              letter: 'T',
              status: LetterStatus.correct,
              animationDelay: Duration.zero,
            ),
          ),
        ),
      );

      // Avança 1ms para processar a fila de eventos e disparar o callback do Future.delayed
      await tester.pump(const Duration(milliseconds: 1));

      // Avança a animação em 275ms (exatamente metade dos 550ms totais)
      await tester.pump(const Duration(milliseconds: 275));

      // Na metade do caminho (90 graus), cos(90) deve ser próximo de 0.0 (menor que 1.0)
      rotateTransform = tester.widget<Transform>(transformFinder.at(2));
      expect(rotateTransform.transform.entry(0, 0), lessThan(1.0));
      expect(rotateTransform.transform.entry(0, 0), closeTo(0.0, 0.15));

      // Avança os 275ms restantes para concluir os 550ms
      await tester.pump(const Duration(milliseconds: 275));

      // Na conclusão, o bloco completou o giro e volta a ficar paralelo, cos(0) = 1.0
      rotateTransform = tester.widget<Transform>(transformFinder.at(2));
      expect(rotateTransform.transform.entry(0, 0), closeTo(1.0, 0.001));
    });

    testWidgets('Deve validar a animação de Shake (Erro Horizontal)', (WidgetTester tester) async {
      // 1. Renderiza o ShakeWidget inicializado com trigger nulo (sem oscilação)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShakeWidget(
              shakeOffset: 10.0,
              duration: Duration(milliseconds: 500),
              trigger: null,
              child: SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      );

      // Encontra a transformadora de translação específica dentro do ShakeWidget
      final shakeTransformFinder = find.descendant(
        of: find.byType(ShakeWidget),
        matching: find.byType(Transform),
      );
      expect(shakeTransformFinder, findsOneWidget);

      // Offset inicial em X deve ser 0.0
      var translateWidget = tester.widget<Transform>(shakeTransformFinder);
      expect(translateWidget.transform.getTranslation().x, 0.0);

      // 2. Atualiza o trigger para disparar o shake
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShakeWidget(
              shakeOffset: 10.0,
              duration: Duration(milliseconds: 500),
              trigger: 'palavra_invalida',
              child: SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      );

      // Avança 50ms (10% de peso do primeiro TweenSequence: end a 1.0)
      await tester.pump(const Duration(milliseconds: 50));
      translateWidget = tester.widget<Transform>(shakeTransformFinder);
      expect(translateWidget.transform.getTranslation().x, closeTo(10.0, 0.1));

      // Avança mais 100ms (total 150ms / 30%: fim do segundo TweenSequence: end a -1.0)
      await tester.pump(const Duration(milliseconds: 100));
      translateWidget = tester.widget<Transform>(shakeTransformFinder);
      expect(translateWidget.transform.getTranslation().x, closeTo(-10.0, 0.1));

      // Avança os 350ms restantes para concluir a animação de 500ms
      await tester.pump(const Duration(milliseconds: 350));
      translateWidget = tester.widget<Transform>(shakeTransformFinder);
      expect(translateWidget.transform.getTranslation().x, closeTo(0.0, 0.001));
    });
  });
}
