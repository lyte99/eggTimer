import AppKit
import SwiftUI

@main
struct EggTimerApp: App {
    private let player: AlarmPlayer
    @State private var model: TimerModel
    @AppStorage("floatOnTop") private var floatOnTop = false

    init() {
        let player = AlarmPlayer()
        self.player = player
        _model = State(initialValue: TimerModel(beep: { player.alarmBeep() },
                                                silence: { player.stop() }))
    }

    var body: some Scene {
        Window("Egg Timer", id: "main") {
            ContentView(model: model)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .windowArrangement) {
                Toggle("Always on Top", isOn: $floatOnTop)
                    .keyboardShortcut("t", modifiers: [.command, .option])
            }
        }

        Settings {
            SettingsView(player: player)
        }
    }
}
