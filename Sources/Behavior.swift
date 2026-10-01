import Foundation
enum PetMood: Equatable { case sitting, runningRight, runningLeft, resting, asleep }
struct PetBehavior {
    private(set) var mood: PetMood = .sitting
    private(set) var unattended: TimeInterval = 0
    private var runRemaining: TimeInterval = 0
    mutating func poke(leftHalf: Bool) {
        unattended = 0; runRemaining = 1.0
        mood = leftHalf ? .runningRight : .runningLeft
    }
    mutating func settle() { unattended = 0; runRemaining = 0; mood = .sitting }
    mutating func stopAtEdge() { runRemaining = 0; mood = .sitting }
    mutating func advance(_ seconds: TimeInterval) {
        unattended += max(0, seconds)
        if runRemaining > 0 {
            runRemaining = max(0, runRemaining - seconds)
            if runRemaining > 0 { return }
        }
        mood = unattended >= 180 ? .asleep : unattended >= 120 ? .resting : .sitting
    }
}

// Kept separate from elapsed-time behavior: lifting always overrides the idle pose.
enum PetPresentation: Equatable {
    case sprite, lying, sleeping, carried
    init(mood: PetMood, isCarried: Bool) {
        if isCarried { self = .carried }
        else if mood == .asleep { self = .sleeping }
        else if mood == .resting { self = .lying }
        else { self = .sprite }
    }
}
