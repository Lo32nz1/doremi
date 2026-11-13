import 'package:cancionero/models/song.dart';
import 'package:cancionero/providers/library_provider.dart';
import 'package:cancionero/providers/settings_provider.dart';
import 'package:cancionero/providers/setlist_provider.dart';
import 'package:cancionero/screens/home_screen.dart';
import 'package:cancionero/screens/shell_screen.dart';
import 'package:cancionero/widgets/mobile_song_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('study adapts tablet portrait and landscape layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final library = LibraryProvider();
    final settings = SettingsProvider(preferences);
    final setlists = SetlistProvider();
    addTearDown(library.dispose);
    addTearDown(settings.dispose);
    addTearDown(setlists.dispose);
    await setlists.loadSetlists();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: library),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: setlists),
        ],
        child: const MaterialApp(home: ShellScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estudio').first);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.text('Selecciona una canción de la lista'), findsOneWidget);

    tester.view.physicalSize = const Size(1100, 800);
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byTooltip('Volver a canciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android back asks before closing from the home screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final library = LibraryProvider();
    final settings = SettingsProvider(preferences);
    final setlists = SetlistProvider();
    addTearDown(library.dispose);
    addTearDown(settings.dispose);
    addTearDown(setlists.dispose);
    await setlists.loadSetlists();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: library),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: setlists),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const ShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('¿Cerrar DOREMI?'), findsOneWidget);
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar DOREMI?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('study keeps the app navigation visible on its song list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final library = LibraryProvider();
    final settings = SettingsProvider(preferences);
    final setlists = SetlistProvider();
    addTearDown(library.dispose);
    addTearDown(settings.dispose);
    addTearDown(setlists.dispose);
    await setlists.loadSetlists();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: library),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: setlists),
        ],
        child: const MaterialApp(home: ShellScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estudio').first);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.text('Elegí la carpeta de tus canciones para empezar.'),
      findsOneWidget,
    );

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byTooltip('Volver a canciones'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver a canciones'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home welcomes the user on a narrow screen without a library', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final library = LibraryProvider();
    addTearDown(library.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: library),
          ChangeNotifierProvider(create: (_) => SettingsProvider(preferences)),
        ],
        child: MaterialApp(
          home: HomeScreen(onOpenSong: (_) {}, onOpenStudy: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Bienvenido a DOREMI!'), findsOneWidget);
    expect(find.text('Elegir carpeta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('library provider persists recent song opens', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final library = LibraryProvider();
    addTearDown(library.dispose);
    final song = SongMetadata(
      title: 'Canción de prueba',
      artist: '',
      key: '',
      filePath: '/songs/test.chord',
    );

    await library.recordSongOpened(song);

    expect(preferences.getStringList('recent_song_paths'), [
      '/songs/test.chord',
    ]);
    expect(preferences.getInt('song_open_count'), 1);
  });

  test('setlist reorder accepts the adjusted destination index', () async {
    SharedPreferences.setMockInitialValues({});
    final setlists = SetlistProvider();
    addTearDown(setlists.dispose);
    await setlists.createSetlist('Prueba');
    final setlistId = setlists.setlists.single.id;
    await setlists.addSongToSetlist(setlistId, '/songs/one.chord');
    await setlists.addSongToSetlist(setlistId, '/songs/two.chord');
    await setlists.addSongToSetlist(setlistId, '/songs/three.chord');

    await setlists.reorderSongs(setlistId, 0, 2);

    expect(setlists.setlists.single.songPaths, [
      '/songs/two.chord',
      '/songs/three.chord',
      '/songs/one.chord',
    ]);
  });

  testWidgets('mobile song controls fit a narrow screen and respond to taps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var fontSize = 18;
    var transposeSteps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: MobileSongControls(
              keyLabel: transposeSteps == 0 ? 'G' : 'G $transposeSteps',
              fontSize: fontSize,
              onTransposeDown: () => setState(() => transposeSteps--),
              onTransposeUp: () => setState(() => transposeSteps++),
              onFontSizeDown: () => setState(() => fontSize--),
              onFontSizeUp: () => setState(() => fontSize++),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tono'), findsOneWidget);
    expect(find.text('Letra'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('18 px'), findsOneWidget);

    await tester.tap(find.byTooltip('Subir un semitono'));
    await tester.tap(find.byTooltip('Aumentar tamaño de letra'));
    await tester.pump();

    expect(find.text('G 1'), findsOneWidget);
    expect(find.text('19 px'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
