import Foundation
import Observation

/// All timer logic. Time comes from an injectable clock so it can be tested
/// without waiting; the UI drives `tick()` from a short repeating Timer.
@MainActor
@Observable
final class TimerModel {
    enum Phase: Equatable { case stopped, countingDown, countingUp, alarming }

    static let maxSeconds = 99 * 60 + 59

    /// What the display shows, in whole seconds.
    private(set) var seconds = 0
    private(set) var phase: Phase = .stopped
    /// Toggles while alarming so the display can flash.
    private(set) var flashOn = false

    var isRunning: Bool { phase == .countingDown || phase == .countingUp }
    var minutesPart: Int { seconds / 60 }
    var secondsPart: Int { seconds % 60 }

    /// The last time entered with M/S; restored after the alarm is silenced.
    private var setSeconds = 0
    /// Set when paused mid-stopwatch so Start resumes counting up.
    private var resumeCountingUp = false
    /// Countdown: the moment it reaches zero. Count-up: the moment it was at 0.
    private var anchor = Date()
    private var nextBeep = Date()
    private var refreshTimer: Timer?

    private let now: () -> Date
    private let beep: () -> Void
    private let autoTick: Bool

    init(now: @escaping () -> Date = Date.init,
         beep: @escaping () -> Void = {},
         autoTick: Bool = true) {
        self.now = now
        self.beep = beep
        self.autoTick = autoTick
    }

    // MARK: Buttons

    func pressMinute() {
        if silenceIfAlarming() || isRunning { return }
        setValue(minutes: (minutesPart + 1) % 100, seconds: secondsPart)
    }

    func pressSecond() {
        if silenceIfAlarming() || isRunning { return }
        setValue(minutes: minutesPart, seconds: (secondsPart + 1) % 60)
    }

    func pressClear() {
        if silenceIfAlarming() || isRunning { return }
        setValue(minutes: 0, seconds: 0)
    }

    func pressStartStop() {
        if silenceIfAlarming() { return }
        switch phase {
        case .countingDown, .countingUp:
            tick()
            if phase == .countingUp { resumeCountingUp = true }
            phase = .stopped
            stopRefresh()
        case .stopped:
            if seconds == 0 || resumeCountingUp {
                anchor = now().addingTimeInterval(-Double(seconds))
                phase = .countingUp
            } else {
                anchor = now().addingTimeInterval(Double(seconds))
                phase = .countingDown
            }
            resumeCountingUp = false
            startRefresh()
        case .alarming:
            break
        }
    }

    // MARK: Clock

    func tick() {
        let t = now()
        switch phase {
        case .countingDown:
            let remaining = anchor.timeIntervalSince(t)
            if remaining <= 0 {
                seconds = 0
                phase = .alarming
                flashOn = true
                beep()
                nextBeep = t.addingTimeInterval(1)
            } else {
                seconds = Int(remaining.rounded(.up))
            }
        case .countingUp:
            let elapsed = Int(t.timeIntervalSince(anchor).rounded(.down))
            if elapsed >= Self.maxSeconds {
                seconds = Self.maxSeconds
                phase = .stopped
                stopRefresh()
            } else {
                seconds = max(0, elapsed)
            }
        case .alarming:
            if t >= nextBeep {
                beep()
                nextBeep = nextBeep.addingTimeInterval(1)
            }
            flashOn = Int(t.timeIntervalSinceReferenceDate * 2) % 2 == 0
        case .stopped:
            break
        }
    }

    // MARK: Private

    private func setValue(minutes: Int, seconds secs: Int) {
        seconds = minutes * 60 + secs
        setSeconds = seconds
        resumeCountingUp = false
    }

    /// Any button press during the alarm only silences it and recalls the set time.
    private func silenceIfAlarming() -> Bool {
        guard phase == .alarming else { return false }
        phase = .stopped
        flashOn = false
        seconds = setSeconds
        stopRefresh()
        return true
    }

    private func startRefresh() {
        guard autoTick else { return }
        stopRefresh()
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    private func stopRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
