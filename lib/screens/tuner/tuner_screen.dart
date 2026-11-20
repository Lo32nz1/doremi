import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/instrument.dart';
import '../../services/tuner_service.dart';
import 'widgets/instrument_selector.dart';
import 'widgets/string_indicator.dart';
import 'widgets/tuner_dial_painter.dart';

/// Pantalla principal del afinador cromático multi-instrumento.
class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen>
    with TickerProviderStateMixin {
  // ─── Servicio ──────────────────────────────────────────────────────────────
  late final TunerService _tuner;
  late final StreamSubscription<TunerResult> _resultSubscription;

  // ─── Estado ────────────────────────────────────────────────────────────────
  Instrument _selectedInstrument = InstrumentCatalog.all.first; // Cromático
  InstrumentString? _lockedString;
  TunerResult _lastResult = TunerResult.empty;
  bool _hasPermission = false;
  bool _permissionChecked = false;

  /// Pulso de resplandor: se activa solo cuando isInTune == true
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  /// Botón de inicio: animación de pulso suave
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ─── Colores interpolados ──────────────────────────────────────────────────

  Color get _needleColor {
    final abs = _lastResult.centsOff.abs();
    if (_lastResult.confidence < 0.1) {
      return Colors.white.withValues(alpha: 0.3);
    } else if (abs <= 5) {
      return Colors.green;
    } else if (abs <= 15) {
      return Color.lerp(Colors.green, const Color(0xFFF5A623), (abs - 5) / 10)!;
    } else if (abs <= 30) {
      return Color.lerp(
        const Color(0xFFF5A623),
        Colors.redAccent,
        (abs - 15) / 15,
      )!;
    } else {
      return Colors.redAccent;
    }
  }

  Color get _arcColor {
    final theme = Theme.of(context);
    return theme.colorScheme.onSurface;
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tuner = TunerService();
    _resultSubscription = _tuner.results.listen(
      _handleResult,
      onError: _handleTunerError,
    );

    // Resplandor
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Pulso del botón
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkPermission();
  }

  @override
  void dispose() {
    unawaited(_resultSubscription.cancel());
    unawaited(_tuner.dispose());
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Permisos ──────────────────────────────────────────────────────────────

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (!mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
      _permissionChecked = true;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    setState(() => _hasPermission = status.isGranted);
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El afinador necesita acceso al micrófono para funcionar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Control del afinador ─────────────────────────────────────────────────

  Future<void> _toggleTuner() async {
    if (_tuner.isRunning) {
      await _tuner.stop();
      _pulseController.stop();
      _pulseController.reset();
      setState(() {});
    } else {
      if (!_hasPermission) {
        await _requestPermission();
        if (!mounted || !_hasPermission) return;
      }
      try {
        await _tuner.start();
        _tuner.setInstrument(_selectedInstrument);
        if (!mounted) {
          await _tuner.stop();
          return;
        }
        _pulseController.repeat(reverse: true);
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _handleResult(TunerResult result) {
    if (!mounted) return;
    if (result.isInTune && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!result.isInTune) {
      _glowController.stop();
      _glowController.reset();
    }
    setState(() => _lastResult = result);
  }

  void _handleTunerError(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo analizar el audio: $error'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onInstrumentSelected(Instrument instrument) {
    setState(() {
      _selectedInstrument = instrument;
      _lockedString = null;
      _lastResult = TunerResult.empty;
    });
    _tuner.setInstrument(instrument);
  }

  void _onStringTapped(InstrumentString? string) {
    setState(() {
      _lockedString = string;
      _lastResult = TunerResult.empty;
    });
    _tuner.lockString(string);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D0D1A)
          : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Afinador',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: !_permissionChecked
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(theme, isDark),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),

          // ── Selector de instrumento ───────────────────────────────────────
          InstrumentSelector(
            selectedInstrument: _selectedInstrument,
            onSelected: _onInstrumentSelected,
          ),

          const SizedBox(height: 20),

          // ── Cuerdas del instrumento ───────────────────────────────────────
          SizedBox(
            height: 56,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: StringIndicator(
                key: ValueKey(_selectedInstrument.id),
                instrument: _selectedInstrument,
                currentResult: _lastResult,
                lockedString: _lockedString,
                onStringTapped: _onStringTapped,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Dial principal ────────────────────────────────────────────────
          Expanded(child: _buildDialSection(theme, isDark)),

          // ── Botón de inicio/pausa ─────────────────────────────────────────
          _buildStartButton(theme),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDialSection(ThemeData theme, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Dial (CustomPainter) ────────────────────────────────────────────
        Expanded(
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) => TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: _tuner.isRunning ? _lastResult.centsOff : 0,
              ),
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              builder: (context, centsOff, _) => CustomPaint(
                painter: TunerDialPainter(
                  centsOff: centsOff,
                  needleColor: _tuner.isRunning
                      ? _needleColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  arcColor: _arcColor,
                  isInTune: _lastResult.isInTune && _tuner.isRunning,
                  glowProgress: _glowAnimation.value,
                ),
                child: Container(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Nombre de la nota ───────────────────────────────────────────────
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: theme.textTheme.displayLarge!.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 72,
            color: _tuner.isRunning
                ? _needleColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            letterSpacing: -2,
          ),
          child: Text(_tuner.isRunning ? _lastResult.noteName : '—'),
        ),

        if (_lockedString case final target?) ...[
          const SizedBox(height: 2),
          Text(
            'Objetivo: ${target.name}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],

        const SizedBox(height: 4),

        // ── Frecuencia en Hz ────────────────────────────────────────────────
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: theme.textTheme.bodyMedium!.copyWith(
            color: _tuner.isRunning
                ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            fontSize: 14,
            fontVariations: const [FontVariation('wght', 400)],
          ),
          child: Text(
            _tuner.isRunning && _lastResult.frequencyHz > 0
                ? '${_lastResult.frequencyHz.toStringAsFixed(1)} Hz'
                : '',
          ),
        ),

        // ── Indicador de cents ──────────────────────────────────────────────
        const SizedBox(height: 8),
        _buildCentsIndicator(theme),

        // ── Etiqueta de estado ──────────────────────────────────────────────
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: theme.textTheme.labelLarge!.copyWith(
            color: _statusColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          child: Text(_statusLabel),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCentsIndicator(ThemeData theme) {
    if (!_tuner.isRunning || _lastResult.confidence < 0.1) {
      return const SizedBox(height: 20);
    }

    final cents = _lastResult.centsOff.round();
    final sign = cents > 0 ? '+' : '';
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: theme.textTheme.bodySmall!.copyWith(
        color: _needleColor.withValues(alpha: 0.8),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      child: Text('$sign$cents cents'),
    );
  }

  Widget _buildStartButton(ThemeData theme) {
    final isRunning = _tuner.isRunning;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isRunning ? _pulseAnimation.value : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: _toggleTuner,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 160,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: isRunning
                ? Colors.redAccent.withValues(alpha: 0.15)
                : theme.colorScheme.primary,
            border: Border.all(
              color: isRunning ? Colors.redAccent : theme.colorScheme.primary,
              width: 2,
            ),
            boxShadow: isRunning
                ? null
                : [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRunning ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: isRunning
                    ? Colors.redAccent
                    : theme.colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isRunning ? 'Detener' : 'Afinar',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isRunning
                      ? Colors.redAccent
                      : theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers de estado ─────────────────────────────────────────────────────

  String get _statusLabel {
    if (!_tuner.isRunning) return 'Presioná Afinar para comenzar';
    if (_lastResult.confidence < 0.1) return 'Escuchando...';
    if (_lastResult.isInTune) return '✓  Afinado';
    final cents = _lastResult.centsOff;
    if (cents < -5) return '↓  Muy bajo';
    if (cents > 5) return '↑  Muy alto';
    return 'Cerca...';
  }

  Color get _statusColor {
    if (!_tuner.isRunning) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);
    }
    if (_lastResult.isInTune) {
      return Colors.green;
    }
    if (_lastResult.confidence < 0.1) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);
    }
    return _needleColor;
  }
}
