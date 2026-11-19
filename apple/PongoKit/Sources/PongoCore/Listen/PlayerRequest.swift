import Foundation

/// Something a guest listening along does to the player, which the host's
/// player does for everyone instead. Each encodes as an object with one key,
/// its kind, which the server checks the guest may do.
public enum PlayerRequest: Codable, Sendable, Equatable {
    case play
    case pause
    case next
    case previous
    case seek(Double)
    /// Plays the entry with this ID.
    case skip(UUID)
    case add(track: Track, next: Bool)
    case remove([UUID])
    /// Moves entries in play order, as a list's move gives them.
    case move(from: [Int], to: Int)
    case playNext(UUID)
    case clearUpcoming
    case shuffle(Bool)
    case repeatMode(RepeatMode)
    /// Starts [tracks] in place of the queue.
    case replace(collectionID: String, tracks: [Track], index: Int?, shuffle: Bool)
    case mix(collectionID: String, seeds: [Track], mood: Mood?)
    /// Stops the player; a guest leaves the session instead.
    case halt
}
