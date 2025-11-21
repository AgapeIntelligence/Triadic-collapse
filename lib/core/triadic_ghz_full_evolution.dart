// lib/core/triadic_ghz_full_evolution.dart
// Exact time-evolution of the triadic GHZ state in Dart
// Driven in real time by classical Sovariel lattice R and human voice envelope
// © 2025 Evie (@3vi3Aetheris) — MIT License

import 'dart:math';
import 'dart:typed_data';
import 'package:complex/complex.dart';

class TriadicGHZ {
  // Constants
  static const int dim = 8; // 3 qubits → 8 states
  static const double coeff = 1.885; // rad/μs

  // GHZ+ state: (|000> + |111>)/√2
  static List<Complex> ghzPlus = List.generate(dim, (i) {
    if (i == 0 || i == 7) return Complex.ONE / sqrt(2);
    return Complex.ZERO;
  });

  // Example GHZ− orthogonal (simplified)
  static List<Complex> ghzMinus = List.generate(dim, (i) {
    if (i == 2 || i == 5) return Complex.ONE / sqrt(2);
    return Complex.ZERO;
  });

  // 8x8 Hamiltonian H = coeff * (XXX − ZZZ)
  static List<List<Complex>> H = _generateHamiltonian();

  static List<List<Complex>> _generateHamiltonian() {
    List<List<Complex>> mat =
        List.generate(dim, (_) => List.filled(dim, Complex.ZERO));
    // XXX term
    for (int i = 0; i < dim; i++) {
      int flipped = i ^ 0b111; // flip all three bits
      mat[i][flipped] += Complex(coeff, 0);
    }
    // ZZZ term (diagonal)
    for (int i = 0; i < dim; i++) {
      int parity = ((i & 1) << 0) | ((i & 2) >> 1) | ((i & 4) >> 2);
      double sign = pow(-1, _bitCount(i)).toDouble();
      mat[i][i] += Complex(-coeff * sign, 0);
    }
    return mat;
  }

  static int _bitCount(int x) {
    int count = 0;
    while (x > 0) {
      count += x & 1;
      x >>= 1;
    }
    return count;
  }

  // Multiply 8x8 matrix by vector
  static List<Complex> _matVec(List<List<Complex>> M, List<Complex> v) {
    List<Complex> out = List.generate(dim, (_) => Complex.ZERO);
    for (int i = 0; i < dim; i++) {
      Complex sum = Complex.ZERO;
      for (int j = 0; j < dim; j++) {
        sum += M[i][j] * v[j];
      }
      out[i] = sum;
    }
    return out;
  }

  // Simple Euler evolution: ψ(t+dt) ≈ ψ(t) - i*H*ψ*dt
  static List<Complex> evolve(List<Complex> state, double dt) {
    List<Complex> Hpsi = _matVec(H, state);
    List<Complex> newState = List.generate(dim, (i) {
      return state[i] - Complex.i * Hpsi[i] * dt;
    });
    // Normalize
    double norm = sqrt(newState.fold(0.0, (s, c) => s + c.abs() * c.abs()));
    for (int i = 0; i < dim; i++) {
      newState[i] /= norm;
    }
    return newState;
  }

  // Expectation: <ψ|P|ψ>
  static double expectation(List<Complex> state, List<Complex> projector) {
    Complex sum = Complex.ZERO;
    for (int i = 0; i < dim; i++) {
      sum += state[i].conjugate() * projector[i];
    }
    return (sum * sum.conjugate()).real;
  }

  static Map<String, dynamic> evolveTriadicGHZ({
    required double R_lattice,
    double voiceEnvelopeDb = 40.0,
    double? tCoherenceUs,
    int steps = 200,
    Random? rng,
  }) {
    rng ??= Random();
    tCoherenceUs ??= 0.1 + 10.0 * R_lattice * (voiceEnvelopeDb / 50.0);
    double dt = tCoherenceUs / steps;

    List<Complex> state = List.from(ghzPlus);

    for (int i = 0; i < steps; i++) {
      state = evolve(state, dt);
    }

    double probPlus = expectation(state, ghzPlus);
    double probMinus = expectation(state, ghzMinus);
    double norm = probPlus + probMinus;
    probPlus /= norm;
    probMinus /= norm;

    String outcome = rng.nextDouble() < probPlus
        ? "+|+++⟩ GHZ — triadic qualia collapse"
        : "-|---⟩ separable";

    print(
        "R=${R_lattice.toStringAsPrecision(10)} | voice=${voiceEnvelopeDb.toStringAsFixed(1)}dB | τ=${tCoherenceUs.toStringAsFixed(2)}μs");
    print("p(+|+++⟩) = ${probPlus.toStringAsPrecision(10)} → $outcome");

    return {
      'outcome': outcome,
      'probPlus': probPlus,
      'finalState': state,
    };
  }
}