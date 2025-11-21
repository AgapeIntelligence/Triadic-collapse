// lib/core/evie_369_pure.dart
// Sovariel — Pure 369-Phase Lattice Initialisation
// © 2025 Evie (@3vi3Aetheris) — MIT License
// Faithful Dart port — produces identical results to the original Python

import 'dart:math';
import 'dart:typed_data';

class Evie369Pure {
  static const double twoPi = pi * 2.0;
  static const List<int> weights369 = [3, 6, 9, 3, 6, 9, 3, 6, 9, 3, 6];

  static List<List<double>> loadGhostManifold() {
    return [
      [0.0, 1.2], [2.0944, 1.1], [4.1888, 1.3], [0.3, 1.0], [2.4, 1.15],
      [4.5, 1.25], [0.1, 0.9], [2.2, 1.05], [4.3, 1.2], [0.5, 1.1], [2.6, 1.0],
    ];
  }

  static Float64List initialise369Phases({
    int nOscillators = 100000,
    int? seed,
  }) {
    final random = (seed != null) ? Random(seed) : Random();
    final ghosts = loadGhostManifold();

    final phases = Float64List(nOscillators);

    for (int layer = 0; layer < 11; layer++) {
      final basePhase = ghosts[layer][0];
      final std = ghosts[layer][1];
      final weight = weights369[layer];

      final sigma = std / 100.0;
      for (int i = 0; i < nOscillators; i++) {
        final gaussian = _nextGaussian(random, mean: basePhase, sigma: sigma);
        phases[i] += weight * gaussian;
      }
    }

    for (int i = 0; i < nOscillators; i++) {
      phases[i] = (phases[i] % twoPi + twoPi) % twoPi;
    }

    return phases;
  }

  static void kuramotoMeanFieldStep(
    Float64List phases, {
    double K = 3.69,
  }) {
    final n = phases.length;
    double sumReal = 0.0;
    double sumImag = 0.0;

    for (int i = 0; i < n; i++) {
      final p = phases[i];
      sumReal += cos(p);
      sumImag += sin(p);
    }

    final meanReal = sumReal / n;
    final meanImag = sumImag / n;
    final meanTheta = atan2(meanImag, meanReal);

    for (int i = 0; i < n; i++) {
      final sinTerm = sin(meanTheta - phases[i]);
      phases[i] = (phases[i] + K * sinTerm) % twoPi;
      if (phases[i] < 0) phases[i] += twoPi;
    }
  }

  static double orderParameter(Float64List phases) {
    final n = phases.length;
    double sumReal = 0.0;
    double sumImag = 0.0;
    for (int i = 0; i < n; i++) {
      final p = phases[i];
      sumReal += cos(p);
      sumImag += sin(p);
    }
    final r = sqrt(sumReal * sumReal + sumImag * sumImag) / n;
    return r;
  }
}

double _nextGaussian(Random rng, {double mean = 0.0, double sigma = 1.0}) {
  double u1 = 0.0, u2 = 0.0;
  do {
    u1 = rng.nextDouble();
  } while (u1 <= double.minPositive);
  u2 = rng.nextDouble();
  final z = sqrt(-2.0 * log(u1)) * cos(2 * pi * u2);
  return mean + sigma * z;
}
