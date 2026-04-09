// Run with:  swift PikachuPet/run.swift
// Single-file build of PikachuPet for the `swift` interpreter (no Xcode needed).

import SwiftUI
import AppKit
import Combine

// MARK: - PetState

enum PetState: String, Codable {
    case idle, eating, playing, sleeping
}

// MARK: - PetModel

final class PetModel: ObservableObject {
    @Published var hunger: Double
    @Published var happiness: Double
    @Published var energy: Double
    @Published var state: PetState = .idle

    private let hungerPerSec: Double = 0.20
    private let happinessPerSec: Double = 0.15
    private let energyPerSec: Double = 0.10
    private let energyPerSecPlaying: Double = 0.80
    private let energyRegenPerSec: Double = 1.5
    private let sleepThreshold: Double = 15
    private let wakeThreshold: Double = 95
    private let maxOfflineCatchUp: TimeInterval = 6 * 3600

    private var actionEndsAt: Date?
    private var timer: AnyCancellable?

    private let defaults = UserDefaults.standard
    private enum Key {
        static let hunger = "pikachu.hunger"
        static let happiness = "pikachu.happiness"
        static let energy = "pikachu.energy"
        static let lastTick = "pikachu.lastTickEpoch"
    }

    init() {
        self.hunger = defaults.object(forKey: Key.hunger) as? Double ?? 30
        self.happiness = defaults.object(forKey: Key.happiness) as? Double ?? 70
        self.energy = defaults.object(forKey: Key.energy) as? Double ?? 80

        if let last = defaults.object(forKey: Key.lastTick) as? Double {
            let elapsed = min(Date().timeIntervalSince1970 - last, maxOfflineCatchUp)
            if elapsed > 0 { advance(by: elapsed) }
        }
        evaluateState()

        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    var canInteract: Bool { state != .sleeping }

    func feed() {
        guard state != .sleeping else { return }
        hunger = max(0, hunger - 35)
        startAction(.eating, duration: 2)
        save()
    }

    func play() {
        guard state != .sleeping else { return }
        happiness = min(100, happiness + 25)
        energy = max(0, energy - 8)
        startAction(.playing, duration: 2)
        save()
    }

    func reset() {
        hunger = 30; happiness = 70; energy = 80
        state = .idle; actionEndsAt = nil
        save()
    }

    private func tick() { advance(by: 1); evaluateState(); save() }

    private func advance(by seconds: TimeInterval) {
        hunger = min(100, hunger + hungerPerSec * seconds)
        happiness = max(0, happiness - happinessPerSec * seconds)
        switch state {
        case .sleeping: energy = min(100, energy + energyRegenPerSec * seconds)
        case .playing:  energy = max(0, energy - energyPerSecPlaying * seconds)
        default:        energy = max(0, energy - energyPerSec * seconds)
        }
    }

    private func evaluateState() {
        if let end = actionEndsAt, Date() >= end {
            actionEndsAt = nil
            if state == .eating || state == .playing { state = .idle }
        }
        if state == .sleeping {
            if energy >= wakeThreshold { state = .idle }
        } else if energy <= sleepThreshold {
            state = .sleeping; actionEndsAt = nil
        }
    }

    private func startAction(_ s: PetState, duration: TimeInterval) {
        state = s
        actionEndsAt = Date().addingTimeInterval(duration)
    }

    private func save() {
        defaults.set(hunger, forKey: Key.hunger)
        defaults.set(happiness, forKey: Key.happiness)
        defaults.set(energy, forKey: Key.energy)
        defaults.set(Date().timeIntervalSince1970, forKey: Key.lastTick)
    }
}

// MARK: - SpriteView

struct SpriteView: View {
    let state: PetState
    @State private var bob: CGFloat = 0
    @State private var imageCache: [String: NSImage] = [:]

    private var emoji: String {
        switch state {
        case .idle:     return "⚡"
        case .eating:   return "😋"
        case .playing:  return "🤸"
        case .sleeping: return "😴"
        }
    }

    private var assetName: String {
        switch state {
        case .idle, .playing: return "pikachu_idle"
        case .eating:         return "pikachu_eat"
        case .sleeping:       return "pikachu_sleep"
        }
    }

    private func loadImage(_ name: String) -> NSImage? {
        if let cached = imageCache[name] { return cached }
        let dir = (CommandLine.arguments.first as NSString?)?.deletingLastPathComponent ?? "."
        let candidates = [
            "\(dir)/assets/\(name).png",
            "PikachuPet/assets/\(name).png",
            "assets/\(name).png",
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path),
               let img = NSImage(contentsOfFile: path) {
                DispatchQueue.main.async { imageCache[name] = img }
                return img
            }
        }
        return nil
    }

    var body: some View {
        ZStack {
            Group {
                if let img = loadImage(assetName) {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .id(assetName) // stable identity per state, no cross-fade
                } else {
                    Text(emoji).font(.system(size: 96))
                }
            }
            .offset(y: bob)
            .scaleEffect(state == .sleeping ? 0.95 : 1.0)
            .animation(animationFor(state), value: bob)

            if state == .sleeping {
                Text("z")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .offset(x: 40, y: -40)
            }
            if state == .playing {
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.pink)
                    .offset(x: -40, y: -40)
            }
        }
        .frame(width: 140, height: 140)
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

// MARK: - PetView

struct PetView: View {
    @ObservedObject var model: PetModel

    var body: some View {
        VStack(spacing: 6) {
            SpriteView(state: model.state)
            VStack(spacing: 2) {
                StatBar(label: "♥", value: model.happiness, tint: .pink)
                StatBar(label: "🍎", value: 100 - model.hunger, tint: .orange)
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

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    let model = PetModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hosting = NSHostingView(rootView: PetView(model: model))
        hosting.frame = NSRect(x: 0, y: 0, width: 180, height: 220)

        panel = NSPanel(
            contentRect: hosting.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.contentView = hosting

        if let screen = NSScreen.main {
            let f = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: f.maxX - 220, y: f.maxY - 260))
        }
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Bootstrap

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
