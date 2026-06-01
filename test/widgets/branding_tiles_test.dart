import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termofication_app/widgets/branding_tiles.dart';
import 'package:termofication_app/features/game/domain/entities/game_enums.dart';
import 'package:termofication_app/features/game/presentation/widgets/letter_tile.dart';

void main() {
  testWidgets('BrandingTiles renders TERMO with correct initial statuses', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandingTiles(),
        ),
      ),
    );

    // Verify 5 LetterTiles are rendered
    expect(find.byType(LetterTile), findsNWidgets(5));

    // Verify letters rendered
    expect(find.text('T'), findsOneWidget);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);

    // Verify initial statuses (T is correct, others are absent)
    final tiles = tester.widgetList<LetterTile>(find.byType(LetterTile)).toList();
    expect(tiles[0].status, LetterStatus.correct);
    expect(tiles[1].status, LetterStatus.absent);
    expect(tiles[2].status, LetterStatus.absent);
    expect(tiles[3].status, LetterStatus.absent);
    expect(tiles[4].status, LetterStatus.absent);
  });

  testWidgets('BrandingTiles Easter Egg changes all letters to correct after 7 taps', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandingTiles(),
        ),
      ),
    );

    // Tap 6 times with small delays
    for (int i = 0; i < 6; i++) {
      await tester.tap(find.byType(BrandingTiles));
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify letters are still in initial states
    var tiles = tester.widgetList<LetterTile>(find.byType(LetterTile)).toList();
    expect(tiles[0].status, LetterStatus.correct);
    expect(tiles[1].status, LetterStatus.absent);

    // Tap the 7th time to trigger the Easter Egg
    await tester.tap(find.byType(BrandingTiles));
    await tester.pump(); // process tap gesture

    // Advance clock in steps to let each of the 5 sequential delayed futures fire
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    // Settle all remaining bounce animations
    await tester.pumpAndSettle();

    // Verify all tiles are now correct (green)
    tiles = tester.widgetList<LetterTile>(find.byType(LetterTile)).toList();
    for (int i = 0; i < 5; i++) {
      expect(tiles[i].status, LetterStatus.correct);
    }
  });

  testWidgets('BrandingTiles click count resets if taps are slow', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandingTiles(),
        ),
      ),
    );

    // Tap 3 times
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.byType(BrandingTiles));
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Wait 2 seconds (exceeding the 1.5s threshold) to let the reset timer fire
    await tester.pump(const Duration(seconds: 2));

    // Tap 4 more times (total 7 taps but split by 2s delay, so count should reset and not trigger)
    for (int i = 0; i < 4; i++) {
      await tester.tap(find.byType(BrandingTiles));
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    // Wait 2 seconds to let the active reset timer fire, leaving no pending timers at test end
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify it did NOT trigger (others are still absent)
    final tiles = tester.widgetList<LetterTile>(find.byType(LetterTile)).toList();
    expect(tiles[0].status, LetterStatus.correct);
    expect(tiles[1].status, LetterStatus.absent);
  });
}
