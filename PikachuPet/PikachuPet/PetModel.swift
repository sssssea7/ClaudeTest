import Foundation
import Combine

final class PetModel: ObservableObject {
    // Stats 0...100
    @Published var hunger: Double
    @Published var happiness: Double
    @Published var energy: Double
    @Published var state: PetState = .idle

    // Tunables
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

        // Offline catch-up
        if let last = defaults.object(forKey: Key.lastTick) as? Double {
            let elapsed = min(Date().timeIntervalSince1970 - last, maxOfflineCatchUp)
            if elapsed > 0 { advance(by: elapsed) }
        }

        evaluateState()

        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    // MARK: - Actions

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
        hunger = 30
        happiness = 70
        energy = 80
        state = .idle
        actionEndsAt = nil
        save()
    }

    var canInteract: Bool { state != .sleeping }

    // MARK: - Tick

    private func tick() {
        advance(by: 1)
        evaluateState()
        save()
    }

    private func advance(by seconds: TimeInterval) {
        hunger = min(100, hunger + hungerPerSec * seconds)
        happiness = max(0, happiness - happinessPerSec * seconds)

        switch state {
        case .sleeping:
            energy = min(100, energy + energyRegenPerSec * seconds)
        case .playing:
            energy = max(0, energy - energyPerSecPlaying * seconds)
        default:
            energy = max(0, energy - energyPerSec * seconds)
        }
    }

    private func evaluateState() {
        // Action animations expire back to idle
        if let end = actionEndsAt, Date() >= end {
            actionEndsAt = nil
            if state == .eating || state == .playing { state = .idle }
        }

        // Sleep cycle
        if state == .sleeping {
            if energy >= wakeThreshold { state = .idle }
        } else if energy <= sleepThreshold {
            state = .sleeping
            actionEndsAt = nil
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
