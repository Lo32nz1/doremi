import 'dart:math' as math;

import 'package:cancionero/models/instrument.dart';
import 'package:cancionero/models/song.dart';
import 'package:cancionero/providers/library_provider.dart';
import 'package:cancionero/providers/settings_provider.dart';
import 'package:cancionero/providers/setlist_provider.dart';
import 'package:cancionero/screens/home_screen.dart';
import 'package:cancionero/screens/shell_screen.dart';
import 'package:cancionero/screens/tuner/tuner_screen.dart';
import 'package:cancionero/services/tuner_service.dart';
import 'package:cancionero/widgets/mobile_song_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('tuner compares pitch against the selected string', () {
    final e2 = InstrumentCatalog.all[1].strings.first;
    final correctString = TunerResult.fromFrequency(
      frequencyHz: e2.frequency,
      confidence: 1,
      instrument: InstrumentCatalog.all[1],
      lockedString: e2,
    );
    final wrongString = TunerResult.fromFrequency(
      frequencyHz: 440,
      confidence: 1,
      instrument: InstrumentCatalog.all[1],
      lockedString: e2,
    );

    expect(correctString.noteName, 'E');
    expect(correctString.nearestString, e2);
    expect(correctString.isInTune, isTrue);
    final slightlyFlatString = TunerResult.fromFrequency(
      frequencyHz: e2.frequency * math.pow(2, -8 / 1200),
      confidence: 1,
      lockedString: e2,
    );
    expect(slightlyFlatString.isInTune, isTrue);
    expect(slightlyFlatString.centsOff, 0);
    final outsideTolerance = TunerResult.fromFrequency(
      frequencyHz: e2.frequency * math.pow(2, -12 / 1200).toDouble(),
      confidence: 1,
      lockedString: e2,
    );
    expect(outsideTolerance.isInTune, isFalse);
    expect(wrongString.noteName, 'A');
    expect(wrongString.nearestString, e2);
    expect(wrongString.isInTune, isFalse);
    expect(wrongString.centsOff, 50);
  });

  test('instrument catalog uses the requested standard tunings', () {
    final guitar = InstrumentCatalog.all.singleWhere(
      (instrument) => instrument.id == 'guitar_standard',
    );
    final bass = InstrumentCatalog.all.singleWhere(
      (instrument) => instrument.id == 'bass',
    );
    final ukulele = InstrumentCatalog.all.singleWhere(
      (instrument) => instrument.id == 'ukulele',
    );
    final violin = InstrumentCatalog.all.singleWhere(
      (instrument) => instrument.id == 'violin',
    );

    expect(
      InstrumentCatalog.all.any(
        (instrument) => instrument.id == 'guitar_drop_d',
      ),
      isFalse,
    );
    expect(guitar.strings.map((string) => string.name), [
      'E2',
      'A2',
      'D3',
      'G3',
      'B3',
      'E4',
    ]);
    expect(guitar.strings.map((string) => string.frequency), [
      82.41,
      110.00,
      146.83,
      196.00,
      246.94,
      329.63,
    ]);
    expect(bass.strings.map((string) => string.frequency), [
      41.20,
      55.00,
      73.42,
      98.00,
    ]);
    expect(ukulele.strings.map((string) => string.name), [
      'G4',
      'C4',
      'E4',
      'A4',
    ]);
    expect(ukulele.strings.map((string) => string.frequency), [
      392.00,
      261.63,
      329.63,
      440.00,
    ]);
    expect(violin.strings.map((string) => string.name), [
      'G3',
      'D4',
      'A4',
      'E5',
    ]);
    expect(violin.strings.map((string) => string.frequency), [
      196.00,
      293.66,
      440.00,
      659.26,
    ]);
  });

  test('tuner pitch smoother filters short frequency spikes', () {
    final smoother = TunerPitchSmoother();
    smoother.add(440);
    smoother.add(441);
    smoother.add(439);

    final filtered = smoother.add(493.88)!;
    expect(filtered, closeTo(440, 2));
    expect(smoother.add(double.nan), isNull);

    smoother.add(493.88);
    smoother.add(493.88);
    smoother.add(493.88);
    var stabilized = 0.0;
    for (var i = 0; i < 20; i++) {
      stabilized = smoother.add(493.88)!;
    }
    expect(stabilized, closeTo(493.88, 1));

    smoother.reset();
    expect(smoother.add(329.63), closeTo(329.63, 0.01));
  });

  testWidgets('tuner stays in app navigation and has no back button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const permissionChannel = MethodChannel(
      'flutter.baseflow.com/permissions/methods',
    );
    const recordChannel = MethodChannel('com.llfbandit.record/messages');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      permissionChannel,
      (call) async => 0,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      recordChannel,
      (call) async => null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        permissionChannel,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        recordChannel,
        null,
      );
    });

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
    await tester.tap(find.text('Afinador').first);
    await tester.pumpAndSettle();

    expect(find.byType(TunerScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    await tester.tap(find.text('Guitarra').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Afinar cuerda E2'));
    await tester.pumpAndSettle();
    expect(find.text('Objetivo: E2'), findsOneWidget);
    await tester.tap(find.text('Inicio').first);
    await tester.pumpAndSettle();
    expect(find.byType(TunerScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
        child: MaterialApp(home: HomeScreen(onOpenSong: (_) {})),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.text('¡Crea y disfruta de tus canciones!'), findsOneWidget);
    expect(find.text('Elegir carpeta'), findsOneWidget);
    expect(find.text('Abrir Estudio'), findsNothing);
    expect(find.text('Ir al Estudio'), findsNothing);
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
