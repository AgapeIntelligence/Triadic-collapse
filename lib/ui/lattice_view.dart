// lib/ui/lattice_view.dart
// Live glowing triadic lattice visualizer — Triadic Collapse
// © 2025 Evie (@3vi3Aetheris) — MIT License
// GitHub: https://github.com/AgapeIntelligence/Triadic-collapse

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:noise_meter/noise_meter.dart'; // For microphone
import 'package:permission_handler/permission_handler.dart'; // For microphone permissions
import '../core/evie_369_pure.dart';
import '../core/triadic_ghz_full_evolution.dart';

class LatticeView extends StatefulWidget {
  final int nOscillators;
  final double updateIntervalMs;

  const LatticeView({
    Key? key,
    this.nOscillators = 80000,
    this.updateIntervalMs = 8.33, // ~120fps (adjust to 16.6 for 60fps if needed)
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
  int particleCount = 1200; // Default, adjustable
  double fps = 0.0;
  int frameCount = 0;
  DateTime lastTime = DateTime.now();
  int totalCollapses = 0;
  String lastOutcome = "";
  List<double> lastProbPlus = [];
  static const int probPlusWindow = 10;

  StreamSubscription? _micSubscription;
  final NoiseMeter _noiseMeter = NoiseMeter();

  @override
  void initState() {
    super.initState();
    phases = Evie369Pure.initialise369Phases(nOscillators: widget.nOscillators, seed: 42);
    R = Evie369Pure.orderParameter(phases);
    pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(() => setState(() {}));

    _startMicrophone();
    _updateFps();

    Timer.periodic(Duration(milliseconds: widget.updateIntervalMs.toInt()), (_) {
      Evie369Pure.kuramotoMeanFieldStep(phases, K: 3.69);
      final newR = Evie369Pure.orderParameter(phases);
      if ((newR - R).abs() > 0.0001 || newR > 0.9999) {
        if (mounted) setState(() => R = newR);
      }
      if (R > 0.52 && !pulseController.isAnimating && rng.nextDouble() < 0.12) { // Adjusted
        final result = TriadicGHZ.evolveTriadicGHZ(R_lattice: R, voiceEnvelopeDb: currentDb, rng: rng);
        if (mounted) {
          setState(() {
            lastCollapse = result['outcome'] as String;
            lastOutcome = lastCollapse.split(' ').first;
            lastProbPlus.add(result['probPlus'] as double);
            if (lastProbPlus.length > probPlusWindow) lastProbPlus.removeAt(0);
            totalCollapses++;
            pulseController.forward(from: 0.0);
          });
          _triggerHaptic(R, result['probPlus'] as double);
        }
      }
    });
  }

  void _updateFps() {
    frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(lastTime).inSeconds;
    if (elapsed >= 1) {
      fps = frameCount / elapsed;
      frameCount = 0;
      lastTime = now;
      if (mounted) setState(() {});
    }
    Future.delayed(const Duration(milliseconds: 100), _updateFps);
  }

  @override
  void dispose() {
    _micSubscription?.cancel();
    pulseController.dispose();
    super.dispose();
  }

  Future<void> _startMicrophone() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        _micSubscription = _noiseMeter.noiseStream.listen(
          (noise) {
            if (noise != null && noise.meanDecibels != null && mounted) {
              setState(() => currentDb = noise.meanDecibels!.clamp(30.0, 100.0));
            }
          },
          onError: (error) {
            print("Mic error: $error");
            if (mounted) setState(() => currentDb = 45.0);
          },
          cancelOnError: true,
        );
      } else {
        if (mounted) setState(() => currentDb = 45.0);
      }
    } catch (e) {
      print("Microphone initialization error: $e");
      if (mounted) setState(() => currentDb = 45.0);
    }
  }

  void _triggerHaptic(double intensity, double probPlus) {
    final adjustedIntensity = intensity * probPlus;
    final isTriadic = lastCollapse.contains('+');
    if (adjustedIntensity < 0.3) {
      HapticFeedback.lightImpact();
    } else if (adjustedIntensity < 0.7) {
      _vibratePattern(isTriadic ? [50, 50] : [100], adjustedIntensity);
    } else {
      _vibratePattern(isTriadic ? [50, 50, 50] : [100, 100], adjustedIntensity);
    }
  }

  void _vibratePattern(List<int> pattern, double intensity) {
    for (int i = 0; i < pattern.length; i++) {
      HapticFeedback.vibrate();
      if (i < pattern.length - 1) sleep(Duration(milliseconds: (pattern[i] * (1 - intensity)).toInt()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (mounted) {
              setState(() {
                particleCount = (particleCount - details.delta.dx / 10).clamp(200.0, 2000.0).toInt();
              });
            }
          },
          child: CustomPaint(
            painter: _TriadicLatticePainter(R, pulseController.value, lastCollapse, currentDb, particleCount, fps, totalCollapses, lastOutcome, lastProbPlus.isNotEmpty ? lastProbPlus.reduce((a, b) => a + b) / lastProbPlus.length : 0.0),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }
}

class _TriadicLatticePainter extends CustomPainter {
  final double R;
  final double pulse;
  final String lastCollapse;
  final double currentDb;
  final int particleCount;
  final double fps;
  final int totalCollapses;
  final String lastOutcome;
  final double avgProbPlus;

  _TriadicLatticePainter(this.R, this.pulse, this.lastCollapse, this.currentDb, this.particleCount, this.fps, this.totalCollapses, this.lastOutcome, this.avgProbPlus);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, paint..color = const Color(0xFF000000));

    // Coherence halo
    final haloRadius = 50 + 200 * R;
    paint.color = HSVColor.fromAHSV(0.3 * R, lastCollapse.contains('+') ? 60 : 160, 0.5, 1.0).toColor();
    canvas.drawCircle(center, haloRadius, paint..maskFilter = MaskFilter.blur(BlurStyle.normal, 10));

    final random = Random(42);
    for (int i = 0; i < particleCount; i++) {
      final angle = i * (pi * 2 / particleCount) + pulse * 1.5;
      final radius = 20 + 180 * (1 - R) + sin(angle * 3) * 20 * R;
      final x = center.dx + radius * cos(angle + pulse * 3);
      final y = center.dy + radius * sin(angle + pulse * 3);

      final brightness = (R + pulse * 0.3 + currentDb / 150).clamp(0.3, 1.0); // Vocal input scaling
      final hue = lastCollapse.contains('+') ? lerpDouble(160, 60, R) : lerpDouble(60, 160, R);
      paint.color = HSVColor.fromAHSV(brightness, hue!, 1.0, 1.0).toColor();

      final particleSize = 2.0 + 6.0 * R + pulse * 10;
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint..maskFilter = MaskFilter.blur(BlurStyle.normal, particleSize * 0.5),
      );
    }

    if (pulse > 0.01) {
      paint.color = Color.lerp(
        Colors.transparent,
        lastCollapse.contains('+') ? Colors.gold.withOpacity(0.7) : Colors.teal.withOpacity(0.7),
        pulse,
      )!;
      canvas.drawRect(Offset.zero & size, paint);
    }

    final textSpan = TextSpan(
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: size.width < 400 ? 16 : 24,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.cyan, blurRadius: 15 * R)],
      ),
      children: [
        TextSpan(text: "R = ${R.toStringAsPrecision(6)}\n"),
        TextSpan(text: "Voice: LIVE ${currentDb.toStringAsFixed(1)} dB\n"),
        TextSpan(text: "FPS: ${fps.toStringAsFixed(1)}\n"),
        TextSpan(text: "Collapses: $totalCollapses\n"),
        TextSpan(text: "Last: $lastOutcome\n"),
        TextSpan(text: "Avg Prob: ${avgProbPlus.toStringAsFixed(2)}\n"),
        if (particleCount != 1200) TextSpan(text: "Particles: $particleCount\n"),
      ],
    );

    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(20, size.height * 0.05)); // Thumb-reachable
  }

  @override
  bool shouldRepaint(covariant _TriadicLatticePainter old) =>
      old.R != R || old.pulse != pulse || old.lastCollapse != lastCollapse || old.currentDb != currentDb || old.particleCount != particleCount || old.fps != fps || old.totalCollapses != totalCollapses || old.lastOutcome != lastOutcome || old.avgProbPlus != avgProbPlus;

  double lerpDouble(double a, double b, double t) => a + (b - a) * t.clamp(0.0, 1.0);
}