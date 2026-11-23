import 'dart:io';

import 'package:cancionero/models/song.dart';
import 'package:cancionero/providers/library_provider.dart';
import 'package:cancionero/providers/setlist_provider.dart';
import 'package:cancionero/providers/settings_provider.dart';
import 'package:cancionero/screens/settings/settings_screen.dart';
import 'package:cancionero/screens/song_view_screen.dart';
import 'package:cancionero/utils/chord_transposer.dart';
import 'package:cancionero/widgets/chord_line_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ChordTransposer notation conversion and transposition', () {
    test('converts American chords to Latin notation', () {
      expect(
        ChordTransposer.formatChord('C', notation: ChordNotation.latin),
        'Do',
      );
      expect(
        ChordTransposer.formatChord('G', notation: ChordNotation.latin),
        'Sol',
      );
      expect(
        ChordTransposer.formatChord('Am7', notation: ChordNotation.latin),
        'Lam7',
      );
      expect(
        ChordTransposer.formatChord('F#m7b5/C#', notation: ChordNotation.latin),
        'Fa#m7b5/Do#',
      );
      expect(
        ChordTransposer.formatChord('Bb/D', notation: ChordNotation.latin),
        'Sib/Re',
      );
      expect(
        ChordTransposer.formatChord('(G)', notation: ChordNotation.latin),
        '(Sol)',
      );
      expect(
        ChordTransposer.formatChord('N.C.', notation: ChordNotation.latin),
        'N.C.',
      );
    });

    test('distinguishes Fadd9 / Faug / Falt from Latin Fa chords', () {
      expect(
        ChordTransposer.formatChord('Fadd9', notation: ChordNotation.latin),
        'Faadd9',
      );
      expect(
        ChordTransposer.formatChord('Faug', notation: ChordNotation.latin),
        'Faaug',
      );
      expect(
        ChordTransposer.formatChord('Falt', notation: ChordNotation.latin),
        'Faalt',
      );
      expect(
        ChordTransposer.formatChord('Fadd9', notation: ChordNotation.american),
        'Fadd9',
      );
      expect(
        ChordTransposer.formatChord('Faadd9', notation: ChordNotation.american),
        'Fadd9',
      );
      expect(
        ChordTransposer.formatChord('Faaug', notation: ChordNotation.american),
        'Faug',
      );
    });

    test('converts Latin input chords to American notation and transposes', () {
      expect(
        ChordTransposer.formatChord('Sol', notation: ChordNotation.american),
        'G',
      );
      expect(
        ChordTransposer.formatChord('Lam7', notation: ChordNotation.american),
        'Am7',
      );
      expect(
        ChordTransposer.formatChord('Sol/Si', notation: ChordNotation.american),
        'G/B',
      );
      expect(
        ChordTransposer.transposeChord(
          'Sol',
          2,
          notation: ChordNotation.latin,
        ),
        'La',
      );
      expect(
        ChordTransposer.transposeChord(
          'Sol',
          2,
          notation: ChordNotation.american,
        ),
        'A',
      );
      expect(
        ChordTransposer.transposeChord(
          'G',
          1,
          useFlats: true,
          notation: ChordNotation.latin,
        ),
        'Lab',
      );
      expect(
        ChordTransposer.transposeChord(
          'G',
          1,
          useFlats: false,
          notation: ChordNotation.latin,
        ),
        'Sol#',
      );
      expect(
        ChordTransposer.transposeChord(
          'Do#m/Sol#',
          -1,
          notation: ChordNotation.latin,
        ),
        'Dom/Sol',
      );
    });

    test('preserves original flats/sharps when steps == 0 and requested', () {
      expect(
        ChordTransposer.transposeChord(
          'Bb',
          0,
          useFlats: false,
          notation: ChordNotation.latin,
          preserveAccidentals: true,
        ),
        'Sib',
      );
      expect(
        ChordTransposer.transposeChord(
          'F#m',
          0,
          useFlats: true,
          notation: ChordNotation.latin,
          preserveAccidentals: true,
        ),
        'Fa#m',
      );
      expect(ChordTransposer.usesFlatNotation('Sib'), isTrue);
      expect(ChordTransposer.usesFlatNotation('Bb'), isTrue);
      expect(ChordTransposer.usesFlatNotation('G'), isFalse);
    });

    test('transposes an entire Song including metadata key in Latin', () {
      const song = Song(
        metadata: SongMetadata(
          title: 'Test',
          artist: '',
          key: 'G',
          filePath: '/test.chord',
        ),
        sections: [
          SongSection(
            name: 'Verso',
            type: SectionType.verse,
            lines: [
              SongLine(
                chunks: [
                  SongChunk(chord: 'G', lyrics: 'Hola '),
                  SongChunk(chord: 'Em7', lyrics: 'mundo '),
                  SongChunk(chord: 'C/E', lyrics: 'hoy'),
                ],
              ),
            ],
          ),
        ],
      );

      final latinUpTwo = ChordTransposer.transposeSong(
        song,
        2,
        notation: ChordNotation.latin,
      );
      expect(latinUpTwo.metadata.key, 'La');
      final chunks = latinUpTwo.sections.single.lines.single.chunks;
      expect(chunks.map((c) => c.chord).toList(), ['La', 'Fa#m7', 'Re/Fa#']);
    });
  });

  group('SettingsProvider and UI notation switching', () {
    test('persists chord notation preference in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsProvider(prefs);
      addTearDown(settings.dispose);

      expect(settings.chordNotation, ChordNotation.american);

      await settings.setChordNotation(ChordNotation.latin);
      expect(settings.chordNotation, ChordNotation.latin);
      expect(prefs.getString('chord_notation'), 'latin');

      final reloaded = SettingsProvider(prefs);
      addTearDown(reloaded.dispose);
      expect(reloaded.chordNotation, ChordNotation.latin);
    });

    testWidgets('SettingsScreen lets user switch between American and Latin', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final library = LibraryProvider();
      final settings = SettingsProvider(prefs);
      addTearDown(library.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: library),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notación de acordes'), findsOneWidget);
      expect(find.text('Do, Sol, La'), findsOneWidget);

      await tester.tap(find.text('Do, Sol, La'));
      await tester.pumpAndSettle();

      expect(settings.chordNotation, ChordNotation.latin);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'SongViewScreen switches notation and transposes in Latin from song view',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final samplePath =
            File('sample_songs/amazing_grace.chord').absolute.path;

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final library = LibraryProvider();
        final settings = SettingsProvider(prefs);
        final setlists = SetlistProvider();
        addTearDown(library.dispose);
        addTearDown(settings.dispose);
        addTearDown(setlists.dispose);
        await setlists.loadSetlists();

        await tester.runAsync(() async {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: library),
                ChangeNotifierProvider.value(value: settings),
                ChangeNotifierProvider.value(value: setlists),
              ],
              child: MaterialApp(
                home: SongViewScreen(
                  metadata: SongMetadata(
                    title: 'Amazing Grace',
                    artist: 'John Newton',
                    key: 'G',
                    filePath: samplePath,
                  ),
                  mobilePortrait: true,
                  hideSongPanel: true,
                ),
              ),
            ),
          );
          for (var i = 0; i < 20; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 25));
            await tester.pump();
            if (find.byType(ChordLineWidget).evaluate().isNotEmpty) break;
          }
        });

        expect(find.text('TONO  G'), findsOneWidget);
        expect(find.text('C D E'), findsOneWidget);

        // Toggle to Latin notation from the song view bar
        await tester.tap(find.text('C D E'));
        await tester.pump();

        expect(settings.chordNotation, ChordNotation.latin);
        expect(find.text('Do Re'), findsOneWidget);
        expect(find.text('TONO  Sol'), findsOneWidget);

        // Transpose up 2 semitones while in Latin notation: Sol -> La
        await tester.tap(find.byTooltip('Subir un semitono'));
        await tester.tap(find.byTooltip('Subir un semitono'));
        await tester.pump();

        expect(find.text('TONO  La'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
