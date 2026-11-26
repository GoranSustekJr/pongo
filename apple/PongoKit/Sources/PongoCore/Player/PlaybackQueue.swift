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
    /// The entry's place in the collection the queue was started from, or
    /// `nil` for one added to it, such as by a mix.
    public var contextIndex: Int?

    public init(track: Track, collectionID: String, duration: Double, isMix: Bool = false) {
        self.track = track
        self.collectionID = collectionID
        self.duration = duration
        self.isMix = isMix
    }

    private enum CodingKeys: String, CodingKey { case id, collectionID, track, duration, isMix, isQueued, addedBy, contextIndex }

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
        contextIndex = try container.decodeIfPresent(Int.self, forKey: .contextIndex)
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
///
/// The play order has parts that each keep to themselves: the entries played
/// before the current one, in the order they played; the current one; those
/// the user queued to play next; the rest of the collection the queue was
/// started from, such as a playlist or album; and the entries added after it,
/// such as by a mix or smart shuffle. Shuffling only reorders the rest of the
/// collection.
public struct PlaybackQueue: Sendable, Equatable {
    /// The entries, in the order they were added; [playOrder] says when each plays.
    public private(set) var items: [QueueItem] = []
    /// The index in [items] of the current entry.
    public private(set) var currentIndex: Int?
    public private(set) var shuffleEnabled = false
    /// The indexes of [items] in the order they play.
    public private(set) var playOrder: [Int] = []
    /// The entries that were current at some point, so shuffling can tell
    /// the collection's tracks that were skipped over from those that played.
    public private(set) var played: Set<UUID> = []
    public var repeatMode = RepeatMode.all

    public init() {}

    public var current: QueueItem? { currentIndex.map { items[$0] } }

    public var isEmpty: Bool { items.isEmpty }

    /// The position of the current entry in [playOrder].
    public var position: Int? { currentIndex.flatMap { playOrder.firstIndex(of: $0) } }

    /// The entries in play order, from the current one on.
    public var upcoming: [QueueItem] {
        guard let position else { return [] }
        return playOrder[position...].map { items[$0] }
    }

    /// Whether the entry at [index] of [items] belongs to the collection the
    /// queue was started from, rather than queued or added to it.
    public func isFromCollection(_ index: Int) -> Bool {
        items[index].contextIndex != nil && !items[index].isQueued
    }

    /// How many entries the user queued to play right after the current one.
    public var queuedCount: Int {
        guard let position else { return 0 }
        return playOrder[(position + 1)...].prefix { items[$0].isQueued }.count
    }

    /// How many of the collection's entries play after those queued, before
    /// the ones added after the collection.
    public var collectionCount: Int {
        guard let position else { return 0 }
        return playOrder[(position + 1 + queuedCount)...].prefix { isFromCollection($0) }.count
    }

    /// Replaces the queue with the collection [items], starting at [index],
    /// or at a random entry if shuffling and [index] is `nil`.
    public mutating func replace(with items: [QueueItem], startingAt index: Int?) {
        self.items = items.enumerated().map { offset, item in
            var item = item
            if item.contextIndex == nil, !item.isMix, !item.isQueued { item.contextIndex = offset }
            return item
        }
        played = []
        guard !items.isEmpty else {
            currentIndex = nil
            playOrder = []
            return
        }
        if shuffleEnabled {
            let start = index ?? Int.random(in: items.indices)
            playOrder = [start] + items.indices.filter { $0 != start }.shuffled()
            currentIndex = start
        } else {
            playOrder = Array(items.indices)
            currentIndex = index ?? 0
        }
        markCurrentPlayed()
    }

    /// Turns shuffling on or off, which reorders only the collection's
    /// entries still to play; the rest of the queue stays as it is.
    public mutating func setShuffle(_ enabled: Bool) {
        shuffleEnabled = enabled
        arrangeCollection()
    }

    /// Puts the collection's entries still to play in shuffled or in the
    /// collection's order, between those queued and those added after it.
    private mutating func arrangeCollection() {
        guard let position else { return }
        let current = playOrder[position]
        let after = playOrder[(position + 1)...]
        let queued = Array(after.prefix { items[$0].isQueued })
        let rest = after.dropFirst(queued.count)
        // Tracks of the collection that were skipped over, as when it was
        // started from its middle, still play
        let skipped = playOrder[..<position].filter { isFromCollection($0) && !played.contains(items[$0].id) }
        var collection = rest.filter { isFromCollection($0) } + skipped
        let added = rest.filter { !isFromCollection($0) }
        if shuffleEnabled {
            collection.shuffle()
        } else {
            // In the collection's order, on from the track that plays or last played
            collection.sort { items[$0].contextIndex! < items[$1].contextIndex! }
            let from =
                items[current].contextIndex
                ?? playOrder[..<position].last { isFromCollection($0) }.flatMap { items[$0].contextIndex } ?? -1
            collection = collection.filter { items[$0].contextIndex! > from }
                + collection.filter { items[$0].contextIndex! <= from }
        }
        let skippedSet = Set(skipped)
        playOrder = playOrder[..<position].filter { !skippedSet.contains($0) } + [current] + queued + collection + added
    }

    /// Makes the entry at [index] of [items] current.
    public mutating func select(_ index: Int) {
        guard items.indices.contains(index) else { return }
        currentIndex = index
        markCurrentPlayed()
    }

    private mutating func markCurrentPlayed() {
        if let current { played.insert(current.id) }
    }

    /// The index of the entry after the current one, for when it ends or the
    /// user skips; `nil` at the end of the queue unless it repeats.
    /// [userSkipped] moves on even when repeating one track.
    public func nextIndex(userSkipped: Bool) -> Int? {
        guard let currentIndex else { return nil }
        if repeatMode == .one && !userSkipped { return currentIndex }
        guard let position else { return nil }
        if position + 1 < playOrder.count { return playOrder[position + 1] }
        return repeatMode == .off && !userSkipped ? nil : playOrder.first
    }

    /// The index of the entry before the current one, if any.
    public func previousIndex() -> Int? {
        guard let position else { return nil }
        if position > 0 { return playOrder[position - 1] }
        return repeatMode == .off ? nil : playOrder.last
    }

    /// Adds [item] at the end: a track of the collection after the rest of
    /// it, before the entries added after it, and any other at the very end.
    public mutating func append(_ item: QueueItem) {
        let index = items.count
        items.append(item)
        if isFromCollection(index), let position {
            let start = position + 1 + queuedCount
            let at = playOrder[start...].firstIndex { !isFromCollection($0) } ?? playOrder.count
            playOrder.insert(index, at: at)
        } else {
            playOrder.append(index)
        }
        if currentIndex == nil {
            currentIndex = index
            markCurrentPlayed()
        }
    }

    /// Inserts [item] at [position] of the play order; the current entry
    /// stays current.
    public mutating func insert(_ item: QueueItem, atPosition position: Int) {
        let index = items.count
        items.append(item)
        playOrder.insert(index, at: min(max(position, 0), playOrder.count))
        if currentIndex == nil {
            currentIndex = index
            markCurrentPlayed()
        }
    }

    /// Inserts [item] to play after the current entry and those queued
    /// before it, so entries queued one after another play in that order.
    public mutating func insertNext(_ item: QueueItem) {
        let at = position.map { $0 + 1 + queuedCount } ?? 0
        insert(item, atPosition: at)
    }

    /// Moves the entry at [index] to play next, after those already queued.
    public mutating func moveNext(_ index: Int) {
        guard items.indices.contains(index), index != currentIndex else { return }
        items[index].isQueued = true
        playOrder.removeAll { $0 == index }
        let at = position.map { $0 + 1 + queuedCount } ?? 0
        playOrder.insert(index, at: at)
    }

    /// Removes every entry after the current one in play order.
    public mutating func removeUpcoming() {
        guard let position else { return }
        for index in playOrder[(position + 1)...].sorted(by: >) { remove(at: index) }
    }

    /// Removes the entry at [index], unless it's the current one.
    public mutating func remove(at index: Int) {
        guard items.indices.contains(index), index != currentIndex else { return }
        played.remove(items[index].id)
        items.remove(at: index)
        playOrder = playOrder.filter { $0 != index }.map { $0 > index ? $0 - 1 : $0 }
        if let currentIndex, index < currentIndex { self.currentIndex = currentIndex - 1 }
    }

    /// Moves the entries at [offsets] of the play order to [destination], as
    /// a list's move gives them.
    public mutating func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        playOrder.moveElements(fromOffsets: offsets, toOffset: destination)
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
        playOrder = []
        played = []
    }

    /// Restores a queue saved by [snapshot].
    public mutating func restore(_ snapshot: Snapshot) {
        items = snapshot.items
        shuffleEnabled = snapshot.shuffleEnabled
        repeatMode = snapshot.repeatMode
        currentIndex = snapshot.currentIndex.flatMap { items.indices.contains($0) ? $0 : nil }
            ?? (items.isEmpty ? nil : 0)
        if let order = snapshot.order, order.sorted() == Array(items.indices) {
            playOrder = order
            played = Set(snapshot.played ?? [])
        } else {
            // Saved before the queue had parts: the shuffled order held every entry
            let shuffled = snapshot.shuffleEnabled && snapshot.shuffleOrder.sorted() == Array(items.indices)
            playOrder = shuffled ? snapshot.shuffleOrder : Array(items.indices)
            for index in items.indices where !items[index].isMix && !items[index].isQueued {
                items[index].contextIndex = items[index].contextIndex ?? index
            }
            played = Set((position.map { playOrder[...$0] } ?? []).map { items[$0].id })
        }
        markCurrentPlayed()
    }

    /// The queue as it's saved between launches and handed to other devices.
    public struct Snapshot: Codable, Sendable {
        public var items: [QueueItem]
        public var currentIndex: Int?
        public var shuffleEnabled: Bool
        /// The play order, also under the name earlier versions read it by.
        public var shuffleOrder: [Int]
        public var repeatMode: RepeatMode
        public var position: Double
        /// Whether a mix was adding tracks, and the mood it kept to.
        public var mixActive: Bool?
        public var mixMood: Mood?
        /// The entries smart shuffle suggested and the user didn't keep.
        public var suggested: [UUID]?
        /// The play order; missing from queues saved by earlier versions.
        public var order: [Int]?
        public var played: [UUID]?
    }

    public func snapshot(position: Double) -> Snapshot {
        Snapshot(
            items: items, currentIndex: currentIndex, shuffleEnabled: shuffleEnabled, shuffleOrder: playOrder,
            repeatMode: repeatMode, position: position, order: playOrder, played: Array(played))
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
