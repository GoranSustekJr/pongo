import AVFoundation
import Foundation
import MediaPlayer
import Observation

/// Something the player wants to tell the user.
public enum PlayerMessage: Sendable {
    /// A sleep alarm started; the app must stay open for it to work.
    case keepAppOpen
    /// Play or pause was blocked because an alarm is waiting to wake the user.
    case sleepAlarmEnabled
    /// The player couldn't be stopped because a sleep alarm is active.
    case cannotHaltDuringSleepAlarm
    case repeatChanged(RepeatMode)
    /// The server couldn't make a track playable.
    case trackUnavailable
    /// The server couldn't be reached, so only downloaded tracks play.
    case serverUnreachable
}

/// The playback position, kept apart from the player so only the views that
/// show it update several times a second.
@MainActor
@Observable
public final class PlaybackProgress {
    /// Seconds into the current track.
    public internal(set) var position: Double = 0
    /// Seconds of the current track that are loaded.
    public internal(set) var buffered: Double = 0
}

/// Settings the player reads while it plays.
public struct PlayerPreferences: Sendable {
    public var useCachingSource = false
    public var linearSleepIn = true
    public var linearWakeUp = true
    public var alarmDeviceVolume = 0.5
    public var startMix = true
    /// Whether a track the server is still downloading plays from its stream
    /// of the download right away.
    public var streamWhileDownloading = false
    /// Seconds a track fades into the next; 0 for none.
    public var crossfade: Double = 0
    /// Whether tracks of one album that follow each other skip the fade.
    public var gaplessAlbums = true
    /// How much the low bass is lifted.
    public var bassBoost = BassBoostLevel.off

    public init() {}
}

/// Plays the queue: streams from the server or plays downloaded files, shows
/// the track on the lock screen, evens out loudness, keeps mixes going and
/// runs sleep alarms.
@MainActor
@Observable
public final class Player {
    public private(set) var queue = PlaybackQueue()
    public private(set) var isPlaying = false
    public private(set) var isBuffering = false
    /// The length of the current track in seconds.
    public private(set) var duration: Double = 0
    /// The volume the user and the sleep alarms set, before the track's gain.
    public private(set) var volume: Double = 1
    /// Whether the queue can be shuffled, which it can't while tracks are
    /// still being fetched into it.
    public private(set) var canShuffle = true
    /// Whether the queue still lists a collection's tracks in their order, so
    /// tapping a track can skip to it instead of restarting the collection.
    public private(set) var queueMatchesCollection = true
    /// IDs of the tracks the server is fetching for playback.
    public private(set) var fetchingTracks: Set<String> = []
    /// The lengths of tracks the server fetched since launch, so lists know
    /// they can play them right away.
    public private(set) var fetchedDurations: [String: Double] = [:]
    /// Entries smart shuffle added to a playlist's queue, which the user can
    /// keep in the playlist.
    public private(set) var suggestedIDs: Set<UUID> = []
    /// The ID of the running sleep alarm, or -1 if none is running.
    public private(set) var activeSleepAlarm = -1

    public let progress = PlaybackProgress()

    @ObservationIgnored public var preferences = PlayerPreferences() {
        didSet {
            BassBoost.shared.level.store(preferences.bassBoost.rawValue, ordering: .relaxed)
            scheduleCrossfade()
        }
    }
    @ObservationIgnored public var onMessage: ((PlayerMessage) -> Void)?
    /// Called when a track starts playing, such as to record it as played.
    @ObservationIgnored public var onTrackStarted: ((QueueItem) -> Void)?
    /// Reports seconds listened to an entry: first once it was listened to
    /// long enough to count as played, with `true`, then every half minute
    /// and when it ends.
    @ObservationIgnored public var onListened: ((QueueItem, Double, Bool) -> Void)?
    // What was listened to of the current entry and not reported yet
    @ObservationIgnored private var listening: Listening?

    private struct Listening {
        var item: QueueItem
        var seconds: Double = 0
        var counted = false
        var lastPosition: Double?
    }
    /// Sets the device volume, for the alarm to wake the user.
    @ObservationIgnored public var setDeviceVolume: ((Double) -> Void)?
    /// Writes a line to the sleep alarm log.
    @ObservationIgnored public var log: ((String) -> Void)?
    /// Takes what the user does to the queue while they listen along with
    /// someone else, returning whether it did; what it doesn't take plays
    /// here alone, such as pausing for a moment.
    @ObservationIgnored public var remote: ((PlayerRequest) -> Bool)?
    /// Called when playback starts, stops, seeks or moves to another entry,
    /// for listeners following this player.
    @ObservationIgnored public var onPlaybackChanged: (() -> Void)?
    /// Who entries the user adds are marked as added by, while listening
    /// together.
    @ObservationIgnored public var addingAs: String?
    // Loads the entry again after a guest's track failed, until it plays
    @ObservationIgnored private var followRetry: Task<Void, Never>?

    @ObservationIgnored private let client: APIClient
    @ObservationIgnored private let socket: TrackSocket
    @ObservationIgnored private let gains: TrackGains
    @ObservationIgnored private let store: KeyValueStore
    @ObservationIgnored private let streamURL: (String, Bool) -> URL?
    @ObservationIgnored private let downloadStreamURL: (String) -> URL?
    // Tracks the server is still downloading, which play from its stream
    @ObservationIgnored private var downloading: Set<String> = []
    // Tracks whose loaded item is the server's stream of their download
    @ObservationIgnored private var streamed: Set<String> = []
    // The track whose stream failed before its download finished
    @ObservationIgnored private var failedStream: String?
    // The track that may start streaming once the server says it downloads it
    @ObservationIgnored private var streamCandidate: String?
    /// Entries that failed to load one after another, so a server that turns
    /// every track away doesn't skip through the whole queue.
    @ObservationIgnored private var failuresInARow = 0
    /// Watches for each loaded item from the server failing, by item.
    @ObservationIgnored private var failureObservations: [ObjectIdentifier: NSKeyValueObservation] = [:]
    @ObservationIgnored private let cacheDirectory: URL
    @ObservationIgnored private let engine = AVQueuePlayer()
    @ObservationIgnored private var loadedCurrent: Loaded?
    @ObservationIgnored private var loadedNext: Loaded?
    @ObservationIgnored private var observations: [NSKeyValueObservation] = []
    @ObservationIgnored private var timeObserver: Any?
    // Incremented whenever a new queue starts, so older fills stop
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var gainFactor = 1.0
    // Crossfades: the end of the previous track plays on in [tail] while the
    // engine fades the next one in
    @ObservationIgnored private let tail = AVPlayer()
    @ObservationIgnored private var tailStid: String?
    @ObservationIgnored private var tailGain = 1.0
    @ObservationIgnored private var tailReady = false
    @ObservationIgnored private var tailObservation: NSKeyValueObservation?
    @ObservationIgnored private var fadeIn = 1.0
    @ObservationIgnored private var crossfadeObserver: Any?
    @ObservationIgnored private var crossfadeTask: Task<Void, Never>?
    @ObservationIgnored private var fadeTask: Task<Void, Never>?
    @ObservationIgnored private var alarmTask: Task<Void, Never>?
    @ObservationIgnored private var blockPlayback = false
    @ObservationIgnored private var artworkTask: Task<Void, Never>?
    /// The mood the mix keeps to, if it was started from one.
    @ObservationIgnored private var mixMood: Mood?
    @ObservationIgnored private lazy var mix = MixRefill(
        fetch: { [weak self] seeds, exclude, count in
            try await self?.fetchMix(seeds: seeds, exclude: exclude, count: count) ?? []
        },
        append: { [weak self] entries in self?.appendMix(entries) })

    /// The entry a track started streaming as, if it did.
    private final class StreamingStart {
        var item: QueueItem?
    }

    private struct Loaded {
        var uid: UUID
        var index: Int
        var item: AVPlayerItem
    }

    /// Creates a player that streams tracks from [streamURL], given a track ID
    /// and whether to use the caching endpoint, and tracks the server is still
    /// downloading from [downloadStreamURL].
    public init(
        client: APIClient, socket: TrackSocket, gains: TrackGains, store: KeyValueStore,
        streamURL: @escaping (String, Bool) -> URL?, downloadStreamURL: @escaping (String) -> URL? = { _ in nil }
    ) {
        self.client = client
        self.socket = socket
        self.gains = gains
        self.store = store
        self.streamURL = streamURL
        self.downloadStreamURL = downloadStreamURL
        cacheDirectory = URL.cachesDirectory.appending(path: "tracks", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        engine.actionAtItemEnd = .advance
        observeEngine()
        setUpRemoteCommands()
        #if os(iOS)
            observeAudioSession()
        #endif
    }

    // MARK: - Starting queues

    /// The current entry, or `nil` when the queue is empty.
    public var current: QueueItem? { queue.current }

    private func startNewQueue() -> Int {
        mix.stop()
        mixMood = nil
        suggestedIDs = []
        generation += 1
        return generation
    }

    private func setFetching(_ stid: String, _ fetching: Bool) {
        if fetching { fetchingTracks.insert(stid) } else { fetchingTracks.remove(stid) }
    }

    private func trackFetched(_ stid: String, _ duration: Double?) {
        if let duration { fetchedDurations[stid] = duration }
    }

    /// Waits until the server can stream the track with [stid] and returns its
    /// length in seconds, or `nil` if it can't get it.
    ///
    /// If [streamingStart] is given and the server has to download the track,
    /// it's called to start playing the download, instead of showing the
    /// track as fetching.
    private func ensureAvailable(_ stid: String, streamingStart: (@MainActor () -> Void)? = nil) async -> Double? {
        streamCandidate = streamingStart == nil ? nil : stid
        let state = await socket.ensureAvailable(stid) { state in
            guard state == .downloading else { return }
            Task { @MainActor in
                if let streamingStart, self.streamCandidate == stid {
                    streamingStart()
                } else {
                    self.setFetching(stid, true)
                }
            }
        }
        streamCandidate = nil
        setFetching(stid, false)
        guard case .ready(let duration) = state else {
            onMessage?(.trackUnavailable)
            return nil
        }
        trackFetched(stid, duration)
        return duration
    }

    private func startQueue(_ items: [QueueItem], index: Int?, shuffle: Bool) {
        queue.setShuffle(shuffle)
        queue.replace(with: items, startingAt: index)
        loadCurrent(autoplay: true)
        canShuffle = true
    }

    /// Plays the catalog [tracks] started from [collectionID].
    ///
    /// [durations] holds the length in seconds of tracks the server already
    /// has; the others are fetched first. Starts at [index], or at a random
    /// track if [shuffle].
    public func playOnline(
        _ collectionID: String, _ tracks: [Track], durations: [String: Double], index: Int? = nil,
        shuffle: Bool = false
    ) async {
        if let remote, remote(.replace(collectionID: collectionID, tracks: tracks, index: index, shuffle: shuffle)) {
            return
        }
        let generation = startNewQueue()
        let known = durations.merging(fetchedDurations) { first, _ in first }
        let missing = tracks.map(\.id).filter { known[$0] == nil }
        if missing.isEmpty {
            startQueue(
                tracks.map { QueueItem(track: $0, collectionID: collectionID, duration: known[$0.id]!) },
                index: index, shuffle: shuffle)
            return
        }
        // Tracks are queued in order while the server fetches the missing ones
        canShuffle = false
        stopEngine()
        queue.clear()
        let batch = await socket.openBatch(missing)
        defer {
            batch.close()
            if generation == self.generation { canShuffle = true }
        }
        var started = false
        for track in tracks {
            guard generation == self.generation else { return }
            var duration = known[track.id]
            if duration == nil, !started, preferences.streamWhileDownloading {
                // The first track plays while the server downloads it
                started = true
                let item = startStreaming(track, collectionID: collectionID)
                duration = await batch.next()
                trackFetched(track.id, duration)
                if !finishStreaming(item, duration: duration, generation: generation) {
                    // The next track that can play starts the queue instead
                    started = false
                }
                continue
            }
            if duration == nil {
                setFetching(track.id, true)
                duration = await batch.next()
                setFetching(track.id, false)
                trackFetched(track.id, duration)
                guard duration != nil, generation == self.generation else { continue }
            }
            let item = QueueItem(track: track, collectionID: collectionID, duration: duration!)
            if started {
                append(item)
            } else {
                started = true
                queue.setShuffle(false)
                queue.replace(with: [item], startingAt: 0)
                loadCurrent(autoplay: true)
            }
        }
    }

    /// Plays the downloaded [tracks] started from [collectionID]; [durations]
    /// holds the length of each in milliseconds.
    public func playOffline(
        _ collectionID: String, _ tracks: [Track], durations: [String: Int], index: Int? = nil,
        shuffle: Bool = false
    ) {
        if let remote, remote(.replace(collectionID: collectionID, tracks: tracks, index: index, shuffle: shuffle)) {
            return
        }
        _ = startNewQueue()
        startQueue(
            tracks.map {
                QueueItem(track: $0, collectionID: collectionID, duration: Double(durations[$0.id] ?? 0) / 1000)
            }, index: index, shuffle: shuffle)
    }

    /// Plays [track] alone, or toggles playback if it's already current, and
    /// queues similar tracks after it if mixes are on.
    public func playSingle(_ track: Track, collectionID: String) async {
        if current?.stid == track.id {
            togglePlayback()
            return
        }
        if let remote, remote(.replace(collectionID: collectionID, tracks: [track], index: 0, shuffle: false)) {
            return
        }
        let generation = startNewQueue()
        canShuffle = true
        let streaming = StreamingStart()
        let start: @MainActor () -> Void = { [weak self] in
            guard let self, generation == self.generation else { return }
            streaming.item = self.startStreaming(track, collectionID: collectionID)
            self.startMixIfWanted()
        }
        let duration = await ensureAvailable(
            track.id, streamingStart: preferences.streamWhileDownloading ? start : nil)
        if let streaming = streaming.item {
            _ = finishStreaming(streaming, duration: duration, generation: generation)
            return
        }
        guard let duration, generation == self.generation else { return }
        queue.replace(with: [QueueItem(track: track, collectionID: collectionID, duration: duration)], startingAt: 0)
        loadCurrent(autoplay: true)
        startMixIfWanted()
    }

    /// Mixes about [count] tracks like those of the shuffled queue of
    /// [collectionID] into it, marked as suggestions.
    public func addSuggestions(to collectionID: String, count: Int) async {
        let generation = self.generation
        guard remote == nil, queue.shuffleEnabled, current?.collectionID == collectionID else { return }
        let stids = queue.items.map(\.stid)
        let seeds = Array(stids.shuffled().prefix(MixRefill.seedCount))
        var added: [String] = []
        // The server sends a few at a time, as it fetches each one
        while added.count < count {
            guard
                let entries = try? await fetchMix(
                    seeds: seeds, exclude: stids + added, count: min(count - added.count, MixRefill.batchSize)),
                !entries.isEmpty, generation == self.generation, queue.shuffleEnabled
            else { return }
            let items = entries.map {
                QueueItem(track: $0.track, collectionID: collectionID, duration: $0.duration, isMix: true)
            }
            queue.insertSuggestions(items)
            suggestedIDs.formUnion(items.map(\.id))
            added += items.map(\.stid)
            refreshNext()
            saveState()
        }
    }

    /// Stops marking the entry with [id] as a suggestion, once it's kept.
    public func keepSuggestion(_ id: UUID) {
        suggestedIDs.remove(id)
        saveState()
    }

    /// Plays [seeds] as a mix, which goes on with similar tracks for as long
    /// as it plays, whatever the mix preference, keeping to [mood] if given.
    public func playMix(
        _ collectionID: String, seeds: [Track], durations: [String: Double] = [:], mood: Mood? = nil
    ) async {
        if let remote, remote(.mix(collectionID: collectionID, seeds: seeds, mood: mood)) { return }
        await playOnline(collectionID, seeds, durations: durations)
        // Another queue may have started while the seeds were fetched
        guard current?.collectionID == collectionID, !mix.isActive else { return }
        mixMood = mood
        queue.setShuffle(false)
        mix.start()
        reportQueueToMix()
    }

    private func startMixIfWanted() {
        guard preferences.startMix else { return }
        queue.setShuffle(false)
        mix.start()
        reportQueueToMix()
    }

    // MARK: - Playing while the server downloads

    /// Starts a queue of just [track], played from the server's download of
    /// it. Its length is filled in once the download ends.
    private func startStreaming(_ track: Track, collectionID: String) -> QueueItem {
        downloading.insert(track.id)
        let item = QueueItem(track: track, collectionID: collectionID, duration: 0)
        queue.setShuffle(false)
        queue.replace(with: [item], startingAt: 0)
        loadCurrent(autoplay: true)
        return item
    }

    /// Ends playing [item] from the server's download, which ended with the
    /// track's [duration], or `nil` if the server couldn't get it. A stream
    /// that failed meanwhile carries on from the library.
    ///
    /// Returns whether the track can play.
    private func finishStreaming(_ item: QueueItem, duration: Double?, generation: Int) -> Bool {
        downloading.remove(item.stid)
        let failed = failedStream == item.stid
        if failed { failedStream = nil }
        guard generation == self.generation else { return false }
        guard let duration else {
            mix.stop()
            stopEngine()
            queue.clear()
            self.duration = 0
            progress.position = 0
            updateNowPlaying()
            return false
        }
        queue.setDuration(duration, of: item.id)
        if current?.id == item.id {
            self.duration = duration
            updateNowPlaying()
            if failed { playCurrentFromLibrary() }
        }
        return true
    }

    /// Handles the current track's stream breaking: it goes on from the
    /// library once the server has it.
    /// Moves on from the current entry when its audio can't load, instead of
    /// stopping the queue: to the next downloaded track if the server can't
    /// be reached, or else to the next track.
    private func itemFailed(_ playerItem: AVPlayerItem) {
        guard let loaded = loadedCurrent, loaded.item === playerItem, let item = current else { return }
        // Following someone, the entry stays: the server may still be fetching it for them
        if remote != nil {
            retryFollowing(item.id)
            return
        }
        if streamed.contains(item.stid) {
            streamFailed(playerItem)
            return
        }
        let offline = Self.isNetworkError(playerItem.error)
        failuresInARow += 1
        if failuresInARow == 1 { onMessage?(offline ? .serverUnreachable : .trackUnavailable) }
        let order = queue.playOrder
        guard let position = queue.position else { return }
        let next = order[(position + 1)...].first { !offline || playsFromDevice(queue.items[$0]) }
        // A server refusing the user fails every track, as do several failing in a row;
        // stopping keeps the entry, which play tries again
        guard let next, !Self.isRefusal(playerItem.error), failuresInARow < 3 else {
            stopEngine()
            updateNowPlaying()
            return
        }
        queue.select(next)
        loadCurrent(autoplay: true)
    }

    /// Whether [error], or one it came from, is the server refusing the
    /// user, as when they're no longer signed in.
    private static func isRefusal(_ error: (any Error)?) -> Bool {
        guard let error = error as NSError? else { return false }
        let description = (error.userInfo[NSLocalizedDescriptionKey] ?? error.userInfo["NSDescription"]) as? String
        if let description, description.contains("HTTP 401") || description.contains("HTTP 403") { return true }
        return error.underlyingErrors.contains { isRefusal($0) }
    }

    /// Whether [error], or one it came from, says the server couldn't be
    /// reached.
    private static func isNetworkError(_ error: (any Error)?) -> Bool {
        guard let error = error as NSError? else { return false }
        let unreachable: Set<Int> = [
            NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorCannotConnectToHost,
            NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed, NSURLErrorTimedOut,
            NSURLErrorInternationalRoamingOff, NSURLErrorDataNotAllowed,
        ]
        if error.domain == NSURLErrorDomain, unreachable.contains(error.code) { return true }
        return error.underlyingErrors.contains { isNetworkError($0) }
    }

    private func streamFailed(_ playerItem: AVPlayerItem) {
        guard let loaded = loadedCurrent, loaded.item === playerItem, let stid = current?.stid,
            streamed.contains(stid)
        else { return }
        if downloading.contains(stid) {
            // The server may not be able to stream it, but still download it
            failedStream = stid
        } else {
            playCurrentFromLibrary()
        }
    }

    private func playCurrentFromLibrary() {
        let position = progress.position
        loadCurrent(autoplay: true)
        seekEngine(to: position)
    }

    /// Handles a tap on the track at [index] of a collection: starts the
    /// collection with [playCollection] unless it's already playing, skips to
    /// the track if the queue still matches the collection, and otherwise
    /// toggles playback.
    public func playCollectionTrack(
        collectionID: String, stid: String, index: Int, playCollection: @MainActor () async -> Void
    ) async {
        guard let current, current.collectionID == collectionID else {
            queueMatchesCollection = true
            await playCollection()
            return
        }
        if current.stid != stid && queue.items.count > index && queueMatchesCollection {
            skip(to: index)
        } else {
            togglePlayback()
        }
    }

    // MARK: - Editing the queue

    private func queueEntry(for track: Track, collectionID: String) async -> QueueItem? {
        if track.isDownloaded {
            return QueueItem(track: track, collectionID: collectionID, duration: 0)
        }
        var duration = fetchedDurations[track.id]
        if duration == nil {
            duration = try? await client.post("get_track_duration", ["stid": .string(track.id)])["duration"]?.double
        }
        if duration == nil { duration = await ensureAvailable(track.id) }
        guard let duration else { return nil }
        return QueueItem(track: track, collectionID: collectionID, duration: duration)
    }

    /// Inserts [track] after the current entry and those queued before it.
    public func addNext(_ track: Track, collectionID: String, by user: String? = nil) async {
        if let remote, remote(.add(track: track, next: true)) { return }
        guard var item = await queueEntry(for: track, collectionID: collectionID) else { return }
        item.isQueued = true
        item.addedBy = user ?? addingAs
        queueMatchesCollection = false
        let wasEmpty = queue.isEmpty
        queue.insertNext(item)
        if wasEmpty { loadCurrent(autoplay: true) } else { refreshNext() }
    }

    /// Appends [track] to the queue.
    public func addLast(_ track: Track, collectionID: String, by user: String? = nil) async {
        if let remote, remote(.add(track: track, next: false)) { return }
        guard var item = await queueEntry(for: track, collectionID: collectionID) else { return }
        item.addedBy = user ?? addingAs
        queueMatchesCollection = false
        append(item)
    }

    private func append(_ item: QueueItem) {
        let wasEmpty = queue.isEmpty
        queue.append(item)
        if wasEmpty { loadCurrent(autoplay: true) } else { refreshNext() }
        reportQueueToMix()
        Task { await gains.prefetch([item.stid]) }
    }

    /// Removes the entries at [indexes] of the queue, except the one playing.
    public func remove(at indexes: [Int]) {
        if let remote, remote(.remove(indexes.filter(queue.items.indices.contains).map { queue.items[$0].id })) {
            return
        }
        for index in indexes.sorted(by: >) { queue.remove(at: index) }
        queueMatchesCollection = false
        reindexLoaded()
        refreshNext()
    }

    /// Whether a mix adds tracks as the queue nears its end.
    public var isMixing: Bool { mix.isActive }

    /// Moves the entry at [index] to play next.
    public func playNext(at index: Int) {
        if let remote, queue.items.indices.contains(index), remote(.playNext(queue.items[index].id)) { return }
        queue.moveNext(index)
        queueMatchesCollection = false
        reindexLoaded()
        refreshNext()
        saveState()
    }

    /// Removes everything after the current entry, and stops a mix adding
    /// more.
    public func clearUpcoming() {
        if let remote, remote(.clearUpcoming) { return }
        mix.stop()
        mixMood = nil
        queue.removeUpcoming()
        suggestedIDs = suggestedIDs.filter { id in queue.items.contains { $0.id == id } }
        queueMatchesCollection = false
        reindexLoaded()
        refreshNext()
        saveState()
    }

    /// Moves entries in play order, as a list's move gives them.
    public func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        if let remote, remote(.move(from: Array(offsets), to: destination)) { return }
        queue.move(fromOffsets: offsets, toOffset: destination)
        queueMatchesCollection = false
        reindexLoaded()
        refreshNext()
    }

    /// Keeps the loaded entries' indexes right after the queue changed.
    private func reindexLoaded() {
        if let uid = loadedCurrent?.uid, let index = queue.items.firstIndex(where: { $0.id == uid }) {
            loadedCurrent?.index = index
        }
        if let uid = loadedNext?.uid, let index = queue.items.firstIndex(where: { $0.id == uid }) {
            loadedNext?.index = index
        }
    }

    // MARK: - Transport

    public func play() {
        if let remote, remote(.play) { return }
        resume()
    }

    private func resume() {
        guard !blockPlayback else {
            onMessage?(.sleepAlarmEnabled)
            return
        }
        guard current != nil else { return }
        if loadedCurrent == nil { loadCurrent(autoplay: false) }
        activateSession()
        engine.play()
        fade(to: volume, steps: 10, every: .milliseconds(50), from: 0)
    }

    public func pause() {
        if let remote, remote(.pause) { return }
        guard !blockPlayback else {
            onMessage?(.sleepAlarmEnabled)
            return
        }
        finishCrossfade()
        let target = volume
        fadeTask?.cancel()
        fadeTask = Task {
            for step in 1...10 {
                applyVolume(target - target * Double(step) / 10)
                try? await Task.sleep(for: .milliseconds(10))
            }
            engine.pause()
            applyVolume(target)
        }
    }

    public func togglePlayback() {
        isPlaying ? pause() : play()
    }

    public func seek(to seconds: Double) {
        if let remote, remote(.seek(seconds)) { return }
        seekEngine(to: seconds)
        onPlaybackChanged?()
    }

    private func seekEngine(to seconds: Double) {
        progress.position = seconds
        engine.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000), toleranceBefore: .zero, toleranceAfter: .zero) {
            [weak self] _ in
            Task { @MainActor in self?.scheduleCrossfade() }
        }
        updateNowPlaying()
    }

    /// Plays the entry at [index] of the queue.
    public func skip(to index: Int) {
        guard queue.items.indices.contains(index) else { return }
        if let remote, remote(.skip(queue.items[index].id)) { return }
        queue.select(index)
        loadCurrent(autoplay: true)
    }

    public func skipToNext() {
        if let remote, remote(.next) { return }
        guard let next = queue.nextIndex(userSkipped: true) else { return }
        skip(to: next)
    }

    /// Restarts the track, or plays the previous entry near its start.
    public func skipToPrevious() {
        if let remote, remote(.previous) { return }
        if progress.position < 5, let previous = queue.previousIndex() {
            skip(to: previous)
        } else {
            seek(to: 0)
        }
    }

    public func setRepeatMode(_ mode: RepeatMode, announce: Bool = true) {
        if let remote, remote(.repeatMode(mode)) { return }
        queue.repeatMode = mode
        refreshNext()
        if announce { onMessage?(.repeatChanged(mode)) }
        saveModes()
    }

    public func cycleRepeatMode() { setRepeatMode(queue.repeatMode.next) }

    public func setShuffle(_ enabled: Bool) {
        if let remote, remote(.shuffle(enabled)) { return }
        guard canShuffle || !enabled else { return }
        if !enabled {
            // Suggestions belong to the shuffle; unshuffled, the playlist plays as it is
            let suggestions = queue.items.indices.filter {
                suggestedIDs.contains(queue.items[$0].id) && $0 != queue.currentIndex
            }
            if !suggestions.isEmpty { remove(at: suggestions) }
        }
        queue.setShuffle(enabled)
        refreshNext()
        reportQueueToMix()
        saveModes()
    }

    /// Sets the player volume, before the track's loudness gain.
    public func setVolume(_ volume: Double) {
        self.volume = volume
        applyVolume(volume)
    }

    /// Stops playback and empties the queue, unless a sleep alarm is running.
    /// Returns whether the player stopped.
    @discardableResult
    public func halt() -> Bool {
        if let remote, remote(.halt) { return true }
        guard activeSleepAlarm == -1 else {
            onMessage?(.cannotHaltDuringSleepAlarm)
            return false
        }
        _ = startNewQueue()
        stopEngine()
        queue.clear()
        failedStream = nil
        duration = 0
        progress.position = 0
        updateNowPlaying()
        return true
    }

    // MARK: - The engine

    private func stopEngine() {
        finishCrossfade()
        fadeTask?.cancel()
        engine.pause()
        engine.removeAllItems()
        failureObservations = [:]
        loadedCurrent = nil
        loadedNext = nil
    }

    private func sourceURL(for item: QueueItem) -> URL? {
        if let path = item.track.audioPath { return URL(filePath: path) }
        if let downloaded = downloadedFile(item.stid) { return downloaded }
        let cached = cacheDirectory.appending(path: "\(item.stid).m4a")
        if FileManager.default.fileExists(atPath: cached.path) { return cached }
        return streamURL(item.stid, preferences.useCachingSource)
    }

    /// The downloaded file of [stid], which plays without the server.
    private func downloadedFile(_ stid: String) -> URL? {
        let file = Downloads.directory.appending(path: "\(stid).m4a")
        return FileManager.default.fileExists(atPath: file.path) ? file : nil
    }

    private func playsFromDevice(_ item: QueueItem) -> Bool {
        sourceURL(for: item)?.isFileURL ?? false
    }

    private func playerItem(for item: QueueItem) -> AVPlayerItem? {
        let stream = downloading.contains(item.stid) ? downloadStreamURL(item.stid) : nil
        if stream != nil { streamed.insert(item.stid) } else { streamed.remove(item.stid) }
        guard let url = stream ?? sourceURL(for: item) else { return nil }
        let playerItem = AVPlayerItem(url: url)
        playerItem.preferredForwardBufferDuration = 30
        if stream == nil { BassBoost.attach(to: playerItem) }
        if !url.isFileURL {
            // Audio the server can't serve, or a server that can't be reached, fails as the item loads
            failureObservations[ObjectIdentifier(playerItem)] =
                playerItem.observe(\.status, options: [.new]) { [weak self] observed, _ in
                    guard observed.status == .failed else { return }
                    Task { @MainActor in self?.itemFailed(observed) }
                }
        }
        return playerItem
    }

    /// Loads the current entry into the engine, replacing what's there.
    private func loadCurrent(autoplay: Bool) {
        stopEngine()
        guard let index = queue.currentIndex, let item = current, let playerItem = playerItem(for: item) else {
            updateNowPlaying()
            return
        }
        loadedCurrent = Loaded(uid: item.id, index: index, item: playerItem)
        engine.insert(playerItem, after: nil)
        refreshNext()
        currentChanged()
        if autoplay {
            activateSession()
            engine.play()
            applyVolume(volume)
        }
    }

    /// Preloads the entry that plays next, so it starts without a gap.
    private func refreshNext() {
        guard let loadedCurrent, engine.items().contains(loadedCurrent.item) else { return }
        let nextIndex = queue.nextIndex(userSkipped: false)
        let wanted = nextIndex.map { queue.items[$0].id }
        // A repeated track needs an item of its own, since one item can't be
        // queued twice
        if let loadedNext, loadedNext.uid == wanted, loadedNext.index == nextIndex,
            loadedNext.item !== loadedCurrent.item
        {
            return
        }
        if let loadedNext { engine.remove(loadedNext.item) }
        loadedNext = nil
        guard let nextIndex, let playerItem = playerItem(for: queue.items[nextIndex]) else { return }
        engine.insert(playerItem, after: loadedCurrent.item)
        loadedNext = Loaded(uid: queue.items[nextIndex].id, index: nextIndex, item: playerItem)
        scheduleCrossfade()
    }

    /// Follows the engine moving on to the preloaded entry.
    private func engineItemChanged() {
        let item = engine.currentItem
        guard item !== loadedCurrent?.item else { return }
        if let next = loadedNext, item === next.item {
            queue.select(next.index)
            loadedCurrent = next
            loadedNext = nil
            // Items that played are done with
            let loaded = Set(engine.items().map(ObjectIdentifier.init))
            failureObservations = failureObservations.filter { loaded.contains($0.key) }
            refreshNext()
            currentChanged()
        }
    }

    private func itemEnded(_ item: AVPlayerItem) {
        guard item === loadedCurrent?.item, loadedNext == nil else { return }
        // The end of a queue that doesn't repeat: back to the start, paused
        if let first = queue.playOrder.first {
            queue.select(first)
            loadCurrent(autoplay: false)
        }
    }

    private func currentChanged() {
        reportListening()
        guard let item = current else { return }
        listening = Listening(item: item)
        duration = item.duration
        progress.position = 0
        progress.buffered = 0
        applyGain(of: item)
        updateNowPlaying()
        loadArtwork(for: item)
        reportQueueToMix()
        onTrackStarted?(item)
        onPlaybackChanged?()
        scheduleCrossfade()
        Task { await gains.prefetch(queue.upcoming.prefix(5).map(\.stid)) }
        cacheIfWanted(item)
    }

    private func observeEngine() {
        observations = [
            engine.observe(\.currentItem, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.engineItemChanged() }
            },
            engine.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
                let status = player.timeControlStatus
                Task { @MainActor in
                    guard let self else { return }
                    let wasPlaying = self.isPlaying
                    self.isPlaying = status != .paused
                    if wasPlaying != self.isPlaying { self.onPlaybackChanged?() }
                    if wasPlaying && !self.isPlaying { self.saveListening() }
                    self.isBuffering = status == .waitingToPlayAtSpecifiedRate
                    self.updateNowPlaying()
                }
            },
        ]
        timeObserver = engine.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 1000), queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated { self?.tick(time) }
        }
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.failedToPlayToEndTimeNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let item = notification.object as? AVPlayerItem else { return }
            MainActor.assumeIsolated { self?.itemFailed(item) }
        }
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let item = notification.object as? AVPlayerItem else { return }
            MainActor.assumeIsolated { self?.itemEnded(item) }
        }
    }

    private func tick(_ time: CMTime) {
        guard let item = engine.currentItem, item === loadedCurrent?.item else { return }
        progress.position = time.seconds.isFinite ? time.seconds : 0
        if progress.position > 0.5 { failuresInARow = 0 }
        countListening()
        if let range = item.loadedTimeRanges.last?.timeRangeValue {
            progress.buffered = range.end.seconds
        }
        let itemDuration = item.duration.seconds
        if itemDuration.isFinite, itemDuration > 0, abs(itemDuration - duration) > 0.5 {
            duration = itemDuration
            updateNowPlaying()
            scheduleCrossfade()
        }
    }

    // MARK: - Listening time

    /// Adds the time played since the last tick; a seek isn't listening.
    private func countListening() {
        guard var listening, listening.item.id == current?.id else { return }
        let position = progress.position
        if let last = listening.lastPosition, isPlaying, position > last, position - last < 1.5 {
            listening.seconds += position - last
        }
        listening.lastPosition = position
        let length = duration > 0 ? duration : listening.item.duration
        let enough = length > 0 ? min(30, length / 2) : 30
        if !listening.counted, listening.seconds >= enough {
            onListened?(listening.item, listening.seconds, true)
            listening.counted = true
            listening.seconds = 0
        } else if listening.counted, listening.seconds >= 30 {
            onListened?(listening.item, listening.seconds, false)
            listening.seconds = 0
        }
        self.listening = listening
    }

    /// Reports the time listened so far, as playback pauses.
    private func saveListening() {
        guard let listening, listening.counted, listening.seconds > 0 else { return }
        onListened?(listening.item, listening.seconds, false)
        self.listening?.seconds = 0
    }

    /// Reports what's left of the entry that played, if it counted.
    private func reportListening() {
        if let listening, listening.counted, listening.seconds > 0 {
            onListened?(listening.item, listening.seconds, false)
        }
        listening = nil
    }

    // MARK: - Crossfades

    /// When the current track starts fading into the next, or `nil` when it
    /// plays to its end: without a crossfade length, a next track, a known
    /// length, during alarms, for streams of downloads, and between tracks of
    /// one album when those play gapless.
    private func crossfadeStart() -> Double? {
        let length = preferences.crossfade
        guard length > 0, activeSleepAlarm == -1, let current, let loadedCurrent, let loadedNext,
            loadedNext.item !== loadedCurrent.item, duration > length * 3
        else { return nil }
        let next = queue.items[loadedNext.index]
        guard !streamed.contains(current.stid), !streamed.contains(next.stid) else { return nil }
        if preferences.gaplessAlbums, let album = current.track.album?.id, !album.isEmpty,
            next.track.album?.id == album
        {
            return nil
        }
        return duration - length
    }

    /// Watches for the moments to load the current track's end and to start
    /// fading.
    private func scheduleCrossfade() {
        if let crossfadeObserver { engine.removeTimeObserver(crossfadeObserver) }
        crossfadeObserver = nil
        // The tail of the track that's fading out keeps playing
        if crossfadeTask == nil, tailStid != nil, tailStid != current?.stid {
            tail.replaceCurrentItem(with: nil)
            tailStid = nil
            tailReady = false
            tailObservation = nil
        }
        guard let start = crossfadeStart() else { return }
        let times = [max(start - 8, 0.1), start].map { NSValue(time: CMTime(seconds: $0, preferredTimescale: 1000)) }
        crossfadeObserver = engine.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            MainActor.assumeIsolated { self?.crossfadeBoundary() }
        }
        // Already past the moment to load the end, such as after a seek
        let position = engine.currentTime().seconds
        if crossfadeTask == nil, let current, tailStid != current.stid, position > start - 8, position < start - 1 {
            prepareTail(of: current, at: start + Self.handoffDelay)
        }
    }

    private func crossfadeBoundary() {
        guard crossfadeTask == nil, let start = crossfadeStart(), let current else { return }
        let position = engine.currentTime().seconds
        if position < start - 0.5 {
            prepareTail(of: current, at: start + Self.handoffDelay)
        } else {
            startCrossfade(at: position, start: start)
        }
    }

    /// How long after the fade's start the engine hands the track over to
    /// [tail], which gives the main thread time to schedule both exactly.
    private static let handoffDelay = 0.4

    /// Loads the track's end into [tail] ahead of time, buffered and ready
    /// at [handoff], so it plays on without a pause.
    private func prepareTail(of item: QueueItem, at handoff: Double) {
        guard let url = sourceURL(for: item) else { return }
        let playerItem = AVPlayerItem(url: url)
        BassBoost.attach(to: playerItem)
        tail.automaticallyWaitsToMinimizeStalling = false
        tail.replaceCurrentItem(with: playerItem)
        tail.volume = 0
        tailStid = item.stid
        tailReady = false
        tailObservation = playerItem.observe(\.status, options: [.initial, .new]) { [weak self] observed, _ in
            guard observed.status == .readyToPlay else { return }
            Task { @MainActor in self?.prerollTail(playerItem, at: handoff) }
        }
    }

    private func prerollTail(_ item: AVPlayerItem, at handoff: Double) {
        guard tail.currentItem === item, !tailReady else { return }
        tailObservation = nil
        tail.seek(to: CMTime(seconds: handoff, preferredTimescale: 1000), toleranceBefore: .zero, toleranceAfter: .zero) {
            [weak self] finished in
            guard finished else { return }
            Task { @MainActor in
                guard let self, self.tail.currentItem === item else { return }
                self.tail.preroll(atRate: 1) { [weak self] ready in
                    Task { @MainActor in
                        guard let self, self.tail.currentItem === item else { return }
                        self.tailReady = ready
                    }
                }
            }
        }
    }

    /// Starts [tail] on the audio clock at the moment the engine reaches the
    /// handoff point and moves the engine on to the next track then, so the
    /// end plays on seamlessly; then fades one out as the other comes in.
    private func startCrossfade(at position: Double, start: Double) {
        // Without its end ready in time, the track plays to its end as usual
        guard let current, tailStid == current.stid, tailReady else { return }
        let wait = start + Self.handoffDelay - position
        guard wait > 0.05 else { return }
        let length = preferences.crossfade - Self.handoffDelay
        tailGain = gainFactor
        tail.volume = Float(min(volume * tailGain, 1))
        let hostTime = CMTimeAdd(
            CMClockGetTime(CMClockGetHostTimeClock()), CMTime(seconds: wait, preferredTimescale: 1_000_000_000))
        tail.setRate(1, time: .invalid, atHostTime: hostTime)
        crossfadeTask = Task {
            // A hair late rather than early: a few doubled milliseconds can't be
            // heard, a gap can
            try? await Task.sleep(for: .seconds(wait + 0.02))
            if Task.isCancelled { return }
            fadeIn = 0
            applyVolume(volume)
            engine.advanceToNextItem()
            // Equal power, so the sum stays as loud as either track
            let steps = max(Int(length * 20), 1)
            for step in 1...steps {
                try? await Task.sleep(for: .milliseconds(50))
                if Task.isCancelled { return }
                let progress = Double(step) / Double(steps)
                fadeIn = sin(progress * .pi / 2)
                tail.volume = Float(min(volume * tailGain * cos(progress * .pi / 2), 1))
                applyVolume(volume)
            }
            crossfadeTask = nil
            finishCrossfade()
        }
    }

    /// Stops a crossfade or the end loaded for one, leaving the engine at full
    /// volume.
    private func finishCrossfade() {
        crossfadeTask?.cancel()
        crossfadeTask = nil
        tail.pause()
        tail.replaceCurrentItem(with: nil)
        tailStid = nil
        tailReady = false
        tailObservation = nil
        guard fadeIn != 1 else { return }
        fadeIn = 1
        applyVolume(volume)
    }

    // MARK: - Volume

    private func applyVolume(_ level: Double) {
        engine.volume = Float(min(max(level * gainFactor * fadeIn, 0), 1))
    }

    private func fade(to target: Double, steps: Int, every interval: Duration, from start: Double) {
        fadeTask?.cancel()
        fadeTask = Task {
            for step in 1...steps {
                applyVolume(start + (target - start) * Double(step) / Double(steps))
                try? await Task.sleep(for: interval)
                if Task.isCancelled { return }
            }
        }
    }

    private func applyGain(of item: QueueItem) {
        Task {
            let gain = await gains.gain(for: item.stid)
            // The queue may have moved on while the gain was looked up
            guard current?.id == item.id else { return }
            gainFactor = gain.map { pow(10, $0 / 20) } ?? 1
            applyVolume(volume)
        }
    }

    // MARK: - Mixes

    /// Tells the mix where playback is, in play order.
    private func reportQueueToMix() {
        guard mix.isActive else { return }
        mix.update(queue: queue.playOrder.map { queue.items[$0].stid }, position: queue.position)
    }

    private func fetchMix(seeds: [String], exclude: [String], count: Int) async throws -> [MixEntry] {
        var request: [String: JSONValue] = [
            "seeds": JSONValue(seeds), "exclude": JSONValue(exclude), "count": .int(count),
        ]
        if let mixMood { request["mood"] = .string(mixMood.rawValue) }
        let response = try await client.post("next_mix_tracks", request)
        guard let tracks = response["tracks"]?.array else { throw APIError.malformed("next_mix_tracks") }
        return tracks.compactMap { entry in
            guard let track = entry["track"].flatMap(Track.init(json:)), let duration = entry["duration"]?.double
            else { return nil }
            return MixEntry(track: track, duration: duration)
        }
    }

    private func appendMix(_ entries: [MixEntry]) {
        queueMatchesCollection = false
        for entry in entries {
            append(QueueItem(track: entry.track, collectionID: "online.mix", duration: entry.duration, isMix: true))
        }
    }

    // MARK: - Caching

    private func cacheIfWanted(_ item: QueueItem) {
        guard preferences.useCachingSource, !item.track.isDownloaded,
            let url = streamURL(item.stid, true)
        else { return }
        let file = cacheDirectory.appending(path: "\(item.stid).m4a")
        guard !FileManager.default.fileExists(atPath: file.path) else { return }
        Task.detached(priority: .background) {
            guard let (temporary, response) = try? await URLSession.shared.download(from: url),
                (response as? HTTPURLResponse)?.statusCode == 200
            else { return }
            try? FileManager.default.moveItem(at: temporary, to: file)
        }
    }

    /// Forgets the cached audio and loudness of the track with [stid], after
    /// the server changed which recording it plays.
    public func forgetAudio(of stid: String) async {
        try? FileManager.default.removeItem(at: cacheDirectory.appending(path: "\(stid).m4a"))
        await gains.forget(stid)
    }

    /// Deletes the cached tracks.
    public func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Sleep alarms

    /// Starts [alarm]: fades the music out and, if set, wakes the user later.
    ///
    /// Playback never stops between falling asleep and waking up: iOS
    /// suspends a backgrounded app once its audio stops, which would keep the
    /// alarm from ever firing. While waiting, the music plays at volume 0.
    public func startSleepAlarm(_ alarm: SleepAlarm) {
        log?("start \(alarm), playing \(isPlaying), volume \(volume)")
        alarmTask?.cancel()
        activeSleepAlarm = alarm.id
        if queue.repeatMode == .off { setRepeatMode(.all) }
        onMessage?(.keepAppOpen)
        alarmTask = Task { await runSleepAlarm(alarm) }
    }

    /// Stops the running sleep alarm and pauses playback.
    public func stopSleepAlarm() {
        if activeSleepAlarm != -1 { log?("stopped by the user") }
        activeSleepAlarm = -1
        alarmTask?.cancel()
        blockPlayback = false
        engine.pause()
        setVolume(1)
    }

    private func runSleepAlarm(_ alarm: SleepAlarm) async {
        if alarm.sleep {
            activateSession()
            engine.play()
            let step = Duration.milliseconds(alarm.sleepDuration * 60 * 1000 / 100)
            var level = volume
            while level > 0 {
                try? await Task.sleep(for: step)
                if Task.isCancelled { return }
                guard engine.timeControlStatus != .paused else { continue }
                level = SleepSchedule.step(level, down: true, linear: preferences.linearSleepIn)
                setVolume(level)
            }
            log?("asleep")
            guard alarm.alarmClock else {
                engine.pause()
                setVolume(1)
                activeSleepAlarm = -1
                return
            }
        }
        guard alarm.alarmClock else { return }
        await waitToWakeUp(alarm)
    }

    /// Keeps playing silently until the fade in of [alarm] is due, then fades
    /// the music in.
    private func waitToWakeUp(_ alarm: SleepAlarm) async {
        let (fadeInAt, fadeIn) = SleepSchedule.wakeUp(alarm, now: Date())
        log?("fade in at \(fadeInAt) for \(fadeIn) s")
        blockPlayback = true
        setVolume(0)
        activateSession()
        engine.play()
        var lastHeartbeat = Date()
        // Check the clock instead of waiting once: the system can pause the
        // app for a moment, which makes timers fire late
        while Date() < fadeInAt {
            try? await Task.sleep(for: .seconds(5))
            if Task.isCancelled || activeSleepAlarm != alarm.id { return }
            if Date().timeIntervalSince(lastHeartbeat) >= 900 {
                lastHeartbeat = Date()
                log?("waiting, playing \(isPlaying)")
            }
            // Keep the app alive if something like a call paused the music
            if engine.timeControlStatus == .paused {
                log?("restarting paused music")
                engine.play()
            }
        }
        log?("waking up")
        blockPlayback = false
        engine.play()
        setDeviceVolume?(preferences.alarmDeviceVolume)
        var level = 0.0
        let step = Duration.milliseconds(Int(fadeIn * 1000) / 100)
        while level < 1 {
            level = SleepSchedule.step(level, down: false, linear: preferences.linearWakeUp)
            setVolume(level)
            try? await Task.sleep(for: step)
            if Task.isCancelled { return }
        }
        log?("awake")
        activeSleepAlarm = -1
    }

    // MARK: - Lock screen and Control Center

    private func setUpRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        func handle(_ command: MPRemoteCommand, _ action: @escaping @MainActor (Player) -> Void) {
            // Hops instead of assuming the main thread, which MediaPlayer
            // doesn't promise
            command.addTarget { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    action(self)
                }
                return .success
            }
        }
        handle(center.playCommand) { $0.play() }
        handle(center.pauseCommand) { $0.pause() }
        handle(center.togglePlayPauseCommand) { $0.togglePlayback() }
        handle(center.nextTrackCommand) { $0.skipToNext() }
        handle(center.previousTrackCommand) { $0.skipToPrevious() }
        handle(center.stopCommand) { $0.halt() }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let position = event.positionTime
            Task { @MainActor in self?.seek(to: position) }
            return .success
        }
    }

    @ObservationIgnored private var artwork: (stid: String, artwork: MPMediaItemArtwork)?

    private func updateNowPlaying() {
        let center = MPNowPlayingInfoCenter.default()
        guard let item = current else {
            center.nowPlayingInfo = nil
            center.playbackState = .stopped
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: item.track.name,
            MPMediaItemPropertyArtist: item.track.artistNames,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: progress.position,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyPlaybackQueueIndex: queue.position ?? 0,
            MPNowPlayingInfoPropertyPlaybackQueueCount: queue.items.count,
        ]
        if let album = item.track.album?.name { info[MPMediaItemPropertyAlbumTitle] = album }
        if let artwork, artwork.stid == item.stid { info[MPMediaItemPropertyArtwork] = artwork.artwork }
        center.nowPlayingInfo = info
        center.playbackState = isPlaying ? .playing : .paused
    }

    private func loadArtwork(for item: QueueItem) {
        artworkTask?.cancel()
        guard artwork?.stid != item.stid, let url = item.track.coverURL else { return }
        artworkTask = Task {
            let data: Data? =
                url.isFileURL ? try? Data(contentsOf: url) : try? await URLSession.shared.data(from: url).0
            guard let data, let artwork = PlatformArtwork.make(data), !Task.isCancelled else { return }
            self.artwork = (item.stid, artwork)
            updateNowPlaying()
        }
    }

    // MARK: - Audio session

    private func activateSession() {
        #if os(iOS)
            try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    #if os(iOS)
        private func observeAudioSession() {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
            ) { [weak self] notification in
                let info = notification.userInfo
                let type = (info?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(
                    AVAudioSession.InterruptionType.init)
                let options = AVAudioSession.InterruptionOptions(
                    rawValue: info?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
                MainActor.assumeIsolated {
                    guard let self else { return }
                    if self.activeSleepAlarm != -1 {
                        self.log?("interruption \(type == .began ? "began" : "ended")")
                    }
                    if type == .ended, options.contains(.shouldResume) { self.engine.play() }
                }
            }
        }
    #endif

    // MARK: - Listening together

    /// Exactly how far into the current track the engine is.
    public var exactPosition: Double {
        let seconds = engine.currentTime().seconds
        return seconds.isFinite ? seconds : 0
    }

    /// Takes on the queue someone else plays, keeping the entry that plays
    /// here if it's still current in it.
    public func follow(_ snapshot: PlaybackQueue.Snapshot) {
        _ = startNewQueue()
        var snapshot = snapshot
        // Their downloads are on their device; here the tracks play from the server
        snapshot.items = snapshot.items.map { item in
            var item = item
            item.track.audioPath = nil
            item.track.localImagePath = nil
            return item
        }
        queue.restore(snapshot)
        canShuffle = true
        queueMatchesCollection = false
        if let uid = loadedCurrent?.uid, uid == current?.id {
            reindexLoaded()
            refreshNext()
        } else {
            loadCurrent(autoplay: false)
        }
        saveState()
    }

    /// Plays the entry with [entry] from [position], or pauses it, as
    /// someone else's player does; small differences in position stay.
    public func follow(entry: UUID, position: Double, playing: Bool, tolerance: Double = 0.25) {
        guard let index = queue.items.firstIndex(where: { $0.id == entry }) else { return }
        if loadedCurrent?.uid != entry || queue.currentIndex != index {
            followRetry?.cancel()
            queue.select(index)
            loadCurrent(autoplay: false)
            seekEngine(to: position)
            if playing { resume() }
            return
        }
        if abs(exactPosition - position) > tolerance { seekEngine(to: position) }
        if playing && !isPlaying {
            resume()
        } else if !playing && isPlaying {
            engine.pause()
        }
    }

    /// Pauses here only, while following someone.
    public func pauseHere() {
        engine.pause()
    }

    private func retryFollowing(_ entry: UUID) {
        followRetry?.cancel()
        followRetry = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let self, self.remote != nil, self.current?.id == entry else { return }
            self.loadCurrent(autoplay: self.isPlaying)
            self.onPlaybackChanged?()
        }
    }

    // MARK: - Saving the queue

    /// Saves the queue, position and modes so the next launch can resume.
    public func saveState() {
        var snapshot = queue.snapshot(position: progress.position)
        snapshot.mixActive = mix.isActive
        snapshot.mixMood = mixMood
        snapshot.suggested = Array(suggestedIDs)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        store.set(String(decoding: data, as: UTF8.self), for: .queue)
    }

    private func saveModes() {
        store.set(queue.repeatMode.rawValue, for: .loopMode)
        store.set(queue.shuffleEnabled, for: .shuffleMode)
    }

    /// Restores the queue saved by [saveState], paused where it was.
    public func restoreState() {
        if let mode = store.string(.loopMode).flatMap(RepeatMode.init) { queue.repeatMode = mode }
        guard let text = store.string(.queue),
            let snapshot = try? JSONDecoder().decode(PlaybackQueue.Snapshot.self, from: Data(text.utf8))
        else { return }
        queue.restore(snapshot)
        guard !queue.isEmpty else { return }
        let ids = Set(queue.items.map(\.id))
        suggestedIDs = Set(snapshot.suggested ?? []).intersection(ids)
        loadCurrent(autoplay: false)
        seekEngine(to: snapshot.position)
        // A mix goes on where it was, keeping to its mood
        if snapshot.mixActive == true {
            mixMood = snapshot.mixMood
            mix.start()
            reportQueueToMix()
        }
    }
}

#if os(iOS)
    import UIKit

    enum PlatformArtwork {
        static func make(_ data: Data) -> MPMediaItemArtwork? {
            guard let image = UIImage(data: data) else { return nil }
            return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
    }
#else
    import AppKit

    enum PlatformArtwork {
        static func make(_ data: Data) -> MPMediaItemArtwork? {
            guard let image = NSImage(data: data) else { return nil }
            return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
    }
#endif
