import Foundation
import Testing
@testable import EggTimer

@MainActor
final class FakeClock {
    var date = Date(timeIntervalSinceReferenceDate: 1_000_000)
    func advance(_ s: TimeInterval) { date = date.addingTimeInterval(s) }
}

@MainActor
struct TimerModelTests {
    let clock = FakeClock()

    func makeModel(beepCounter: @escaping () -> Void = {}) -> TimerModel {
        TimerModel(now: { [clock] in clock.date }, beep: beepCounter, autoTick: false)
    }

    @Test func incrementsAndWraps() {
        let m = makeModel()
        for _ in 0..<61 { m.pressSecond() }
        #expect(m.secondsPart == 1)   // 59 -> 0 wraps without carrying
        #expect(m.minutesPart == 0)
        for _ in 0..<100 { m.pressMinute() }
        #expect(m.minutesPart == 0)   // 99 -> 0 wraps
    }

    @Test func countsDownToAlarmAndRecalls() {
        var beeps = 0
        let m = makeModel { beeps += 1 }
        m.pressSecond(); m.pressSecond(); m.pressSecond()
        m.pressStartStop()
        #expect(m.phase == .countingDown)

        clock.advance(0.5); m.tick()
        #expect(m.seconds == 3)
        clock.advance(1.0); m.tick()
        #expect(m.seconds == 2)
        clock.advance(1.5); m.tick()
        #expect(m.phase == .alarming)
        #expect(m.seconds == 0)
        #expect(beeps == 1)

        clock.advance(1.0); m.tick()
        #expect(beeps == 2)

        m.pressMinute()   // silences only, does not add a minute
        #expect(m.phase == .stopped)
        #expect(m.seconds == 3)
    }

    @Test func countsUpFromZeroAndResumes() {
        let m = makeModel()
        m.pressStartStop()
        #expect(m.phase == .countingUp)
        clock.advance(5.2); m.tick()
        #expect(m.seconds == 5)

        m.pressStartStop()
        #expect(m.phase == .stopped)
        clock.advance(100)
        m.pressStartStop()
        #expect(m.phase == .countingUp)   // resumes upward, not a countdown
        clock.advance(2); m.tick()
        #expect(m.seconds == 7)
    }

    @Test func pausesAndResumesCountdown() {
        let m = makeModel()
        m.pressMinute()
        m.pressStartStop()
        clock.advance(10); m.tick()
        m.pressStartStop()
        #expect(m.seconds == 50)
        clock.advance(30)
        m.pressStartStop()
        clock.advance(5); m.tick()
        #expect(m.seconds == 45)
    }

    @Test func buttonsIgnoredWhileRunning() {
        let m = makeModel()
        m.pressMinute()
        m.pressStartStop()
        m.pressSecond(); m.pressMinute(); m.pressClear()
        m.tick()
        #expect(m.seconds == 60)
        #expect(m.phase == .countingDown)
    }

    @Test func clearResets() {
        let m = makeModel()
        m.pressMinute(); m.pressSecond()
        m.pressClear()
        #expect(m.seconds == 0)
    }

    @Test func countUpStopsAtMax() {
        let m = makeModel()
        m.pressStartStop()
        clock.advance(10_000); m.tick()
        #expect(m.seconds == TimerModel.maxSeconds)
        #expect(m.phase == .stopped)
    }
}

@MainActor
struct AlarmToneTests {
    @Test func silencingStopsTheSound() {
        let clock = FakeClock()
        var silenced = 0
        let m = TimerModel(now: { clock.date }, silence: { silenced += 1 }, autoTick: false)
        m.pressSecond()
        m.pressStartStop()
        clock.advance(2); m.tick()
        #expect(m.phase == .alarming)
        m.pressStartStop()
        #expect(silenced == 1)
    }

    @Test func everyToneLoads() {
        let player = AlarmPlayer()
        let tones = AlarmPlayer.generatedTones + AlarmPlayer.systemTones
        #expect(tones.count > AlarmPlayer.generatedTones.count)
        for tone in tones {
            #expect(player.sound(for: tone.id) != nil, "\(tone.name) failed to load")
        }
        #expect(AlarmPlayer.systemTones.contains { $0.id == AlarmPlayer.defaultTone })
    }

    @Test func generatedTonesFitInOneBeepInterval() throws {
        let player = AlarmPlayer()
        for tone in AlarmPlayer.generatedTones {
            let duration = try #require(player.sound(for: tone.id)).duration
            #expect(duration > 0.2 && duration < 1.0, "\(tone.name) is \(duration)s")
        }
    }
}
