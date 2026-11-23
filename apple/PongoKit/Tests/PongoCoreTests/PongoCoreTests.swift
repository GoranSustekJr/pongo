import Foundation
import Testing

@testable import PongoCore

private func item(_ stid: String) -> QueueItem {
    QueueItem(track: Track(id: stid, name: stid, artists: [], album: nil), collectionID: "test.list", duration: 60)
}

@Suite struct PlaybackQueueTests {
    @Test func playsInOrderAndRepeats() {
        var queue = PlaybackQueue()
        queue.replace(with: ["a", "b", "c"].map(item), startingAt: 1)
        #expect(queue.current?.stid == "b")
        #expect(queue.nextIndex(userSkipped: false) == 2)
        queue.select(2)
        #expect(queue.nextIndex(userSkipped: false) == 0)
        queue.repeatMode = .off
        #expect(queue.nextIndex(userSkipped: false) == nil)
        queue.repeatMode = .one
        #expect(queue.nextIndex(userSkipped: false) == 2)
        #expect(queue.nextIndex(userSkipped: true) == 0)
    }

    @Test func shuffleKeepsTheCurrentEntryFirst() {
        var queue = PlaybackQueue()
        queue.replace(with: (0..<20).map { item("\($0)") }, startingAt: 7)
        queue.setShuffle(true)
        #expect(queue.shuffleOrder.first == 7)
        #expect(queue.shuffleOrder.sorted() == Array(0..<20))
        #expect(queue.position == 0)
    }

    @Test func insertNextPlaysRightAfterTheCurrentEntry() {
        var queue = PlaybackQueue()
        queue.replace(with: (0..<10).map { item("\($0)") }, startingAt: 3)
        queue.setShuffle(true)
        queue.insertNext(item("next"))
        let next = queue.nextIndex(userSkipped: true)!
        #expect(queue.items[next].stid == "next")
        #expect(queue.current?.stid == "3")
        #expect(queue.shuffleOrder.sorted() == Array(0..<11))
    }

    @Test func suggestionsSpreadThroughTheRestOfTheShuffle() {
        var queue = PlaybackQueue()
        queue.replace(with: (0..<12).map { item("\($0)") }, startingAt: 0)
        queue.setShuffle(true)
        queue.insertSuggestions(["s1", "s2", "s3"].map(item))
        let order = queue.playOrder.map { queue.items[$0].stid }
        let slots = order.indices.filter { order[$0].hasPrefix("s") }
        #expect(order.count == 15)
        #expect(Set(queue.shuffleOrder) == Set(0..<15))
        #expect(queue.current?.stid == "0")
        // Never right after the current entry, never two in a row
        #expect(slots.first! >= 2)
        #expect(zip(slots, slots.dropFirst()).allSatisfy { $1 - $0 > 1 })
    }

    @Test func savedQueuesKeepTheirMixAndLoadOlderOnes() throws {
        var queue = PlaybackQueue()
        queue.replace(with: ["a", "b"].map(item), startingAt: 0)
        var snapshot = queue.snapshot(position: 12)
        snapshot.mixActive = true
        snapshot.mixMood = .chill
        snapshot.suggested = [queue.items[1].id]
        let saved = try JSONDecoder().decode(
            PlaybackQueue.Snapshot.self, from: try JSONEncoder().encode(snapshot))
        #expect(saved.mixMood == .chill && saved.mixActive == true)
        #expect(saved.items.map(\.id) == queue.items.map(\.id))
        #expect(saved.suggested == [queue.items[1].id])
        // Queues saved before mixes were kept have none of it
        var older = try JSONSerialization.jsonObject(with: try JSONEncoder().encode(snapshot)) as! [String: Any]
        for key in ["mixActive", "mixMood", "suggested"] { older[key] = nil }
        let old = try JSONDecoder().decode(
            PlaybackQueue.Snapshot.self, from: try JSONSerialization.data(withJSONObject: older))
        #expect(old.mixActive == nil && old.items.count == 2)
    }

    @Test func entriesQueuedNextPlayInTheOrderTheyWereQueued() {
        for shuffled in [false, true] {
            var queue = PlaybackQueue()
            queue.replace(with: ["a", "b", "c", "d"].map(item), startingAt: 0)
            queue.setShuffle(shuffled)
            for stid in ["x", "y"] {
                var entry = item(stid)
                entry.isQueued = true
                queue.insertNext(entry)
            }
            let order = queue.playOrder.map { queue.items[$0].stid }
            #expect(Array(order.prefix(3)) == ["a", "x", "y"])
            #expect(queue.queuedCount == 2)
            // Moving an entry up puts it after those queued
            queue.moveNext(queue.items.firstIndex { $0.stid == order.last! }!)
            #expect(Array(queue.playOrder.map { queue.items[$0].stid }.prefix(4)) == ["a", "x", "y", order.last!])
            queue.removeUpcoming()
            #expect(queue.items.map(\.stid) == ["a"] && queue.playOrder == [0])
        }
    }

    @Test func removingKeepsTheCurrentEntry() {
        var queue = PlaybackQueue()
        queue.replace(with: ["a", "b", "c", "d"].map(item), startingAt: 2)
        queue.remove(at: 0)
        queue.remove(at: 1)
        #expect(queue.items.map(\.stid) == ["b", "c", "d"])
        #expect(queue.current?.stid == "c")
    }

    @Test func movingFollowsTheCurrentEntry() {
        var queue = PlaybackQueue()
        queue.replace(with: ["a", "b", "c"].map(item), startingAt: 0)
        queue.move(fromOffsets: [0], toOffset: 3)
        #expect(queue.items.map(\.stid) == ["b", "c", "a"])
        #expect(queue.current?.stid == "a")
    }
}

@Suite struct ModelTests {
    @Test func picksImageSizes() {
        let images = [
            ImageRef(url: "small", height: 64, width: 64), ImageRef(url: "big", height: 640, width: 640),
            ImageRef(url: "medium", height: 300, width: 300),
        ]
        #expect(images.bestURL == "big")
        #expect(images.url(forWidth: 150, height: 150) == "medium")
        #expect(images.url(forWidth: 1000, height: 1000) == "big")
    }

    @Test func parsesSyncedLyrics() {
        let lyrics = Lyrics(plain: "", synced: "[00:01.50] One\n[00:10.00][01:00.00] Chorus\n[00:05.25]Two")
        #expect(lyrics.syncedLines.map(\.text) == ["One", "Two", "Chorus", "Chorus"])
        #expect(lyrics.syncedLines.map(\.time) == [1.5, 5.25, 10, 60])
    }

    @Test func parsesTracksWithNumericIDs() throws {
        let json = try JSONValue.decode(
            Data(#"{"id": 3135556, "name": "Song", "artists": [{"id": 27, "name": "Daft Punk"}]}"#.utf8))
        let track = try #require(Track(json: json))
        #expect(track.id == "3135556")
        #expect(track.artistNames == "Daft Punk")
    }

    @Test func schedulesTheWakeUp() {
        var alarm = SleepAlarm()
        alarm.wakeTime = 7 * 60
        alarm.beforeEndTimeMin = 30
        let calendar = Calendar(identifier: .gregorian)
        let evening = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 23))!
        let early = SleepSchedule.wakeUp(alarm, now: evening, calendar: calendar)
        #expect(early.fadeIn == 1800)
        #expect(early.fadeInAt == calendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 6, minute: 30)))
        let late = calendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 6, minute: 50))!
        let rushed = SleepSchedule.wakeUp(alarm, now: late, calendar: calendar)
        #expect(rushed.fadeInAt == late)
        #expect(rushed.fadeIn == 600)
    }
}

@Suite struct DatabaseTests {
    @Test func togglesFavourites() async throws {
        let database = try Database()
        let favourite = Favourite(stid: "1", title: "Song", artists: [ArtistRef(id: "2", name: "Artist")], album: nil, image: nil)
        #expect(try await database.toggleFavourite(favourite))
        #expect(try await database.favourites().first?.artists.first?.name == "Artist")
        #expect(try await !database.toggleFavourite(favourite))
        #expect(try await database.favouriteCount() == 0)
    }

    @Test func keepsTheLatestHistoryFirst() async throws {
        let database = try Database()
        for stid in ["a", "b", "a"] { try await database.addPlayedTrack(stid) }
        #expect(try await database.playedTracks() == ["a", "b"])
    }

    @Test func syncsPlaylistsInTheFlutterFormat() async throws {
        let database = try Database()
        let opid = try await database.createOnlinePlaylist("Mine", cover: Data([1, 2, 3]))
        try await database.addOnlineTrack(
            OnlinePlaylistTrack(opid: opid, stid: "9", title: "Song", artists: [], album: nil, image: "x"))
        let snapshot = try await database.snapshot()
        let (key, playlist) = try #require(snapshot.first { $0.key.kind == "online_playlist" })
        #expect(playlist.data?["title"] == "Mine")
        #expect(playlist.data?["cover"] == .string(Data([1, 2, 3]).base64EncodedString()))
        #expect(playlist.data?["tracks"]?[0]?["stid"] == "9")
        #expect(playlist.data?["tracks"]?[0]?["hidden"] == false)

        // Applying the item on another device recreates the playlist
        let other = try Database()
        try await other.apply(key, playlist.data)
        #expect(try await other.onlinePlaylists().first?.title == "Mine")
        #expect(try await other.onlineTracks(other.onlinePlaylists()[0].id).map(\.stid) == ["9"])
        #expect(try await LibrarySync.hash(other.item(key).data) == LibrarySync.hash(playlist.data))

        try await other.apply(key, nil)
        #expect(try await other.onlinePlaylistCount() == 0)
    }

    @Test func syncsSleepAlarms() async throws {
        let database = try Database()
        var alarm = SleepAlarm()
        alarm.alarmClock = true
        _ = try await database.addSleepAlarm(alarm)
        let (key, item) = try #require(try await database.snapshot().first { $0.key.kind == "sleep_alarm" })
        let other = try Database()
        try await other.apply(key, item.data)
        #expect(try await other.sleepAlarms().first?.alarmClock == true)
    }
}

@MainActor
@Suite struct MixRefillTests {
    @Test func fetchesWhenTheQueueIsNearlyDone() async throws {
        var requests: [[String]] = []
        var appended: [String] = []
        let refill = MixRefill(
            fetch: { seeds, _, _ in
                requests.append(seeds)
                return [MixEntry(track: Track(id: "new", name: "", artists: [], album: nil), duration: 1)]
            },
            append: { entries in
                // The player changes its queue here, which has to be on the main thread
                #expect(Thread.isMainThread)
                appended += entries.map(\.track.id)
            })
        refill.start()
        refill.update(queue: ["a", "b", "c", "d", "e"], position: 0)
        try await Task.sleep(for: .milliseconds(50))
        #expect(requests.isEmpty)
        refill.update(queue: ["a", "b", "c", "d", "e"], position: 2)
        try await Task.sleep(for: .milliseconds(50))
        #expect(requests == [["c", "b", "a"]])
        #expect(appended == ["new"])
    }
}

@Suite struct ListenTogetherTests {
    /// The server reads a request's kind from its only key.
    @Test func requestsEncodeAsTheirKind() throws {
        let requests: [(PlayerRequest, String)] = [
            (.pause, "pause"), (.seek(12), "seek"), (.skip(UUID()), "skip"),
            (.add(track: item("1").track, next: true), "add"), (.move(from: [2], to: 0), "move"),
            (.repeatMode(.one), "repeatMode"),
            (.replace(collectionID: "c", tracks: [], index: nil, shuffle: false), "replace"),
        ]
        for (request, kind) in requests {
            let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
            #expect(object.map { Array($0.keys) } == [kind])
            #expect(try JSONDecoder().decode(PlayerRequest.self, from: JSONEncoder().encode(request)) == request)
        }
    }

    @Test func presetsMatchTheirRights() {
        #expect(ListenPreset.matching([]) == .listenAlong)
        #expect(ListenPreset.matching([.add, .vote]) == .party)
        #expect(ListenPreset.matching(Set(ListenRight.allCases)) == .coPilot)
        #expect(ListenPreset.matching([.add, .playback]) == nil)
    }

    @Test func entriesKeepWhoAddedThem() throws {
        var entry = item("1")
        entry.addedBy = "friend"
        let decoded = try JSONDecoder().decode(QueueItem.self, from: JSONEncoder().encode(entry))
        #expect(decoded.addedBy == "friend")
    }
}

@Suite struct BassBoostTests {
    /// The filter's gain in dB at [frequency], from its coefficients.
    private func gain(_ c: [Double], at frequency: Double, rate: Double) -> Double {
        let w = 2 * Double.pi * frequency / rate
        func magnitude(_ a: Double, _ b: Double, _ c: Double) -> Double {
            let re = a + b * cos(w) + c * cos(2 * w)
            let im = -(b * sin(w) + c * sin(2 * w))
            return sqrt(re * re + im * im)
        }
        return 20 * log10(magnitude(c[0], c[1], c[2]) / magnitude(1, c[3], c[4]))
    }

    @Test func liftsOnlyTheLowBass() {
        for shelf in BassBoost.shelves {
            let c = BassBoost.coefficients(shelf, sampleRate: 44_100)
            // The full lift well below the corner, none well above it
            #expect(abs(gain(c, at: 20, rate: 44_100) - (shelf.gainDB + shelf.headroomDB)) < 0.6)
            #expect(abs(gain(c, at: 3_000, rate: 44_100) - shelf.headroomDB) < 0.1)
            #expect(abs(gain(c, at: 10_000, rate: 44_100) - shelf.headroomDB) < 0.05)
        }
        #expect(BassBoost.shelves[0].gainDB == 8)
    }

    @MainActor @Test func theOldSwitchBecomesTheLowLevel() {
        let store = MemoryStore()
        store.set(true, for: .bassBoost)
        #expect(SettingsRepository(store: store).settings.bassBoost == .low)
        store.set(3, for: .bassBoostLevel)
        #expect(SettingsRepository(store: store).settings.bassBoost == .high)
    }
}

@Suite struct PlayStatsTests {
    private func track(_ id: String, artist: String) -> Track {
        Track(id: id, name: id, artists: [ArtistRef(id: artist, name: artist)], album: nil)
    }

    @Test func countsPlaysPerMonthAcrossDevices() async throws {
        let database = try Database()
        let november = Date(timeIntervalSince1970: 1_794_000_000)
        let month = Database.month(of: november)
        try await database.recordListen(track("a", artist: "x"), seconds: 30, newPlay: true, at: november)
        try await database.recordListen(track("a", artist: "x"), seconds: 90, newPlay: false, at: november)
        try await database.recordListen(track("b", artist: "y"), seconds: 30, newPlay: true, at: november)
        // Another device's count of the same song, as a sync brings it
        try await database.apply(
            SyncKey(kind: "play_count", key: "\(month)|other|a"),
            ["plays": .int(2), "seconds": .double(400), "track": .object(["id": "a", "name": "a", "artists": []])])
        let stats = try await database.monthStats(month)
        #expect(stats.tracks.map(\.id) == ["a", "b"])
        #expect(stats.tracks.first?.plays == 3)
        #expect(stats.tracks.first?.seconds == 520)
        #expect(stats.plays == 4)
        #expect(stats.artists.map(\.id) == ["x", "y"])
        #expect(try await database.playMonths() == [month])
        // This device's counts go out to the others
        let snapshot = try await database.snapshot()
        #expect(snapshot.keys.filter { $0.kind == "play_count" }.count == 3)
    }

    @Test func addsUpTheYearByMonth() async throws {
        let database = try Database()
        let calendar = Calendar.current
        let march = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let may = calendar.date(from: DateComponents(year: 2026, month: 5, day: 10))!
        let lastYear = calendar.date(from: DateComponents(year: 2025, month: 12, day: 10))!
        try await database.recordListen(track("a", artist: "x"), seconds: 60, newPlay: true, at: march)
        try await database.recordListen(track("a", artist: "x"), seconds: 60, newPlay: true, at: may)
        try await database.recordListen(track("b", artist: "y"), seconds: 30, newPlay: true, at: may)
        try await database.recordListen(track("c", artist: "z"), seconds: 30, newPlay: true, at: lastYear)
        let year = try await database.yearStats("2026")
        #expect(year.total.plays == 3)
        #expect(year.total.tracks.map(\.id) == ["a", "b"])
        #expect(year.months.map(\.month) == ["2026-03", "2026-05"])
        #expect(year.months.map(\.plays) == [1, 2])
        #expect(try await database.playYears() == ["2026", "2025"])
    }
}

@Suite struct AccountLibraryTests {
    @Test func signingOutClearsTheLibraryButNotDownloads() async throws {
        let database = try Database()
        let track = Track(id: "1", name: "One", artists: [], album: nil)
        try await database.recordListen(track, seconds: 40, newPlay: true)
        try await database.addPlayedTrack("1")
        try await database.addFavourite(Favourite(stid: "1", title: "One", artists: [], album: nil, image: nil))
        try await database.setLibraryOwner("a")
        try await database.execute("INSERT INTO downloaded_tracks (stid) VALUES ('9')")
        try await database.clearLibrary()
        #expect(try await database.playMonths().isEmpty)
        #expect(try await database.playedTracks().isEmpty)
        #expect(try await database.favourites().isEmpty)
        #expect(try await database.libraryOwner() == nil)
        #expect(try await database.countRows("downloaded_tracks") == 1)
    }

    @MainActor @Test func readsTheAccountFromItsToken() {
        let store = TestStore()
        // {"uid":"user-42"} as a token's payload; the signature isn't checked here
        store.set("x.eyJ1aWQiOiJ1c2VyLTQyIn0.y", for: .accessToken)
        let auth = AuthRepository(client: APIClient(config: AppConfig(serverURL: "http://x", googleClientID: "")), store: store)
        #expect(auth.accountID == "user-42")
    }
}

extension Database {
    func execute(_ sql: String) throws { try db.execute(sql) }
    func countRows(_ table: String) throws -> Int { try count("SELECT COUNT(*) FROM \(table)") }
}

private final class TestStore: KeyValueStore, @unchecked Sendable {
    private var values: [StorageKey: String] = [:]
    func string(_ key: StorageKey) -> String? { values[key] }
    func set(_ value: String?, for key: StorageKey) { values[key] = value }
}

@Suite struct JoinLinkTests {
    @MainActor @Test func readsTheCodeFromALink() {
        #expect(ListeningSession.code(in: URL(string: "pongo://join/ab12cd")!) == "AB12CD")
        #expect(ListeningSession.code(in: URL(string: "pongo://lyrics")!) == nil)
        #expect(ListeningSession.code(in: URL(string: "https://join/AB12CD")!) == nil)
    }
}

@Suite struct ServerAddressesTests {
    @Test func startsOnTheFirstAddressAndSkipsEmptyOnes() {
        let config = AppConfig(
            serverURL: "https://pongo.example:48129", fallbackServerURLs: ["", "https://192.168.1.2:9090/"],
            googleClientID: "")
        #expect(config.servers.all == ["https://pongo.example:48129/", "https://192.168.1.2:9090/"])
        #expect(config.serverURL == "https://pongo.example:48129/")
        #expect(config.socketURL == "wss://pongo.example:48129/")
    }

    @Test func keepsTheCurrentAddressWhenNoneAnswers() async {
        let config = AppConfig(
            serverURL: "http://127.0.0.1:9/", fallbackServerURLs: ["http://127.0.0.1:7/"], googleClientID: "")
        await config.servers.choose()
        #expect(config.serverURL == "http://127.0.0.1:9/")
    }

    @Test func switchesToAnotherServer() {
        let config = AppConfig(serverURL: "https://a.example/", fallbackServerURLs: ["http://10.0.0.2:8081/"], googleClientID: "")
        config.servers.replace(with: ["http://192.168.1.10:8081"])
        #expect(config.servers.all == ["http://192.168.1.10:8081/"])
        #expect(config.socketURL == "ws://192.168.1.10:8081/")
    }

    @Test func readsTypedAddresses() {
        #expect(ServerInfo.normalize("192.168.1.10") == "http://192.168.1.10:8081/")
        #expect(ServerInfo.normalize(" 192.168.1.10:9000 ") == "http://192.168.1.10:9000/")
        #expect(ServerInfo.normalize("my-mac.local") == "http://my-mac.local:8081/")
        #expect(ServerInfo.normalize("pongo.example.com") == "https://pongo.example.com/")
        #expect(ServerInfo.normalize("pongo.duckdns.org:48129") == "https://pongo.duckdns.org:48129/")
        #expect(ServerInfo.normalize("HTTP://10.0.0.5:8081") == "http://10.0.0.5:8081/")
        #expect(ServerInfo.normalize("http://10.0.0.5") == "http://10.0.0.5/")
        #expect(ServerInfo.normalize("https://box.tail1234.ts.net/pongo") == "https://box.tail1234.ts.net/pongo/")
        #expect(ServerInfo.normalize("") == nil)
        #expect(ServerInfo.normalize("not an address") == nil)
        #expect(ServerInfo.normalize("ftp://x.example") == nil)
    }
}

@Suite struct LibraryChangeTests {
    @Test func onlyLibraryChangesAskForASync() async throws {
        let database = try Database()
        let start = await database.changeCount()
        // Listening, history and the sync's own records wait for the regular sync
        let track = Track(id: "a", name: "a", artists: [], album: nil)
        try await database.recordListen(track, seconds: 30, newPlay: true)
        try await database.addPlayedTrack("a")
        try await database.setCursor(42)
        #expect(await database.changeCount() == start)

        let favourite = Favourite(stid: "1", title: "Song", artists: [], album: nil, image: nil)
        #expect(try await database.toggleFavourite(favourite))
        #expect(await database.changeCount() > start)
    }
}
