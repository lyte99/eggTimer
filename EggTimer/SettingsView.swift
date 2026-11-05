import SwiftUI

struct SettingsView: View {
    let player: AlarmPlayer
    @AppStorage(AlarmPlayer.defaultsKey) private var tone = AlarmPlayer.defaultTone

    var body: some View {
        Form {
            HStack {
                Picker("Alarm tone:", selection: $tone) {
                    ForEach(AlarmPlayer.generatedTones) { Text($0.name).tag($0.id) }
                    Divider()
                    ForEach(AlarmPlayer.systemTones) { Text($0.name).tag($0.id) }
                }
                Button {
                    player.preview(tone)
                } label: {
                    Image(systemName: "play.fill")
                }
                .help("Play tone")
                .accessibilityLabel("Play tone")
            }
            .onChange(of: tone) { _, newTone in player.preview(newTone) }
        }
        .padding(20)
        .frame(width: 360)
        .onDisappear { player.stop() }
    }
}
