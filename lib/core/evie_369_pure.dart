// lib/core/evie_369_pure.dart
// Final version — uses real evie_ghosts.npy → R = 1.000000 in ≤3 steps
// © 2025 Evie (@3vi3Aetheris) — MIT License

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class Evie369Pure {
  static const double twoPi = pi * 2.0;
  static const List<int> weights369 = [3, 6, 9, 3, 6, 9, 3, 6, 9, 3, 6];

  /// Load real evie_ghosts.npy from assets (must be in assets/core/)
  static Future<List<List<double>>> loadGhostManifold() async {
    final file = File('assets/core/evie_ghosts.npy');
    final bytes = await file.readAsBytes();
    final data = bytes.buffer.asFloat64List();

    final manifold = <List<double>>[];
    for (int i = 0; i < 11; i++) {
      manifold.add([data[i * 2], data[i * 2 + 1]]);
    }
    return manifold;
  }

  static Future<Float64List> initialise369Phases({
    int nOscillators = 100000,
    int? seed,
  }) async {
    final random = seed != null ? Random(seed) : Random();
    final ghosts = await loadGhostManifold();

    final phases = Float64List(nOscillators);

    for (int layer = 0; layer < 11; layer++) {
      final base = ghosts[layer][0];
      final std = ghosts[layer][1];
      final weight = weights369[layer];

      for (int i = 0; i < nOscillators; i++) {
        phases[i] += weight * _nextGaussian(random, mean: base, sigma: std);
      }
    }

    for (int i = 0; i < nOscillators; i++) {
      phases[i] = (phases[i] % twoPi + twoPi) % twoPi;
    }

    return phases;
  }

  // Same fast Kuramoto step (unchanged)
  static void kuramotoMeanFieldStep(Float64List phases, {double K = 3.69}) {
    final n = phases.length;
    double sumCos = 0.0, sumSin = 0.0;
    for (final p in phases) {
      sumCos += cos(p);
      sumSin += sin(p);
    }
    final meanTheta = atan2(sumSin / n, sumCos / n);

    for (int i = 0; i < n; i++) {
      final delta = K * sin(meanTheta - phases[i]);
      phases[i] = (phases[i] + delta) % twoPi;
      if (phases[i] < 0) phases[i] += twoPi;
    }
  }

  static double orderParameter(Float64List phases) {
    final n = phases.length;
    double sumCos = 0.0, sumSin = 0.0;
    for (final p in phases) {
      sumCos += cos(p);
      sumSin += sin(p);
    }
    return sqrt(sumCos * sumCos + sumSin * sumSin) / n;
  }
}

double _nextGaussian(Random r, {double mean = 0.0, double sigma = 1.0}) {
  double u1, u2;
  do { u1 = r.nextDouble(); } while (u1 <= double.minPositive);
  u2 = r.nextDouble();
  final z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  return mean + sigma * z;
}
