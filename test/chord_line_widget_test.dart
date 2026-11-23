import 'dart:io';

import 'package:cancionero/models/song.dart';
import 'package:cancionero/providers/library_provider.dart';
import 'package:cancionero/providers/setlist_provider.dart';
import 'package:cancionero/providers/settings_provider.dart';
import 'package:cancionero/screens/song_view_screen.dart';
import 'package:cancionero/widgets/chord_line_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('tokenizeSongLine', () {
    test('keeps mid-word chords inside a single atomic word token', () {
      final tokens = tokenizeSongLine(const [
        SongChunk(lyrics: 'How '),
        SongChunk(chord: 'G', lyrics: 'precious '),
        SongChunk(chord: 'C', lyrics: 'grace ap'),
        SongChunk(chord: 'G', lyrics: 'pear'),
      ]);

      expect(tokens.map((t) => t.lyrics).toList(), [
        'How',
        'precious',
        'grace',
        'appear',
      ]);
      expect(tokens.last.segments.length, 2);
      expect(tokens.last.segments[0].chord, isNull);
      expect(tokens.last.segments[0].text, 'ap');
      expect(tokens.last.segments[1].chord, 'G');
      expect(tokens.last.segments[1].text, 'pear');
    });

    test('splits multi-word chunks into individual word tokens', () {
      final tokens = tokenizeSongLine(const [
        SongChunk(chord: 'G', lyrics: 'A ti sea la gloria y la '),
        SongChunk(chord: 'D', lyrics: 'honra'),
      ]);

      expect(tokens.map((t) => t.lyrics).toList(), [
        'A',
        'ti',
        'sea',
        'la',
        'gloria',
        'y',
        'la',
        'honra',
      ]);
      expect(tokens.first.segments.single.chord, 'G');
      expect(tokens[1].hasChords, isFalse);
      expect(tokens.last.segments.single.chord, 'D');
    });

    test('handles chord-only intro lines with and without spaces', () {
      final spaced = tokenizeSongLine(const [
        SongChunk(chord: 'G', lyrics: '  '),
        SongChunk(chord: 'D', lyrics: '  '),
        SongChunk(chord: 'Em', lyrics: '  '),
        SongChunk(chord: 'C', lyrics: ''),
      ]);
      expect(spaced.length, 4);
      expect(spaced.map((t) => t.segments.single.chord).toList(), [
        'G',
        'D',
        'Em',
        'C',
      ]);

      final compact = tokenizeSongLine(const [
        SongChunk(chord: 'G', lyrics: ''),
        SongChunk(chord: 'D', lyrics: ''),
        SongChunk(chord: 'Em', lyrics: ''),
      ]);
      expect(compact.length, 3);
      expect(compact.map((t) => t.segments.single.chord).toList(), [
        'G',
        'D',
        'Em',
      ]);
    });

    test('handles a chord placed directly before a space', () {
      final tokens = tokenizeSongLine(const [
        SongChunk(chord: 'G', lyrics: 'Santo'),
        SongChunk(chord: 'D', lyrics: ' es el Señor'),
      ]);

      expect(tokens.length, 5);
      expect(tokens[0].lyrics, 'Santo');
      expect(tokens[1].segments.single.chord, 'D');
      expect(tokens[1].lyrics, '');
      expect(tokens[1].trailingSpace, ' ');
      expect(tokens[2].lyrics, 'es');
      expect(tokens[3].lyrics, 'el');
      expect(tokens[4].lyrics, 'Señor');
    });
  });

  group('computeChordLineLayout', () {
    const chordStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    const lyricStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );

    testWidgets('wraps whole word with mid-word chord instead of cutting it', (
      tester,
    ) async {
      final tokens = tokenizeSongLine(const [
        SongChunk(chord: 'C', lyrics: 'grace ap'),
        SongChunk(chord: 'G', lyrics: 'pear'),
      ]);

      // Narrow enough that "grace" and "appear" cannot both fit on one row,
      // but wide enough for each individual word.
      final singleWordWidth = computeChordLineLayout(
        tokens: [tokens.last],
        maxWidth: double.infinity,
        chordStyle: chordStyle,
        lyricStyle: lyricStyle,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        wrappedRowSpacing: 8,
      ).width;

      final result = computeChordLineLayout(
        tokens: tokens,
        maxWidth: singleWordWidth + 16,
        chordStyle: chordStyle,
        lyricStyle: lyricStyle,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        wrappedRowSpacing: 8,
      );

      expect(result.rows.length, 2);
      expect(result.rows[0].lyrics.map((l) => l.text).toList(), ['grace']);
      expect(result.rows[0].chords.map((c) => c.text).toList(), ['C']);
      expect(result.rows[1].lyrics.map((l) => l.text).toList(), ['appear']);
      expect(result.rows[1].chords.map((c) => c.text).toList(), ['G']);
      // Chord G sits over "pear", strictly after the start of "appear"
      expect(result.rows[1].chords.single.x, greaterThan(0));
    });

    testWidgets('keeps multi-word chunk flowing so next chord continues inline',
        (tester) async {
      final tokens = tokenizeSongLine(const [
        SongChunk(chord: 'G', lyrics: 'A ti sea la gloria y la '),
        SongChunk(chord: 'D', lyrics: 'honra'),
      ]);

      // In test Ahem font, each character is 20px wide; 360px fits 18 chars:
      // Row 0: "A ti sea la gloria" (18 chars), Row 1: "y la honra" (10 chars).
      final result = computeChordLineLayout(
        tokens: tokens,
        maxWidth: 360,
        chordStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        lyricStyle: const TextStyle(fontSize: 20),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        wrappedRowSpacing: 6,
      );

      // "honra" should share a visual row with "y" and "la" rather than
      // being forced alone onto a separate row.
      expect(result.rows.length, 2);
      expect(result.rows[0].lyrics.map((l) => l.text).toList(), [
        'A',
        'ti',
        'sea',
        'la',
        'gloria',
      ]);
      expect(result.rows[1].lyrics.map((l) => l.text).toList(), [
        'y',
        'la',
        'honra',
      ]);
      expect(result.rows[1].chords.map((c) => c.text).toList(), ['D']);
      for (final row in result.rows) {
        expect(row.width, lessThanOrEqualTo(360.01));
      }
    });

    testWidgets('prevents overlapping chords inside a single word', (
      tester,
    ) async {
      final tokens = tokenizeSongLine(const [
        SongChunk(chord: 'C#m7', lyrics: 'A'),
        SongChunk(chord: 'G', lyrics: 'l'),
      ]);

      final result = computeChordLineLayout(
        tokens: tokens,
        maxWidth: 400,
        chordStyle: chordStyle,
        lyricStyle: lyricStyle,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        wrappedRowSpacing: 8,
      );

      expect(result.rows.length, 1);
      // Word remains unbroken ("Al") while chords do not overlap.
      expect(result.rows.single.lyrics.single.text, 'Al');
      final firstChord = result.rows.single.chords[0];
      final secondChord = result.rows.single.chords[1];
      expect(secondChord.x, greaterThan(firstChord.x + firstChord.width));
    });

    testWidgets('splits an oversized single word without exceeding maxWidth', (
      tester,
    ) async {
      final tokens = tokenizeSongLine(const [
        SongChunk(lyrics: 'todopode'),
        SongChunk(chord: 'G', lyrics: 'roso'),
      ]);

      const narrowWidth = 180.0;
      final result = computeChordLineLayout(
        tokens: tokens,
        maxWidth: narrowWidth,
        chordStyle: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
        lyricStyle: const TextStyle(fontSize: 36),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        wrappedRowSpacing: 10,
      );

      expect(result.rows.length, greaterThan(1));
      expect(
        result.rows.expand((r) => r.lyrics).map((l) => l.text).join(),
        'todopoderoso',
      );
      expect(
        result.rows.expand((r) => r.chords).map((c) => c.text).toList(),
        ['G'],
      );
      for (final row in result.rows) {
        expect(row.width, lessThanOrEqualTo(narrowWidth + 0.01));
      }
    });

    testWidgets('collapses unused chord height on chordless wrapped rows', (
      tester,
    ) async {
      final tokens = tokenizeSongLine(const [
        SongChunk(
          chord: 'G',
          lyrics: 'Cuando veo tu gloria y tu gran majestad hoy ',
        ),
        SongChunk(chord: 'D', lyrics: 'Señor'),
      ]);

      final result = computeChordLineLayout(
        tokens: tokens,
        maxWidth: 260,
        chordStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        lyricStyle: const TextStyle(fontSize: 22),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        wrappedRowSpacing: 6,
      );

      final chordlessRows = result.rows.where((r) => r.chords.isEmpty);
      expect(chordlessRows, isNotEmpty);
      for (final row in chordlessRows) {
        expect(row.lyricY, row.chordY);
      }
    });
  });

  group('ChordLineWidget and SongViewScreen large font rendering', () {
    testWidgets(
      'ChordLineWidget renders cleanly at 40px inside narrow width and IntrinsicHeight',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const line = SongLine(
          chunks: [
            SongChunk(lyrics: 'How '),
            SongChunk(chord: 'G', lyrics: 'precious '),
            SongChunk(chord: 'G7', lyrics: 'did that '),
            SongChunk(chord: 'C', lyrics: 'grace ap'),
            SongChunk(chord: 'G', lyrics: 'pear'),
          ],
          inlineRightComment: 'x2',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(14),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 3),
                      SizedBox(width: 10),
                      Expanded(
                        child: ChordLineWidget(
                          line: line,
                          fontSize: 40,
                          showChords: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ChordLineWidget), findsOneWidget);
        expect(find.text('X2'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('SongViewScreen renders sample song at 38px without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final samplePath = File('sample_songs/amazing_grace.chord').absolute.path;
      expect(File(samplePath).existsSync(), isTrue);

      SharedPreferences.setMockInitialValues({'font_size': 38.0});
      final preferences = await SharedPreferences.getInstance();
      final library = LibraryProvider();
      final settings = SettingsProvider(preferences);
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

      expect(find.text('Amazing Grace'), findsWidgets);
      expect(find.byType(ChordLineWidget), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
