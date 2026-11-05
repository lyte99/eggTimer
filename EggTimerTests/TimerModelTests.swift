import Foundation
import Testing
@testable import EggTimer

@MainActor
final class FakeClock {
    var date = Date(timeIntervalSinceReferenceDate: 1_000_000)
    func advance(_ seconds: TimeInterval) { date = date.addingTimeInterval(seconds) }
}

@MainActor
struct TimerModelTests {
    let clock = FakeClock()

    func makeModel(beepCounter: @escaping () -> Void = {}) -> TimerModel {
        TimerModel(now: { [clock] in clock.date }, beep: beepCounter, autoTick: false)
    }

    @Test func incrementsAndWraps() {
        let timer = makeModel()
        for _ in 0..<61 { timer.pressSecond() }
        #expect(timer.secondsPart == 1)   // 59 -> 0 wraps without carrying
        #expect(timer.minutesPart == 0)
        for _ in 0..<100 { timer.pressMinute() }
        #expect(timer.minutesPart == 0)   // 99 -> 0 wraps
    }

    @Test func countsDownToAlarmAndRecalls() {
        var beeps = 0
        let timer = makeModel { beeps += 1 }
        timer.pressSecond(); timer.pressSecond(); timer.pressSecond()
        timer.pressStartStop()
        #expect(timer.phase == .countingDown)

        clock.advance(0.5); timer.tick()
        #expect(timer.seconds == 3)
        clock.advance(1.0); timer.tick()
        #expect(timer.seconds == 2)
        clock.advance(1.5); timer.tick()
        #expect(timer.phase == .alarming)
        #expect(timer.seconds == 0)
        #expect(beeps == 1)

        clock.advance(1.0); timer.tick()
        #expect(beeps == 2)

        timer.pressMinute()   // silences only, does not add a minute
        #expect(timer.phase == .stopped)
        #expect(timer.seconds == 3)
    }

    @Test func countsUpFromZeroAndResumes() {
        let timer = makeModel()
        timer.pressStartStop()
        #expect(timer.phase == .countingUp)
        clock.advance(5.2); timer.tick()
        #expect(timer.seconds == 5)

        timer.pressStartStop()
        #expect(timer.phase == .stopped)
        clock.advance(100)
        timer.pressStartStop()
        #expect(timer.phase == .countingUp)   // resumes upward, not a countdown
        clock.advance(2); timer.tick()
        #expect(timer.seconds == 7)
    }

    @Test func pausesAndResumesCountdown() {
        let timer = makeModel()
        timer.pressMinute()
        timer.pressStartStop()
        clock.advance(10); timer.tick()
        timer.pressStartStop()
        #expect(timer.seconds == 50)
        clock.advance(30)
        timer.pressStartStop()
        clock.advance(5); timer.tick()
        #expect(timer.seconds == 45)
    }

    @Test func buttonsIgnoredWhileRunning() {
        let timer = makeModel()
        timer.pressMinute()
        timer.pressStartStop()
        timer.pressSecond(); timer.pressMinute(); timer.pressClear()
        timer.tick()
        #expect(timer.seconds == 60)
        #expect(timer.phase == .countingDown)
    }

    @Test func clearResets() {
        let timer = makeModel()
        timer.pressMinute(); timer.pressSecond()
        timer.pressClear()
        #expect(timer.seconds == 0)
    }

    @Test func countUpStopsAtMax() {
        let timer = makeModel()
        timer.pressStartStop()
        clock.advance(10_000); timer.tick()
        #expect(timer.seconds == TimerModel.maxSeconds)
        #expect(timer.phase == .stopped)
    }
}

@MainActor
struct AlarmToneTests {
    @Test func silencingStopsTheSound() {
        let clock = FakeClock()
        var silenced = 0
        let timer = TimerModel(now: { clock.date }, silence: { silenced += 1 }, autoTick: false)
        timer.pressSecond()
        timer.pressStartStop()
        clock.advance(2); timer.tick()
        #expect(timer.phase == .alarming)
        timer.pressStartStop()
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
