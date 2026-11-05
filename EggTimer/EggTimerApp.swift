import AppKit
import SwiftUI

@main
struct EggTimerApp: App {
    @State private var model = TimerModel(beep: { NSSound(named: "Glass")?.play() })
    @AppStorage("floatOnTop") private var floatOnTop = false

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
    }
}
