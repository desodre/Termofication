import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termofication_app/widgets/help_button.dart';
import 'package:termofication_app/widgets/help_sheet.dart';

void main() {
  testWidgets('HelpButton renders and opens HelpSheet on tap', (WidgetTester tester) async {
    // Build our widget in a testable Scaffold
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          floatingActionButton: HelpButton(),
        ),
      ),
    );

    // Verify that the HelpButton is rendered with the expected icon
    expect(find.byType(HelpButton), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);

    // Tap the FloatingActionButton inside the HelpButton
    await tester.tap(find.byType(FloatingActionButton), warnIfMissed: false);
    
    // Advance the frame by 500ms to allow the bottom sheet slide animation to finish,
    // avoiding pumpAndSettle which times out due to the infinite repeating float animation.
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the HelpSheet bottom sheet opened successfully
    expect(find.byType(HelpSheet), findsOneWidget);
    expect(find.text('COMO JOGAR & MODOS'), findsOneWidget);
    expect(find.text('COMO JOGAR'), findsOneWidget);
    expect(find.text('MODOS DE JOGO'), findsOneWidget);
  });
}
