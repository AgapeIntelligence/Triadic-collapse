// lib/ui/lattice_view.dart
// Live glowing triadic lattice visualizer — Triadic Collapse
// © 2025 Evie (@3vi3Aetheris) — MIT License

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:flutter_audio_capture/flutter_audio_capture.dart'; // For microphone
import '../core/evie_369_pure.dart';
import '../core/triadic_ghz_full_evolution.dart';

class LatticeView extends StatefulWidget {
  final int nOscillators;
  final double updateIntervalMs;

  const LatticeView({
    Key? key,
    this.nOscillators = 80000,
    this.updateIntervalMs = 16.6, // ~60fps
  }) : super(key: key);

  @override
  State<LatticeView> createState() => _LatticeViewState();
}

class _LatticeViewState extends State<LatticeView> with TickerProviderStateMixin {
  late Float64List phases;
  double R = 0.0;
  double currentDb = 45.0; // Default dB until mic updates
  late AnimationController pulseController;
  String lastCollapse = "";
  final Random rng = Random();

  // Microphone stream controller
  StreamSubscription? _micSubscription;
  final FlutterAudioCapture _audioCapture = FlutterAudioCapture();

  @override
  void initState() {
    super.initState();

    phases = Evie369Pure.initialise369Phases(
      nOscillators: widget.nOscillators,
      seed: 42,
    );
    R = Evie369Pure.orderParameter(phases);

    pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(() => setState(() {}));

    // Start microphone
    _startMicrophone();

    Timer.periodic(Duration(milliseconds: widget.updateIntervalMs.toInt()), (_) {
      Evie369Pure.kuramotoMeanFieldStep(phases, K: 3.69);
      final newR = Evie369Pure.orderParameter(phases);

      if ((newR - R).abs() > 0.0001 || newR > 0.9999) {
        setState(() => R = newR);
      }

      // Trigger collapse with live dB, with debounce
      if (R > 0.50 && !pulseController.isAnimating && rng.nextDouble() < 0.15) {
        final result = TriadicGHZ.evolveTriadicGHZ(
          R_lattice: R,
          voiceEnvelopeDb: currentDb,
          rng: rng,
        );
        setState(() {
          lastCollapse = result['outcome'] as String;
          pulseController.forward(from: 0.0);
        });
        _triggerHaptic(R, result['probPlus'] as double); // Pass probPlus for haptic intensity
      }
    });
  }

  @override
  void dispose() {
    _micSubscription?.cancel();
    _audioCapture.stop();
    pulseController.dispose();
    super.dispose();
  }

  // Start microphone and process audio
  Future<void> _startMicrophone() async {
    try {
      await _audioCapture.start(
        listener: (data) {
          final sum = data.reduce((a, b) => a + b.abs());
          final average = sum / data.length;
          final db = 20 * log(average / 1.0) + 60; // Adjust for Float64 range
          if (!db.isNaN && db.isFinite) {
            setState(() => currentDb = db.clamp(0.0, 100.0));
          }
        },
        onError: (error) => print("Mic error: $error"),
        sampleRate: 44100,
        bufferSize: 1024,
      );
    } catch (e) {
      print("Microphone initialization error: $e");
      setState(() => currentDb = 45.0);
    }
  }

  // Trigger haptic feedback with probPlus influence
  void _triggerHaptic(double intensity, double probPlus) {
    final adjustedIntensity = intensity * probPlus; // Scale by collapse probability
    if (adjustedIntensity < 0.3) {
      HapticFeedback.lightImpact();
    } else if (adjustedIntensity < 0.7) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TriadicLatticePainter(R, pulseController.value, lastCollapse, currentDb),
      size: Size.infinite,
    );
  }
}

class _TriadicLatticePainter extends CustomPainter {
  final double R;
  final double pulse;
  final String lastCollapse;
  final double currentDb;

  _TriadicLatticePainter(this.R, this.pulse, this.lastCollapse, this.currentDb);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..style = PaintingStyle.fill;

    // Background
    canvas.drawRect(Offset.zero & size, paint..color = const Color(0xFF000000));

    const int particles = 1200;
    final random = Random(42);

    for (int i = 0; i < particles; i++) {
      final angle = i * (pi * 2 / particles) + pulse * 2;
      final radius = 20 + 180 * (1 - R) + sin(angle * 3) * 30 * R;
      final x = center.dx + radius * cos(angle + pulse * 5);
      final y = center.dy + radius * sin(angle + pulse * 5);

      final brightness = (R + pulse * 0.5).clamp(0.3, 1.0);
      final hue = lastCollapse.contains('+') ? 60 : 160; // Gold for +|++>, Teal for -|--->
      paint.color = HSVColor.fromAHSV(brightness, hue.toDouble(), 1.0, 1.0).toColor();

      final particleSize = 2.0 + 8.0 * R + pulse * 15;
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint..maskFilter = MaskFilter.blur(BlurStyle.normal, particleSize * 0.6),
      );
    }

    // Collapse flash (outcome-specific)
    if (pulse > 0.01) {
      paint.color = Color.lerp(
        Colors.transparent,
        lastCollapse.contains('+') ? Colors.gold.withOpacity(0.9) : Colors.teal.withOpacity(0.9),
        pulse,
      )!;
      canvas.drawRect(Offset.zero & size, paint);
    }

    // Text overlay
    final textSpan = TextSpan(
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.cyan, blurRadius: 20 * R)],
      ),
      children: [
        TextSpan(text: "R = ${R.toStringAsPrecision(6)}\n"),
        TextSpan(text: "Voice: LIVE ${currentDb.toStringAsFixed(1)} dB\n"),
        if (lastCollapse.isNotEmpty)
          TextSpan(
            text: lastCollapse.split(' ').first,
            style: TextStyle(
              fontSize: 32,
              color: lastCollapse.contains('+') ? Colors.gold : Colors.teal,
            ),
          ),
      ],
    );

    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 40));
  }

  @override
  bool shouldRepaint(covariant _TriadicLatticePainter old) =>
      old.R != R || old.pulse != pulse || old.lastCollapse != lastCollapse || old.currentDb != currentDb;
}