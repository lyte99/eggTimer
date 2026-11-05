import SwiftUI

struct ContentView: View {
    let model: TimerModel

    var body: some View {
        VStack(spacing: 16) {
            display
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
