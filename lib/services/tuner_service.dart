import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

import '../models/instrument.dart';

const double _tuningToleranceCents = 10.0;

// ─── Modelo de resultado ─────────────────────────────────────────────────────

/// Resultado procesado de una detección de tono.
class TunerResult {
  final double frequencyHz;
  final String noteName; // Ej: "A", "E", "D#"
  final int octave;
  final double centsOff; // −50 a +50; 0 = dentro de la tolerancia de afinacion
  final double confidence; // 0.0 a 1.0
  final bool isInTune; // true si la desviacion es de hasta 10 cents

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

  static TunerResult fromFrequency({
    required double frequencyHz,
    required double confidence,
    Instrument? instrument,
    InstrumentString? lockedString,
  }) {
    if (!frequencyHz.isFinite || frequencyHz <= 0) {
      throw ArgumentError.value(frequencyHz, 'frequencyHz');
    }

    final midiNote = 69.0 + 12.0 * _log2(frequencyHz / 440.0);
    final roundedMidi = midiNote.round();
    final noteIndex = ((roundedMidi % 12) + 12) % 12;
    final octave = (roundedMidi ~/ 12) - 1;
    final noteName = _noteNames[noteIndex];
    final chromaticFrequency =
        440.0 * math.pow(2.0, (roundedMidi - 69.0) / 12.0);

    InstrumentString? targetString = lockedString;
    if (targetString == null &&
        instrument != null &&
        instrument.strings.isNotEmpty) {
      targetString = instrument.strings.reduce((a, b) {
        final differenceA = _log2(frequencyHz / a.frequency).abs();
        final differenceB = _log2(frequencyHz / b.frequency).abs();
        return differenceA < differenceB ? a : b;
      });
    }

    final targetFrequency = targetString?.frequency ?? chromaticFrequency;
    final measuredCentsOff = 1200.0 * _log2(frequencyHz / targetFrequency);
    final isInTune = measuredCentsOff.abs() <= _tuningToleranceCents;

    return TunerResult(
      frequencyHz: frequencyHz,
      noteName: noteName,
      octave: octave,
      centsOff: isInTune ? 0 : measuredCentsOff.clamp(-50.0, 50.0),
      confidence: confidence,
      isInTune: isInTune,
      nearestString: targetString,
    );
  }

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

class TunerPitchSmoother {
  static const int _windowSize = 7;
  final List<double> _midiSamples = [];
  double? _smoothedMidi;

  double? add(double frequencyHz) {
    if (!frequencyHz.isFinite || frequencyHz <= 0) return null;

    final midi = 69.0 + 12.0 * _log2(frequencyHz / 440.0);
    _midiSamples.add(midi);
    if (_midiSamples.length > _windowSize) {
      _midiSamples.removeAt(0);
    }

    final sorted = List<double>.of(_midiSamples)..sort();
    final median = sorted[sorted.length ~/ 2];
    final current = _smoothedMidi;
    _smoothedMidi = current == null
        ? median
        : current + (median - current) * 0.35;
    return 440.0 * math.pow(2.0, (_smoothedMidi! - 69.0) / 12.0);
  }

  void reset() {
    _midiSamples.clear();
    _smoothedMidi = null;
  }

  static double _log2(double value) => math.log(value) / math.ln2;
}

// ─── Nombres de notas ────────────────────────────────────────────────────────

const List<String> _noteNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
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

  final AudioRecorder _recorder = AudioRecorder();
  final PitchDetector _pitchDetector = PitchDetector(
    audioSampleRate: _sampleRate.toDouble(),
    bufferSize: _bufferSizeFrames,
  );

  StreamSubscription<Uint8List>? _audioSubscription;
  final StreamController<TunerResult> _resultController =
      StreamController<TunerResult>.broadcast();
  final TunerPitchSmoother _pitchSmoother = TunerPitchSmoother();

  // Buffer acumulador de bytes PCM (int16 little-endian)
  final List<int> _byteBuffer = [];
  Future<void> _processing = Future<void>.value();

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
  Future<void> stop({bool emitResult = true}) async {
    final wasRunning = _isRunning;
    _isRunning = false;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    if (wasRunning) {
      await _recorder.stop();
    }
    _byteBuffer.clear();
    _pitchSmoother.reset();
    // Emitir estado vacío para que la UI regrese al reposo
    if (emitResult && !_resultController.isClosed) {
      _resultController.add(TunerResult.empty);
    }
  }

  /// Libera todos los recursos. Llamar en dispose() del widget.
  Future<void> dispose() async {
    try {
      await stop(emitResult: false);
    } finally {
      await _recorder.dispose();
      await _resultController.close();
    }
  }

  /// Cambia el instrumento activo. Resetea la cuerda fijada.
  void setInstrument(Instrument? instrument) {
    _activeInstrument = instrument;
    _lockedString = null;
    _pitchSmoother.reset();
  }

  /// Fija una cuerda específica (modo single-string).
  void lockString(InstrumentString? string) {
    _lockedString = string;
    _pitchSmoother.reset();
  }

  // ─── Procesamiento de audio ───────────────────────────────────────────────

  void _onAudioData(Uint8List bytes) {
    if (!_isRunning) return;
    // Acumular bytes crudos (PCM16 little-endian)
    _byteBuffer.addAll(bytes);

    // Cada frame PCM16 son 2 bytes, necesitamos _bufferSizeFrames frames
    final bytesNeeded = _bufferSizeFrames * 2;

    while (_byteBuffer.length >= bytesNeeded) {
      final chunk = Uint8List.fromList(_byteBuffer.sublist(0, bytesNeeded));
      _byteBuffer.removeRange(0, bytesNeeded);
      _processing = _processing.then((_) => _processChunk(chunk));
    }
  }

  Future<void> _processChunk(Uint8List pcm16Bytes) async {
    try {
      final result = await _pitchDetector.getPitchFromIntBuffer(pcm16Bytes);
      if (!_isRunning ||
          !result.pitched ||
          result.probability < _confidenceThreshold) {
        return;
      }
      final smoothedHz = _pitchSmoother.add(result.pitch);
      if (smoothedHz != null) {
        _resultController.add(
          TunerResult.fromFrequency(
            frequencyHz: smoothedHz,
            confidence: result.probability,
            instrument: _activeInstrument,
            lockedString: _lockedString,
          ),
        );
      }
    } catch (error, stackTrace) {
      if (!_resultController.isClosed) {
        _resultController.addError(error, stackTrace);
      }
    }
  }

  void _onError(Object error) {
    if (!_resultController.isClosed) {
      _resultController.addError(error);
    }
  }
}

double _log2(double x) => math.log(x) / math.ln2;
