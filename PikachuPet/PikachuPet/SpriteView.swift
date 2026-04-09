import SwiftUI

/// Renders the pet sprite for the current state.
/// Drop PNGs named `pikachu_idle`, `pikachu_eat`, `pikachu_play`, `pikachu_sleep`
/// into Assets.xcassets. Falls back to the ⚡ emoji if an asset is missing,
/// so the app runs before you've added art.
struct SpriteView: View {
    let state: PetState

    @State private var bob: CGFloat = 0

    private var assetName: String {
        switch state {
        case .idle:     return "pikachu_idle"
        case .eating:   return "pikachu_eat"
        case .playing:  return "pikachu_play"
        case .sleeping: return "pikachu_sleep"
        }
    }

    var body: some View {
        ZStack {
            if let nsImage = NSImage(named: assetName) {
                Image(nsImage: nsImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                // Placeholder so the app works before you add sprites
                Text("⚡")
                    .font(.system(size: 96))
            }

            if state == .sleeping {
                Text("z")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .offset(x: 40, y: -40)
            }
        }
        .frame(width: 140, height: 140)
        .offset(y: bob)
        .scaleEffect(state == .sleeping ? 0.95 : 1.0)
        .animation(animationFor(state), value: bob)
        .onAppear { startBobbing() }
        .onChange(of: state) { _ in startBobbing() }
    }

    private func animationFor(_ s: PetState) -> Animation {
        switch s {
        case .idle:     return .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        case .eating:   return .easeInOut(duration: 0.2).repeatForever(autoreverses: true)
        case .playing:  return .interpolatingSpring(stiffness: 200, damping: 6).repeatForever(autoreverses: true)
        case .sleeping: return .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
        }
    }

    private func startBobbing() {
        bob = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            switch state {
            case .idle:     bob = -4
            case .eating:   bob = -2
            case .playing:  bob = -16
            case .sleeping: bob = 2
            }
        }
    }
}
