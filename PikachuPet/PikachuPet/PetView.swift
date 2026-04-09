import SwiftUI
import AppKit

struct PetView: View {
    @ObservedObject var model: PetModel

    var body: some View {
        VStack(spacing: 6) {
            SpriteView(state: model.state)

            VStack(spacing: 2) {
                StatBar(label: "♥", value: model.happiness, tint: .pink)
                StatBar(label: "🍎", value: 100 - model.hunger, tint: .orange) // show fullness
                StatBar(label: "⚡", value: model.energy, tint: .yellow)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.35))
            .cornerRadius(8)
        }
        .padding(8)
        .contextMenu {
            Button("Feed") { model.feed() }.disabled(!model.canInteract)
            Button("Play") { model.play() }.disabled(!model.canInteract)
            Divider()
            Button("Reset stats") { model.reset() }
            Divider()
            Button("Quit Pikachu") { NSApp.terminate(nil) }
        }
    }
}

private struct StatBar: View {
    let label: String
    let value: Double
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 10))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.2))
                    Capsule().fill(tint).frame(width: geo.size.width * CGFloat(value / 100))
                }
            }
            .frame(height: 6)
        }
        .frame(width: 120)
    }
}
