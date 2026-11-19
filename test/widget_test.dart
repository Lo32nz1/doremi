import 'package:flutter_test/flutter_test.dart';
import 'package:doremi/main.dart';
import 'package:doremi/widgets/chord_lyrics_viewer.dart';
import 'package:doremi/models/song.dart';

void main() {
  testWidgets('DoReMiApp carga las 3 pestañas principales y canciones de ejemplo',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DoReMiApp());

    // Verifica que estén las 3 pestañas en la barra de navegación
    expect(find.text('Cancionero'), findsWidgets);
    expect(find.text('Repertorios'), findsOneWidget);
    expect(find.text('Afinador'), findsOneWidget);

    // Verifica las 3 canciones iniciales en memoria
    expect(find.text('De Música Ligera'), findsOneWidget);
    expect(find.text('Flaca'), findsOneWidget);
    expect(find.text('Cielito Lindo'), findsOneWidget);
  });

  test('ChordTransposer transporta acordes latinos y americanos (+1 / -1)', () {
    expect(ChordTransposer.transposeChord('Do', 2), 'Re');
    expect(ChordTransposer.transposeChord('Do', -1), 'Si');
    expect(ChordTransposer.transposeChord('La m', 2), 'Si m');
    expect(ChordTransposer.transposeChord('Si m', 1), 'Do m');
    expect(ChordTransposer.transposeChord('Fa# m', -1), 'Fa m');
    expect(ChordTransposer.transposeChord('Am', 2), 'Bm');
    expect(ChordTransposer.transposeChord('C#m', 1), 'Dm');
  });

  test('Song exporta e importa formato .cho (ChordPro)', () {
    final original = SongRepository.instance.songs.first;
    final choText = original.toChordPro();
    final parsed = Song.fromChordPro(choText, customId: 'test-id');

    expect(parsed.title, original.title);
    expect(parsed.artist, original.artist);
    expect(parsed.baseKey, original.baseKey);
    expect(parsed.content, original.content);
  });
}
