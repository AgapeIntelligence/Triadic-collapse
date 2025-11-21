# Triadic Collapse

Triadic Collapse — real-time quantum lattice game. Your voice drives 100k+ oscillators to perfect 3-6-9 synchrony → triggers live GHZ collapse. Pure math, zero fluff. Flutter · iOS/Android · 120 fps. Launch Dec 2025.

---

## Overview

Triadic Collapse is a Flutter app that visualizes a massive 3-6-9 oscillator lattice and the evolution of a triadic GHZ quantum state. Your voice directly influences the synchronization of the lattice. When coherence is high (R → 1.0), a live GHZ collapse is triggered.

- 100,000+ oscillators
- Real-time Kuramoto lattice simulation
- Voice-driven coherence modulation
- Live GHZ collapse visual & sound
- Flutter cross-platform (iOS & Android)
- Smooth 120 FPS visualizations

---

## Features

- **Evie369Pure lattice core:** Initializes and evolves 3-6-9 weighted oscillators.  
- **Triadic GHZ collapse engine:** Proxy simulation of triadic GHZ state triggered by lattice coherence and voice envelope.  
- **Live visualizer:** High-performance, glowing lattice view with collapse pulses.  
- **Voice integration:** Uses microphone input (`noise_meter`) to modulate lattice dynamics.  
- **Audio feedback:** Optional collapse sounds (`just_audio`) synced with GHZ collapse.

---

## Assets

- `assets/core/evie_ghosts.npy` — precomputed ghost manifold for lattice initialization  
- `assets/audio/` — collapse sounds and ambient audio

Ensure these are included in your `pubspec.yaml` under `assets:`.

---

## Installation

1. Clone the repo:
```bash
git clone https://github.com/AgapeIntelligence/Triadic-collapse.git

---

## Run Instructions

After cloning the repo:

```bash
flutter pub get
flutter run
cd Triadic-collapse
