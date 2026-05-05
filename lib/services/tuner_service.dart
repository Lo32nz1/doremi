import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

import '../models/instrument.dart';

// ─── Modelo de resultado ─────────────────────────────────────────────────────

/// Resultado procesado de una detección de tono.
class TunerResult {
  final double frequencyHz;
  final String noteName;   // Ej: "A", "E", "D#"
  final int octave;
  final double centsOff;   // −50 a +50; 0 = perfectamente afinado
  final double confidence; // 0.0 a 1.0
  final bool isInTune;     // true si |centsOff| < 5

  /// Nota objetivo más cercana para el instrumento activo (puede ser null en modo cromático)
  final InstrumentString? nearestString;

  const TunerResult({
    required this.frequencyHz,
    required this.noteName,
    required this.octave,
    required this.centsOff,
    required this.confidence,
    required this.isInTune,
    this.nearestString,
  });

  /// Estado vacío (sin señal)
  static const TunerResult empty = TunerResult(
    frequencyHz: 0,
    noteName: '—',
    octave: 4,
    centsOff: 0,
    confidence: 0,
    isInTune: false,
  );
}

// ─── Nombres de notas ────────────────────────────────────────────────────────

const List<String> _noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F',
  'F#', 'G', 'G#', 'A', 'A#', 'B',
];

// ─── Servicio principal ──────────────────────────────────────────────────────

/// Orquesta la captura de audio y la detección de pitch en tiempo real.
///
/// Uso:
/// ```dart
/// final service = TunerService();
/// await service.start();
/// service.results.listen((r) { /* actualizar UI */ });
/// // Al salir de la pantalla:
/// await service.stop();
/// service.dispose();
/// ```
class TunerService {
  static const int _sampleRate = 44100;
  static const int _bufferSizeFrames = 2048;

  // Umbral de confianza por debajo del cual ignoramos el resultado
  static const double _confidenceThreshold = 0.80;

  // Umbral de cents para considerar "afinado"
  static const double _inTuneCentsThreshold = 5.0;

  final AudioRecorder _recorder = AudioRecorder();
  final PitchDetector _pitchDetector = PitchDetector(
    audioSampleRate: _sampleRate.toDouble(),
    bufferSize: _bufferSizeFrames,
  );

  StreamSubscription<Uint8List>? _audioSubscription;
  final StreamController<TunerResult> _resultController =
      StreamController<TunerResult>.broadcast();

  // Buffer acumulador de bytes PCM (int16 little-endian)
  final List<int> _byteBuffer = [];

  bool _isRunning = false;

  // Instrumento activo (null = modo cromático)
  Instrument? _activeInstrument;

  // Cuerda fijada manualmente (null = auto-detect)
  InstrumentString? _lockedString;

  /// Stream de resultados procesados. Escuchar este stream en la UI.
  Stream<TunerResult> get results => _resultController.stream;

  bool get isRunning => _isRunning;

  // ─── Control ─────────────────────────────────────────────────────────────

  /// Inicia la captura de audio. Lanza [Exception] si no hay permiso.
  Future<void> start() async {
    if (_isRunning) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Permiso de micrófono denegado.');
    }

    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: _sampleRate,
      numChannels: 1,
    );

    final stream = await _recorder.startStream(config);
    _isRunning = true;

    _audioSubscription = stream.listen(_onAudioData, onError: _onError);
  }

  /// Detiene la captura de audio y libera el micrófono.
  Future<void> stop() async {
    if (!_isRunning) return;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder.stop();
    _byteBuffer.clear();
    _isRunning = false;
    // Emitir estado vacío para que la UI regrese al reposo
    _resultController.add(TunerResult.empty);
  }

  /// Libera todos los recursos. Llamar en dispose() del widget.
  void dispose() {
    stop();
    _recorder.dispose(); // En record 6.x dispose() es async pero no bloqueamos
    _resultController.close();
  }

  /// Cambia el instrumento activo. Resetea la cuerda fijada.
  void setInstrument(Instrument? instrument) {
    _activeInstrument = instrument;
    _lockedString = null;
  }

  /// Fija una cuerda específica (modo single-string).
  void lockString(InstrumentString? string) {
    _lockedString = string;
  }

  // ─── Procesamiento de audio ───────────────────────────────────────────────

  void _onAudioData(Uint8List bytes) {
    // Acumular bytes crudos (PCM16 little-endian)
    _byteBuffer.addAll(bytes);

    // Cada frame PCM16 son 2 bytes, necesitamos _bufferSizeFrames frames
    final bytesNeeded = _bufferSizeFrames * 2;

    while (_byteBuffer.length >= bytesNeeded) {
      final chunk = Uint8List.fromList(_byteBuffer.sublist(0, bytesNeeded));
      _byteBuffer.removeRange(0, bytesNeeded);
      _processChunk(chunk);
    }
  }

  void _processChunk(Uint8List pcm16Bytes) {
    _pitchDetector.getPitchFromIntBuffer(pcm16Bytes).then((result) {
      if (!result.pitched || result.probability < _confidenceThreshold) return;
      final tunerResult = _buildResult(result.pitch, result.probability);
      _resultController.add(tunerResult);
    }).catchError((_) {});
  }

  TunerResult _buildResult(double hz, double confidence) {
    // ── Convertir Hz → número de semitono MIDI ──
    // A4 = 440 Hz = MIDI 69
    final midiNote = 69.0 + 12.0 * _log2(hz / 440.0);
    final roundedMidi = midiNote.round();

    // ── Nota y octava ──
    final noteIndex = ((roundedMidi % 12) + 12) % 12;
    final octave = (roundedMidi ~/ 12) - 1;
    final noteName = _noteNames[noteIndex];

    // ── Cents de desviación ──
    final referenceHz = 440.0 * math.pow(2.0, (roundedMidi - 69.0) / 12.0);
    final centsOff = 1200.0 * _log2(hz / referenceHz);

    // ── Nota objetivo más cercana ──
    InstrumentString? nearestString = _lockedString;
    if (nearestString == null && _activeInstrument != null && _activeInstrument!.strings.isNotEmpty) {
      nearestString = _activeInstrument!.strings.reduce((a, b) {
        final diffA = (hz - a.frequency).abs();
        final diffB = (hz - b.frequency).abs();
        return diffA < diffB ? a : b;
      });
    }

    return TunerResult(
      frequencyHz: hz,
      noteName: noteName,
      octave: octave,
      centsOff: centsOff.clamp(-50.0, 50.0),
      confidence: confidence,
      isInTune: centsOff.abs() <= _inTuneCentsThreshold,
      nearestString: nearestString,
    );
  }

  void _onError(Object error) {
    // Silencioso en producción; se podría loguear
  }

  static double _log2(double x) => math.log(x) / math.ln2;
}
