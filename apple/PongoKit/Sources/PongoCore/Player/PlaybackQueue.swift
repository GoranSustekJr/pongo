import Foundation

/// An entry of the queue.
public struct QueueItem: Sendable, Hashable, Identifiable, Codable {
    /// Unique per entry, since the queue can hold a track twice.
    public var id = UUID()
    /// Where the track was started from, such as `online.album:<id>`.
    public var collectionID: String
    public var track: Track
    /// The track's length in seconds.
    public var duration: Double
    /// Whether the server added this entry to a mix.
    public var isMix = false
    /// Whether the user asked for this entry to play next.
    public var isQueued = false
    /// Who added the entry while listening together, by their user ID.
    public var addedBy: String?

    public init(track: Track, collectionID: String, duration: Double, isMix: Bool = false) {
        self.track = track
        self.collectionID = collectionID
        self.duration = duration
        self.isMix = isMix
    }

    private enum CodingKeys: String, CodingKey { case id, collectionID, track, duration, isMix, isQueued, addedBy }

    // Queues saved by earlier versions lack the newer flags
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        collectionID = try container.decode(String.self, forKey: .collectionID)
        track = try container.decode(Track.self, forKey: .track)
        duration = try container.decode(Double.self, forKey: .duration)
        isMix = try container.decodeIfPresent(Bool.self, forKey: .isMix) ?? false
        isQueued = try container.decodeIfPresent(Bool.self, forKey: .isQueued) ?? false
        addedBy = try container.decodeIfPresent(String.self, forKey: .addedBy)
    }

    public var stid: String { track.id }
}

/// How the queue repeats.
public enum RepeatMode: String, Sendable, Codable {
    case off
    case all
    case one

    /// The mode after this one when the repeat button is tapped.
    public var next: RepeatMode {
        switch self {
        case .off: .all
        case .all: .one
        case .one: .off
        }
    }
}

/// The queue and the order it plays in: which entry is current, shuffling and
/// repeating. It holds no audio, so the player and tests share it.
public struct PlaybackQueue: Sendable, Equatable {
    public private(set) var items: [QueueItem] = []
    /// The index in [items] of the current entry.
    public private(set) var currentIndex: Int?
    public private(set) var shuffleEnabled = false
    /// The indexes of [items] in the order they play while shuffled.
    public private(set) var shuffleOrder: [Int] = []
    public var repeatMode = RepeatMode.all

    public init() {}

    public var current: QueueItem? { currentIndex.map { items[$0] } }

    public var isEmpty: Bool { items.isEmpty }

    /// The indexes of [items] in play order.
    public var playOrder: [Int] { shuffleEnabled ? shuffleOrder : Array(items.indices) }

    /// The position of the current entry in [playOrder].
    public var position: Int? { currentIndex.flatMap { playOrder.firstIndex(of: $0) } }

    /// The entries in play order, from the current one on.
    public var upcoming: [QueueItem] {
        guard let position else { return [] }
        return playOrder[position...].map { items[$0] }
    }

    /// Replaces the queue with [items], starting at [index], or at a random
    /// entry if shuffling and [index] is `nil`.
    public mutating func replace(with items: [QueueItem], startingAt index: Int?) {
        self.items = items
        guard !items.isEmpty else {
            currentIndex = nil
            shuffleOrder = []
            return
        }
        if shuffleEnabled {
            let start = index ?? Int.random(in: items.indices)
            reshuffle(keepingFirst: start)
            currentIndex = start
        } else {
            currentIndex = index ?? 0
        }
    }

    /// Turns shuffling on or off. The current entry stays current and plays
    /// first in the new order.
    public mutating func setShuffle(_ enabled: Bool) {
        shuffleEnabled = enabled
        if enabled { reshuffle(keepingFirst: currentIndex) }
    }

    private mutating func reshuffle(keepingFirst first: Int?) {
        var order = Array(items.indices).shuffled()
        if let first, let at = order.firstIndex(of: first) { order.swapAt(0, at) }
        shuffleOrder = order
    }

    /// Adds [suggestions] to [items] and spreads them through the shuffled
    /// order still to come, never right after the current entry.
    public mutating func insertSuggestions(_ suggestions: [QueueItem]) {
        guard shuffleEnabled, let position, !suggestions.isEmpty else { return }
        var order = shuffleOrder
        let upcoming = order.count - position - 1
        let first = items.count
        items += suggestions
        for (offset, index) in (first..<items.count).enumerated() {
            // Earlier insertions moved the later slots on by one each
            let slot = position + 2 + upcoming * (offset + 1) / (suggestions.count + 1) + offset
            order.insert(index, at: min(slot, order.count))
        }
        shuffleOrder = order
    }

    /// Makes the entry at [index] of [items] current.
    public mutating func select(_ index: Int) {
        guard items.indices.contains(index) else { return }
        currentIndex = index
    }

    /// The index of the entry after the current one, for when it ends or the
    /// user skips; `nil` at the end of the queue unless it repeats.
    /// [userSkipped] moves on even when repeating one track.
    public func nextIndex(userSkipped: Bool) -> Int? {
        guard let currentIndex else { return nil }
        if repeatMode == .one && !userSkipped { return currentIndex }
        let order = playOrder
        guard let position = order.firstIndex(of: currentIndex) else { return nil }
        if position + 1 < order.count { return order[position + 1] }
        return repeatMode == .off && !userSkipped ? nil : order.first
    }

    /// The index of the entry before the current one, if any.
    public func previousIndex() -> Int? {
        guard let position else { return nil }
        let order = playOrder
        if position > 0 { return order[position - 1] }
        return repeatMode == .off ? nil : order.last
    }

    /// Appends [item], which also plays last while shuffled.
    public mutating func append(_ item: QueueItem) {
        items.append(item)
        if shuffleEnabled { shuffleOrder.append(items.count - 1) }
        if currentIndex == nil { currentIndex = 0 }
    }

    /// Inserts [item] at [index] of the queue, which also plays there while
    /// shuffled; the current entry stays current.
    public mutating func insert(_ item: QueueItem, at index: Int) {
        let index = min(max(index, 0), items.count)
        items.insert(item, at: index)
        shuffleOrder = shuffleOrder.map { $0 >= index ? $0 + 1 : $0 }
        if shuffleEnabled { shuffleOrder.insert(index, at: min(index, shuffleOrder.count)) }
        if let currentIndex, index <= currentIndex { self.currentIndex = currentIndex + 1 }
        if currentIndex == nil { currentIndex = 0 }
    }

    /// How many entries the user queued to play right after the current one.
    public var queuedCount: Int {
        guard let position else { return 0 }
        return playOrder[(position + 1)...].prefix { items[$0].isQueued }.count
    }

    /// Inserts [item] to play after the current entry and those queued
    /// before it, so entries queued one after another play in that order.
    public mutating func insertNext(_ item: QueueItem) {
        let queued = queuedCount
        let index = currentIndex.map { $0 + 1 + (shuffleEnabled ? 0 : queued) } ?? 0
        items.insert(item, at: index)
        shuffleOrder = shuffleOrder.map { $0 >= index ? $0 + 1 : $0 }
        if let currentIndex, index <= currentIndex { self.currentIndex = currentIndex + 1 }
        if shuffleEnabled {
            let after = position.map { $0 + 1 + queued } ?? 0
            shuffleOrder.insert(index, at: after)
        }
        if currentIndex == nil { currentIndex = 0 }
    }

    /// Moves the entry at [index] to play next, after those already queued.
    public mutating func moveNext(_ index: Int) {
        guard items.indices.contains(index), index != currentIndex else { return }
        var item = items[index]
        item.isQueued = true
        remove(at: index)
        insertNext(item)
    }

    /// Removes every entry after the current one in play order.
    public mutating func removeUpcoming() {
        guard let position else { return }
        for index in playOrder[(position + 1)...].sorted(by: >) { remove(at: index) }
    }

    /// Removes the entry at [index], unless it's the current one.
    public mutating func remove(at index: Int) {
        guard items.indices.contains(index), index != currentIndex else { return }
        items.remove(at: index)
        shuffleOrder = shuffleOrder.filter { $0 != index }.map { $0 > index ? $0 - 1 : $0 }
        if let currentIndex, index < currentIndex { self.currentIndex = currentIndex - 1 }
    }

    /// Moves the entries at [offsets] of the play order to [destination], as
    /// a list's move gives them.
    public mutating func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        if shuffleEnabled {
            shuffleOrder.moveElements(fromOffsets: offsets, toOffset: destination)
            return
        }
        let current = current?.id
        items.moveElements(fromOffsets: offsets, toOffset: destination)
        currentIndex = items.firstIndex { $0.id == current }
    }

    /// Sets the length of the entry with [id], once it's known.
    public mutating func setDuration(_ duration: Double, of id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].duration = duration
    }

    /// Empties the queue.
    public mutating func clear() {
        items = []
        currentIndex = nil
        shuffleOrder = []
    }

    /// Restores a queue saved by [snapshot].
    public mutating func restore(_ snapshot: Snapshot) {
        items = snapshot.items
        shuffleEnabled = snapshot.shuffleEnabled
        repeatMode = snapshot.repeatMode
        shuffleOrder =
            snapshot.shuffleOrder.sorted() == Array(items.indices) ? snapshot.shuffleOrder : Array(items.indices)
        currentIndex = snapshot.currentIndex.flatMap { items.indices.contains($0) ? $0 : nil }
            ?? (items.isEmpty ? nil : 0)
    }

    /// The queue as it's saved between launches.
    public struct Snapshot: Codable, Sendable {
        public var items: [QueueItem]
        public var currentIndex: Int?
        public var shuffleEnabled: Bool
        public var shuffleOrder: [Int]
        public var repeatMode: RepeatMode
        public var position: Double
        /// Whether a mix was adding tracks, and the mood it kept to.
        public var mixActive: Bool?
        public var mixMood: Mood?
        /// The entries smart shuffle suggested and the user didn't keep.
        public var suggested: [UUID]?
    }

    public func snapshot(position: Double) -> Snapshot {
        Snapshot(
            items: items, currentIndex: currentIndex, shuffleEnabled: shuffleEnabled, shuffleOrder: shuffleOrder,
            repeatMode: repeatMode, position: position)
    }
}

extension Array {
    /// Moves the elements at [offsets] to [destination], counted before the
    /// move, like a list's move gives them.
    mutating func moveElements(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        let moving = offsets.map { self[$0] }
        let before = offsets.filter { $0 < destination }.count
        for index in offsets.reversed() { remove(at: index) }
        insert(contentsOf: moving, at: destination - before)
    }
}
