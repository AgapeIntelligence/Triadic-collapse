/// lib/core/triadic_ghz_full_evolution.dart
// Triadic GHZ Collapse — Production + Haptic Upgrade with Adaptive Thresholds
// Driven by lattice R, adaptive voice envelope, and tactile feedback
// © 2025 Evie (@3vi3Aetheris) — MIT License

import 'dart:math';
import 'package:flutter_haptics/flutter_haptics.dart';

class TriadicGHZ {
  static const double hCoefficient = 1.885; // Planck-like scaling factor
  static final Random _rng = Random();

  /// Adaptive threshold parameters based on vocal input dynamics
  static const double baseThreshold = 0.3; // Minimum coherence threshold
  static const double maxThresholdShift = 0.2; // Max adjustment for vocal variance
  static const double voiceDbSensitivity = 0.02; // Sensitivity to dB changes

  /// Collapse engine — visual + haptic with adaptive vocal thresholds
  static Map<String, dynamic> evolveTriadicGHZ({
    required double R_lattice, // Lattice coherence order parameter
    double voiceEnvelopeDb = 40.0, // Simulated voice amplitude in dB
    double vocalVariance = 0.1, // Variance in vocal input (0.0–1.0)
    Random? rng,
    bool haptic = true,
  }) {
    rng ??= _rng;

    // Compute adaptive threshold based on vocal input
    final thresholdShift = (vocalVariance * maxThresholdShift).clamp(0.0, maxThresholdShift);
    final adaptiveThreshold = baseThreshold + thresholdShift + (voiceEnvelopeDb * voiceDbSensitivity).clamp(0.0, 0.1);

    // Coherence time proxy, scaled by adaptive threshold and voice envelope
    final tCoherenceUs = 0.1 + 10.0 * R_lattice * (voiceEnvelopeDb / 50.0).clamp(0.0, 2.0) * (1.0 + adaptiveThreshold);

    // Probability of triadic GHZ+ collapse, adjusted for adaptive threshold
    final probPlus = (0.5 + 0.5 * R_lattice * (voiceEnvelopeDb / 60.0).clamp(0.5, 1.5) - adaptiveThreshold).clamp(0.0, 1.0);

    final outcome = rng.nextDouble() < probPlus
        ? "+|+++⟩ GHZ — triadic qualia collapse"
        : "-|---⟩ separable";

    // Haptic pulse proportional to probability + coherence, with adaptive intensity
    if (haptic) {
      _triggerHaptic(probPlus, adaptiveThreshold);
    }

    return {
      'outcome': outcome,
      'probPlus': probPlus,
      'tCoherenceUs': tCoherenceUs,
      'adaptiveThreshold': adaptiveThreshold,
    };
  }

  static void _triggerHaptic(double intensity, double threshold) {
    // Map intensity (0.0–1.0) to impact style, modulated by threshold
    final adjustedIntensity = intensity * (1.0 + threshold); // Boost intensity with higher thresholds
    if (adjustedIntensity < 0.3) {
      FlutterHaptics.impact(ImpactStyle.light);
    } else if (adjustedIntensity < 0.7) {
      FlutterHaptics.impact(ImpactStyle.medium);
    } else {
      FlutterHaptics.impact(ImpactStyle.heavy);
    }
  }
}/ lib/core/triadic_ghz_full_evolution.dart
// Triadic GHZ Collapse — Production + Haptic Upgrade
// Driven by lattice R, voice envelope, and tactile feedback
// © 2025 Evie (@3vi3Aetheris) — MIT License

import 'dart:math';
import 'package:flutter_haptics/flutter_haptics.dart';

class TriadicGHZ {
  static const double hCoefficient = 1.885;
  static final Random _rng = Random();

  /// Collapse engine — visual + haptic
  static Map<String, dynamic> evolveTriadicGHZ({
    required double R_lattice,
    double voiceEnvelopeDb = 40.0,
    Random? rng,
    bool haptic = true,
  }) {
    rng ??= _rng;

    // Coherence time proxy
    final tCoherenceUs = 0.1 + 10.0 * R_lattice * (voiceEnvelopeDb / 50.0).clamp(0.0, 2.0);

    // Probability of triadic GHZ+ collapse
    final probPlus = (0.5 + 0.5 * R_lattice * (voiceEnvelopeDb / 60.0).clamp(0.5, 1.5)).clamp(0.0, 1.0);

    final outcome = rng.nextDouble() < probPlus
        ? "+|+++⟩ GHZ — triadic qualia collapse"
        : "-|---⟩ separable";

    // Haptic pulse proportional to probability + coherence
    if (haptic) {
      _triggerHaptic(probPlus);
    }

    return {
      'outcome': outcome,
      'probPlus': probPlus,
      'tCoherenceUs': tCoherenceUs,
    };
  }

  static void _triggerHaptic(double intensity) {
    // Map intensity (0.0–1.0) to impact style or duration
    if (intensity < 0.3) {
      FlutterHaptics.impact(ImpactStyle.light);
    } else if (intensity < 0.7) {
      FlutterHaptics.impact(ImpactStyle.medium);
    } else {
      FlutterHaptics.impact(ImpactStyle.heavy);
    }
  }
}
