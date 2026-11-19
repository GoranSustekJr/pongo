import Foundation

/// A track the server added to a mix, with its length in seconds.
public struct MixEntry: Sendable {
    public var track: Track
    public var duration: Double

    public init(track: Track, duration: Double) {
        self.track = track
        self.duration = duration
    }
}

/// Keeps a mix going by fetching more similar tracks whenever the queue is
/// nearly done.
///
/// Only one request runs at a time, answers for a mix that has since stopped
/// are dropped, and after a failure it tries again with growing delays.
@MainActor
public final class MixRefill {
    /// Tracks left after the current one when more are fetched.
    public static let refillWhenLeft = 2
    /// Tracks fetched per request.
    public static let batchSize = 3
    /// Recently played tracks the next ones are chosen from.
    public static let seedCount = 5

    // Both run on the main actor: the player behind them changes its queue,
    // which a plain async closure would do off the main thread
    public typealias Fetch = @MainActor (_ seeds: [String], _ exclude: [String], _ count: Int) async throws
        -> [MixEntry]
    public typealias Append = @MainActor ([MixEntry]) -> Void

    private let fetch: Fetch
    private let append: Append
    private let retryDelay: (Int) -> Duration

    // Incremented whenever a mix starts or stops, so older requests are ignored
    private var session = 0
    public private(set) var isActive = false
    private var fetchingFor: Int?
    private var failures = 0
    private var retry: Task<Void, Never>?
    private var queue: [String] = []
    private var position: Int?

    public init(
        fetch: @escaping Fetch, append: @escaping Append,
        retryDelay: ((Int) -> Duration)? = nil
    ) {
        self.fetch = fetch
        self.append = append
        self.retryDelay = retryDelay ?? { failures in .seconds(min(5 * (1 << (failures - 1)), 300)) }
    }

    /// Starts a new mix, replacing any running one.
    public func start() {
        reset()
        isActive = true
    }

    /// Stops the mix and ignores any request still running.
    public func stop() {
        reset()
        isActive = false
    }

    private func reset() {
        session += 1
        fetchingFor = nil
        failures = 0
        retry?.cancel()
        retry = nil
    }

    /// Reports the queue's track IDs in play order and the [position] of the
    /// current one, and fetches more tracks if the queue is nearly done.
    public func update(queue: [String], position: Int?) {
        self.queue = queue
        self.position = position
        check()
    }

    private func check() {
        guard isActive, let position, position < queue.count,
            queue.count - 1 - position <= Self.refillWhenLeft, fetchingFor != session, retry == nil
        else { return }
        Task { await refill(position) }
    }

    private func refill(_ position: Int) async {
        let session = self.session
        fetchingFor = session
        let played = queue[...position].reversed()
        var entries: [MixEntry] = []
        do {
            let fetched = try await fetch(
                Array(played.prefix(Self.seedCount)), Array(Set(queue)), Self.batchSize)
            guard session == self.session else { return }
            var queued = Set(queue)
            entries = fetched.filter { queued.insert($0.track.id).inserted }
            if !entries.isEmpty {
                append(entries)
                failures = 0
                // Counted now, since the player reports the longer queue only later
                queue += entries.map(\.track.id)
            }
        } catch {
            entries = []
        }
        guard session == self.session else { return }
        fetchingFor = nil
        if entries.isEmpty {
            // Also when the server had nothing new, so it isn't asked again at once
            failures += 1
            let delay = retryDelay(failures)
            retry = Task { [weak self] in
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                self?.retry = nil
                self?.check()
            }
        } else {
            // The queue may have moved on while the tracks were fetched
            check()
        }
    }
}
