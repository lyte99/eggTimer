import SwiftUI

struct ContentView: View {
    let model: TimerModel
    @AppStorage("floatOnTop") private var floatOnTop = false

    var body: some View {
        VStack(spacing: 16) {
            display
                .overlay(alignment: .topTrailing) {
                    Toggle(isOn: $floatOnTop) {
                        Image(systemName: floatOnTop ? "pin.fill" : "pin")
                            .foregroundStyle(floatOnTop ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.borderless)
                    .help(floatOnTop ? "Always on top: on (⌥⌘T)" : "Always on top: off (⌥⌘T)")
                    .accessibilityLabel("Always on Top")
                    .padding(8)
                }
            HStack(spacing: 10) {
                Button("M", action: model.pressMinute)
                    .keyboardShortcut("m", modifiers: [])
                    .buttonRepeatBehavior(.enabled)
                    .disabled(model.isRunning)
                    .help("Add a minute (M)")
                Button("S", action: model.pressSecond)
                    .keyboardShortcut("s", modifiers: [])
                    .buttonRepeatBehavior(.enabled)
                    .disabled(model.isRunning)
                    .help("Add a second (S)")
                Button("Clear", action: model.pressClear)
                    .keyboardShortcut(.escape, modifiers: [])
                    .disabled(model.isRunning)
                    .help("Reset to 00:00 (Esc)")
                Spacer(minLength: 12)
                Button(model.isRunning ? "Stop" : "Start", action: model.pressStartStop)
                    .keyboardShortcut(.space, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .help("Start / stop (Space)")
            }
            .controlSize(.large)
        }
        .padding(20)
        .frame(width: 320)
        .background(WindowLevelSetter(floating: floatOnTop))
    }

    private var display: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(String(format: "%02d", model.minutesPart))
            Text(":").foregroundStyle(.secondary)
            Text(String(format: "%02d", model.secondsPart))
        }
        .font(.system(size: 72, weight: .medium, design: .rounded).monospacedDigit())
        .opacity(model.phase == .alarming && !model.flashOn ? 0.15 : 1)
        .foregroundStyle(model.phase == .alarming ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(model.minutesPart) minutes \(model.secondsPart) seconds")
    }
}
