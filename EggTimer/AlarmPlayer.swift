import AppKit

/// Plays the alarm tone chosen in Settings. Tones are either generated in code
/// (like the real timer's beep) or the built-in macOS alert sounds.
@MainActor
final class AlarmPlayer {
    static let defaultsKey = "alarmTone"
    static let defaultTone = "Glass"

    struct Tone: Identifiable, Hashable {
        let id: String
        let name: String
    }

    /// Tones synthesized in code, listed first in Settings.
    static let generatedTones = [
        Tone(id: "gen.classic", name: "Classic Beep"),
        Tone(id: "gen.chirp", name: "Digital Chirp"),
        Tone(id: "gen.alarm", name: "Alarm Clock"),
    ]

    /// Built-in macOS alert sounds (Glass, Ping, Submarine, …).
    static let systemTones: [Tone] = {
        let dir = URL(fileURLWithPath: "/System/Library/Sounds")
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        return files
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
            .map { Tone(id: $0, name: $0) }
    }()

    private var cache: [String: NSSound] = [:]
    private var current: NSSound?

    var selectedTone: String {
        UserDefaults.standard.string(forKey: Self.defaultsKey) ?? Self.defaultTone
    }

    /// Called once a second while alarming; doesn't cut off a tone still playing.
    func alarmBeep() {
        if current?.isPlaying == true { return }
        play(selectedTone)
    }

    /// Plays a tone from the start, e.g. when picked in Settings.
    func preview(_ id: String) {
        stop()
        play(id)
    }

    func stop() {
        current?.stop()
        current = nil
    }

    func sound(for id: String) -> NSSound? {
        if let cached = cache[id] { return cached }
        let made: NSSound?
        switch id {
        case "gen.classic": made = NSSound(data: Self.wav(Self.classicPattern))
        case "gen.chirp": made = NSSound(data: Self.wav(Self.chirpPattern))
        case "gen.alarm": made = NSSound(data: Self.wav(Self.alarmPattern))
        default: made = NSSound(named: NSSound.Name(id))
        }
        cache[id] = made
        return made
    }

    private func play(_ id: String) {
        guard let sound = sound(for: id) ?? sound(for: Self.defaultTone) else { return }
        current = sound
        sound.play()
    }

    // MARK: Synthesis

    /// A note: frequency in Hz (0 = silence) and duration in seconds.
    typealias Note = (hz: Double, seconds: Double)

    /// Four quick high beeps, like the physical kitchen timer.
    static let classicPattern: [Note] = Array(repeating: [(2600, 0.08), (0, 0.07)], count: 4).flatMap { $0 }
    /// Two rising chirps.
    static let chirpPattern: [Note] = [(1800, 0.06), (2400, 0.06), (0, 0.12), (1800, 0.06), (2400, 0.06)]
    /// Fast alternating two-tone ring.
    static let alarmPattern: [Note] = Array(repeating: [(1000, 0.05), (1400, 0.05)], count: 6).flatMap { $0 }

    /// Renders notes to 16-bit mono PCM WAV data.
    static func wav(_ notes: [Note], sampleRate: Int = 44_100, volume: Double = 0.45) -> Data {
        var samples: [Int16] = []
        let fade = Int(Double(sampleRate) * 0.004)   // 4 ms ramps avoid clicks
        for note in notes {
            let count = Int(Double(sampleRate) * note.seconds)
            for i in 0..<count {
                guard note.hz > 0 else { samples.append(0); continue }
                let ramp = min(1, Double(min(i, count - 1 - i)) / Double(max(fade, 1)))
                let value = sin(2 * .pi * note.hz * Double(i) / Double(sampleRate)) * volume * ramp
                samples.append(Int16(value * Double(Int16.max)))
            }
        }

        var data = Data()
        func append<T: FixedWidthInteger>(_ v: T) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        let byteCount = samples.count * 2
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36 + byteCount))
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16))
        append(UInt16(1)); append(UInt16(1))                         // PCM, mono
        append(UInt32(sampleRate)); append(UInt32(sampleRate * 2))   // byte rate
        append(UInt16(2)); append(UInt16(16))                        // block align, bits
        data.append(contentsOf: Array("data".utf8)); append(UInt32(byteCount))
        samples.forEach { append($0) }
        return data
    }
}
