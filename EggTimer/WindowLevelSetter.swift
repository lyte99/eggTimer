import AppKit
import SwiftUI

/// Sets the hosting window's level directly, so "Always on Top" applies both
/// at launch and the moment it's toggled.
struct WindowLevelSetter: NSViewRepresentable {
    let floating: Bool

    func makeNSView(context: Context) -> LevelView { LevelView() }

    func updateNSView(_ view: LevelView, context: Context) {
        view.floating = floating
    }

    final class LevelView: NSView {
        var floating = false { didSet { apply() } }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            apply()
        }

        private func apply() {
            guard let window else { return }
            window.level = floating ? .floating : .normal
            // Stay visible when switching Spaces or over full-screen apps.
            window.collectionBehavior = floating
                ? [.canJoinAllSpaces, .fullScreenAuxiliary]
                : []
        }
    }
}
