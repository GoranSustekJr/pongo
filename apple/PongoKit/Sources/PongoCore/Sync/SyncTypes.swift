import Foundation

/// Which library item a sync item is: its kind, such as `favourite`, and its
/// key within the kind, such as the track ID.
public struct SyncKey: Sendable, Hashable {
    public var kind: String
    public var key: String

    public init(kind: String, key: String) {
        self.kind = kind
        self.key = key
    }
}

/// A library item as it's synced: its data, or `nil` if there's no such item,
/// and when it last changed in milliseconds since the epoch, or 0 if the item
/// doesn't record that itself.
public struct SyncItem: Sendable, Equatable {
    public var data: [String: JSONValue]?
    public var changedAt: Int

    public init(data: [String: JSONValue]?, changedAt: Int = 0) {
        self.data = data
        self.changedAt = changedAt
    }
}

/// What was last synced of an item: a hash of its data, `nil` once deleted,
/// when it changed, and whether the server still has to get the change.
public struct SyncState: Sendable, Equatable {
    public var hash: String?
    public var changedAt: Int
    public var dirty: Bool

    public init(hash: String?, changedAt: Int, dirty: Bool) {
        self.hash = hash
        self.changedAt = changedAt
        self.dirty = dirty
    }
}

/// Part of the library that's synced, such as the database or the settings.
public protocol SyncSource: Sendable {
    /// The kinds of items this source holds.
    var kinds: Set<String> { get }
    /// Every item this source holds.
    func snapshot() async throws -> [SyncKey: SyncItem]
    /// The item [key] as it's stored now.
    func item(_ key: SyncKey) async throws -> SyncItem
    /// Stores [data] as item [key], or deletes the item if [data] is `nil`.
    func apply(_ key: SyncKey, _ data: [String: JSONValue]?) async throws
}

/// Where syncing keeps what it last synced.
public protocol SyncStateStore: Sendable {
    /// Where the last sync left off on the server, or `nil` before the first.
    func cursor() async throws -> Int?
    func setCursor(_ cursor: Int) async throws
    /// What was last synced of every item.
    func states() async throws -> [SyncKey: SyncState]
    /// Stores [states], replacing earlier ones.
    func saveStates(_ states: [SyncKey: SyncState]) async throws
    /// Forgets what was synced, as before the first sync.
    func clearSyncState() async throws
    /// A count that grows with every change to the library, so a change since
    /// an earlier count shows.
    func changeCount() async -> Int
}
