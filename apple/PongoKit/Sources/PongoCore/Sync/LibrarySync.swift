import CryptoKit
import Foundation
import Observation

/// Keeps the library the same on all of the user's devices.
///
/// A sync compares the library with what was last synced, sends the server
/// the items that changed, and stores the items that changed on the server
/// since the last sync. The latest change to an item wins. [revision] grows
/// whenever a sync changed the library, so screens can reload.
@MainActor
@Observable
public final class LibrarySync {
    /// How often the library is checked for changes to send.
    public static let checkEvery: Duration = .seconds(30)
    /// How often the server is asked for changes when the library didn't
    /// change, and how often a failed sync is retried.
    public static let pullEvery: TimeInterval = 300

    // What the server takes in one request
    static let maxChanges = 500
    static let maxRequestBytes = 6_000_000
    static let maxItemBytes = 1_900_000
    static let maxKeyLength = 200
    static let maxRequests = 1000

    /// Grows whenever a sync changed the library.
    public private(set) var revision = 0

    @ObservationIgnored private let client: APIClient
    @ObservationIgnored private let store: SyncStateStore
    @ObservationIgnored private let sources: [String: SyncSource]
    @ObservationIgnored private let uniqueSources: [SyncSource]
    @ObservationIgnored private let now: @Sendable () -> Date
    @ObservationIgnored private var timer: Task<Void, Never>?
    @ObservationIgnored private var running: Task<Void, Never>?
    @ObservationIgnored private var again = false
    @ObservationIgnored private var checkedChanges: Int?
    @ObservationIgnored private var lastAttempt: Date?

    public init(
        client: APIClient, store: SyncStateStore, sources: [SyncSource],
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.client = client
        self.store = store
        uniqueSources = sources
        var byKind: [String: SyncSource] = [:]
        for source in sources {
            for kind in source.kinds { byKind[kind] = source }
        }
        self.sources = byKind
        self.now = now
    }

    /// Syncs now and then whenever the library changes, until [stop].
    public func start() async {
        if timer == nil {
            timer = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: Self.checkEvery)
                    await self?.check()
                }
            }
        }
        await sync()
    }

    public func stop() {
        timer?.cancel()
        timer = nil
    }

    /// Stops syncing and forgets what was synced, for when the user signs out.
    public func reset() async {
        stop()
        await running?.value
        try? await store.clearSyncState()
        checkedChanges = nil
        lastAttempt = nil
    }

    /// Syncs once, if started. If a sync is running, syncs again after it.
    public func sync() async {
        guard timer != nil else { return }
        if let running {
            again = true
            await running.value
            return
        }
        let task = Task { await syncWhileAsked() }
        running = task
        await task.value
        running = nil
    }

    private func check() async {
        let changes = await store.changeCount()
        if let lastAttempt, now().timeIntervalSince(lastAttempt) < Self.pullEvery, changes == checkedChanges {
            return
        }
        await sync()
    }

    private func syncWhileAsked() async {
        repeat {
            again = false
            lastAttempt = now()
            let changesBefore = await store.changeCount()
            do {
                let synced = try await syncOnce()
                // Changes while syncing, including the sync's own, are checked
                // again; after a failure only new changes are
                checkedChanges = synced ? changesBefore : await store.changeCount()
            } catch {
                print("LibrarySync failed: \(error)")
                checkedChanges = await store.changeCount()
            }
        } while again && timer != nil
    }

    /// Returns whether the server got every change.
    private func syncOnce() async throws -> Bool {
        let cursor = try await store.cursor()
        var local: [SyncKey: SyncItem] = [:]
        for source in uniqueSources {
            local.merge(try await source.snapshot()) { $1 }
        }
        var hashes = local.mapValues { Self.hash($0.data) }
        let states = try await store.states()
        let now = Int(now().timeIntervalSince1970 * 1000)

        // The changes the server still has to get
        var pending: [SyncKey: SyncItem] = [:]
        for (key, item) in local {
            let state = states[key]
            if let state, state.hash == hashes[key] {
                if state.dirty { pending[key] = SyncItem(data: item.data, changedAt: state.changedAt) }
                continue
            }
            // The server would refuse these, and with them the rest of the request
            if key.key.isEmpty || key.key.count > Self.maxKeyLength
                || JSONValue.object(item.data ?? [:]).encoded().count > Self.maxItemBytes
            {
                continue
            }
            // Before the first sync it's unknown when items changed, so the
            // server's versions win
            let since = item.changedAt > 0 ? item.changedAt : cursor == nil && state == nil ? 1 : now
            pending[key] = SyncItem(data: item.data, changedAt: max(since, (state?.changedAt ?? 0) + 1))
        }
        for (key, state) in states where local[key] == nil && sources[key.kind] != nil {
            if state.hash != nil {
                pending[key] = SyncItem(data: nil, changedAt: max(now, state.changedAt + 1))
            } else if state.dirty {
                pending[key] = SyncItem(data: nil, changedAt: state.changedAt)
            }
        }

        // Stored first, so a change is sent again if this sync fails
        if !pending.isEmpty {
            try await store.saveStates(
                pending.mapValues { SyncState(hash: Self.hash($0.data), changedAt: $0.changedAt, dirty: true) })
        }

        let requests = Self.requests(pending)
        var at = cursor ?? 0
        var more = true
        var changed = false
        var sent = 0
        while sent < requests.count || more {
            if sent == Self.maxRequests { return false }
            let response: JSONValue
            do {
                response = try await client.post(
                    "sync",
                    ["cursor": .int(at), "changes": .array(sent < requests.count ? requests[sent] : [])])
            } catch {
                return false
            }
            var synced: [SyncKey: SyncState] = [:]
            for change in response["changes"]?.array ?? [] {
                guard let kind = change["kind"]?.string, let key = change["key"]?.string,
                    let changedAt = change["changed_at"]?.int, sources[kind] != nil
                else { continue }
                let item = SyncKey(kind: kind, key: key)
                guard
                    let stored = try await receive(
                        item, change["data"]?.object, changedAt, snapshotHash: hashes[item] ?? nil,
                        mine: pending[item])
                else { continue }
                if stored.changed { changed = true }
                hashes[item] = stored.state.hash
                synced[item] = stored.state
            }
            if !synced.isEmpty { try await store.saveStates(synced) }
            more = response["more"]?.bool == true
            if let next = response["cursor"]?.int, next != at {
                at = next
                try await store.setCursor(at)
            } else if cursor == nil && sent == 0 {
                try await store.setCursor(at)
            }
            sent += 1
        }
        if changed { revision += 1 }
        return true
    }

    /// Stores [data] from the server as [item], unless the device has a newer
    /// change to it, and returns what's synced of the item and whether it
    /// changed; returns `nil` if the device's change is newer.
    private func receive(
        _ item: SyncKey, _ data: [String: JSONValue]?, _ changedAt: Int, snapshotHash: String?,
        mine: SyncItem?
    ) async throws -> (state: SyncState, changed: Bool)? {
        let source = sources[item.kind]!
        let current = Self.hash(try await source.item(item).data)
        let hash = Self.hash(data)
        // The device has it already, such as its own change coming back, or it
        // changed while syncing and the next sync sends it as the latest change
        if current == hash || current != snapshotHash {
            return (SyncState(hash: hash, changedAt: changedAt, dirty: false), false)
        }
        if let mine, mine.changedAt > changedAt { return nil }
        try await source.apply(item, data)
        // Stored as the device stores it, which can differ from the data, such
        // as a playlist keeping its own cover when the data has none
        return (
            SyncState(hash: Self.hash(try await source.item(item).data), changedAt: changedAt, dirty: false), true
        )
    }

    /// [pending] as the changes of each request.
    static func requests(_ pending: [SyncKey: SyncItem]) -> [[JSONValue]] {
        var requests: [[JSONValue]] = []
        var current: [JSONValue] = []
        var bytes = 0
        for (key, item) in pending {
            let change: JSONValue = [
                "kind": .string(key.kind), "key": .string(key.key),
                "data": item.data.map(JSONValue.object) ?? .null, "changed_at": .int(item.changedAt),
            ]
            let size = change.encoded().count
            if current.count == maxChanges || (!current.isEmpty && bytes + size > maxRequestBytes) {
                requests.append(current)
                current = []
                bytes = 0
            }
            current.append(change)
            bytes += size
        }
        if !current.isEmpty { requests.append(current) }
        return requests
    }

    /// A hash of [data] that's the same however its keys are ordered.
    nonisolated static func hash(_ data: [String: JSONValue]?) -> String? {
        guard let data else { return nil }
        return Insecure.SHA1.hash(data: JSONValue.object(data).encoded())
            .map { String(format: "%02x", $0) }.joined()
    }
}
