import { vibrator } from '@kit.SensorServiceKit'

// Sound & Haptic manager for wearable
// Audio on wearable is primarily haptic; we use vibration patterns to simulate sounds.
export class SoundHapticManager {
  private static soundEnabled: boolean = true
  private static hapticEnabled: boolean = true

  static configure(sound: boolean, haptic: boolean): void {
    SoundHapticManager.soundEnabled = sound
    SoundHapticManager.hapticEnabled = haptic
  }

  // --- Core vibration ---
  private static vibrate(duration: number, intensity: number = 50): void {
    if (!SoundHapticManager.hapticEnabled) {
      return
    }
    try {
      vibrator.startVibration(
        { type: 'time', duration },
        { id: 0, usage: 'physicalFeedback' }
      )
    } catch (_e) {
      // Vibrator not available on this device — silently ignore
    }
  }

  private static vibratePattern(durations: number[], gaps: number[]): void {
    if (!SoundHapticManager.hapticEnabled) {
      return
    }
    let t: number = 0
    for (let i = 0; i < durations.length; i++) {
      const d: number = durations[i]
      const g: number = gaps[i] ?? 80
      setTimeout(() => {
        SoundHapticManager.vibrate(d)
      }, t)
      t += d + g
    }
  }

  // --- Game events ---

  // Dice roll: 3 rapid pulses of increasing length → feels like dice tumbling
  static playDiceRoll(): void {
    SoundHapticManager.vibratePattern([20, 30, 50], [60, 60, 0])
  }

  // Checker place: single short tap
  static playCheckerPlace(): void {
    SoundHapticManager.vibrate(25)
  }

  // Blot hit: strong double pulse → dramatic
  static playBlotHit(): void {
    SoundHapticManager.vibratePattern([60, 80], [80, 0])
  }

  // Bear off: soft ascending pulse
  static playBearOff(): void {
    SoundHapticManager.vibratePattern([15, 25, 40], [50, 50, 0])
  }

  // Win: victory pattern — three rising pulses
  static playWin(): void {
    SoundHapticManager.vibratePattern([40, 60, 100], [100, 100, 0])
  }

  // Auto-pass notification: two short taps
  static playAutoPass(): void {
    SoundHapticManager.vibratePattern([20, 20], [120, 0])
  }

  // Crown navigation: minimal tick
  static playCrownTick(): void {
    SoundHapticManager.vibrate(10)
  }

  // Doubling cube offer
  static playDoublingOffer(): void {
    SoundHapticManager.vibratePattern([30, 30, 30], [80, 80, 0])
  }

  // Tie (first roll): two equal pulses
  static playTie(): void {
    SoundHapticManager.vibratePattern([40, 40], [150, 0])
  }
}
