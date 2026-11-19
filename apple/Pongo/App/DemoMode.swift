#if DEBUG
    import PongoCore
    import SwiftUI

    /// Sample content for looking at the UI in the simulator without signing
    /// in. Debug builds only, and only when launched with `-PongoDemo`;
    /// `-PongoDemoScreen` then opens `player`, `lyrics`, `queue`, `library`
    /// or `settings`, and `-PongoDemoPosition` jumps that many seconds into
    /// the song.
    enum DemoMode {
        static let isOn = ProcessInfo.processInfo.arguments.contains("-PongoDemo")

        static var screen: String? { arguments(after: "-PongoDemoScreen") }

        /// The launch argument that follows [flag].
        private static func arguments(after flag: String) -> String? {
            let arguments = ProcessInfo.processInfo.arguments
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }

        private static let songs: [(name: String, artist: String, album: String, seconds: Double, colors: [UIColor])] = [
            ("Blinding Lights", "The Weeknd", "After Hours", 200, [.systemRed, .black]),
            ("Levitating", "Dua Lipa", "Future Nostalgia", 203, [.systemPink, .systemPurple]),
            ("Bohemian Rhapsody", "Queen", "A Night at the Opera", 355, [.systemIndigo, .systemTeal]),
            ("Heat Waves", "Glass Animals", "Dreamland", 238, [.systemOrange, .systemPurple]),
            ("Bad Guy", "Billie Eilish", "When We All Fall Asleep, Where Do We Go?", 194, [.systemGreen, .black]),
            ("Take On Me", "a-ha", "Hunting High and Low", 225, [.systemBlue, .white]),
        ]

        /// Puts the sample tracks in the queue before the player restores it,
        /// and into the favourites and a playlist.
        static func seed(store: DefaultsStore, database: Database) {
            let tracks = songs.enumerated().map { index, song in
                Track(
                    id: "demo\(index)", name: song.name, artists: [ArtistRef(id: "artist\(index)", name: song.artist)],
                    album: AlbumRef(id: "", name: song.album, images: []),
                    localImagePath: cover(index, song.colors).path)
            }
            let items = zip(tracks, songs).map { track, song in
                QueueItem(track: track, collectionID: "library.favourites", duration: song.seconds)
            }
            guard let encoded = try? JSONEncoder().encode(items),
                let itemsJSON = try? JSONSerialization.jsonObject(with: encoded)
            else { return }
            let snapshot: [String: Any] = [
                "items": itemsJSON, "currentIndex": 0, "shuffleEnabled": false, "shuffleOrder": [Int](),
                "repeatMode": "all", "position": 62.0,
            ]
            if let data = try? JSONSerialization.data(withJSONObject: snapshot) {
                store.set(String(decoding: data, as: UTF8.self), for: .queue)
            }
            // A home page, as if saved from the server
            let covers = songs.indices.map { cover($0, songs[$0].colors).absoluteString }
            var feed = HomeFeed()
            feed.history = tracks + tracks.prefix(3).map { track in
                var track = track
                track.id += "-again"
                return track
            }
            feed.newReleases = zip(songs, covers).enumerated().map { index, pair in
                Album(id: "album\(index)", name: pair.0.album, type: "album", artists: [pair.0.artist], image: pair.1)
            }
            feed.topTracks = (0..<12).map { tracks[$0 % tracks.count] }.enumerated().map { index, track in
                var track = track
                track.id += "-top\(index)"
                return track
            }
            feed.topArtists = zip(songs, covers).enumerated().map { index, pair in
                Artist(id: "artist\(index)", name: pair.0.artist, image: pair.1)
            }
            feed.categories = ["Pop", "Rap/Hip Hop", "Rock", "Dance"].enumerated().map { index, name in
                BrowseCategory(id: "\(index)", name: name, iconURL: covers[index])
            }
            HomeCache.save(feed)
            // Enough favourites to scroll
            let favourites = (0..<4).flatMap { copy in
                tracks.map { track in
                    var track = track
                    track.id += "-\(copy)"
                    return track
                }
            }
            Task {
                guard (try? await database.favouriteCount()) == 0 else { return }
                for track in favourites { try? await database.addFavourite(Favourite(track: track)) }
                if let id = try? await database.createOnlinePlaylist("Road trip", cover: nil) {
                    for track in tracks.prefix(4) {
                        _ = try? await database.addOnlineTrack(OnlinePlaylistTrack(opid: id, track: track))
                    }
                }
            }
        }

        /// With `-PongoDemoScrolled`, lists open scrolled to their end, to see
        /// what lies under the bars.
        static let scrolled = ProcessInfo.processInfo.arguments.contains("-PongoDemoScrolled")

        /// With `-PongoDemoMiddle`, lists open scrolled to their middle.
        static let middle = ProcessInfo.processInfo.arguments.contains("-PongoDemoMiddle")

        /// Moods for the sample tracks, as the server would have measured them.
        static func moods(for tracks: [Track]) -> [String: TrackMood] {
            var moods: [String: TrackMood] = [:]
            for (index, id) in Array(Set(tracks.map(\.id))).sorted().enumerated() {
                moods[id] = TrackMood(
                    mood: Mood.allCases[index % 4], tempo: 120, energy: 0.5, valence: 0.5, danceability: 0.5)
            }
            return moods
        }

        /// Opens the screen asked for once the UI is up.
        static func open(_ model: AppModel) {
            if model.recents.items.isEmpty, let album = HomeCache.load()?.newReleases.first {
                model.recents.add(.album(album))
            }
            switch screen {
            case "player": model.router.showsPlayer = true
            case "lyrics":
                model.nowPlaying.lyricsOn = true
                model.router.showsPlayer = true
                // Into the song, so a line is being sung
                if let seconds = arguments(after: "-PongoDemoPosition").flatMap(Double.init) {
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        model.player.seek(to: seconds)
                    }
                }
            case "card":
                model.nowPlaying.lyricsOn = true
                model.router.showsPlayer = true
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    let lines = model.nowPlaying.syncedLines.map(\.text)
                    model.nowPlaying.shareLyrics(lines, at: min(6, max(lines.count - 1, 0)), item: model.player.current)
                }
            case "queue":
                model.nowPlaying.showsQueue = true
                model.router.showsPlayer = true
            case "library": model.router.tab = .library
            case "favourites":
                model.router.tab = .library
                model.router.library = [.favourites]
            case "settings": model.router.tab = .settings
            case "preferences":
                model.router.tab = .settings
                model.router.settings = [.preferences]
            case "sleep":
                model.router.tab = .library
                model.router.library = [.sleepAlarms]
            default: break
            }
        }

        /// A gradient cover written to the caches directory.
        private static func cover(_ index: Int, _ colors: [UIColor]) -> URL {
            let url = URL.cachesDirectory.appending(path: "demo-cover-\(index).png")
            if FileManager.default.fileExists(atPath: url.path) { return url }
            let size = CGSize(width: 600, height: 600)
            let image = UIGraphicsImageRenderer(size: size).image { context in
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map(\.cgColor) as CFArray,
                    locations: [0, 1])!
                context.cgContext.drawLinearGradient(
                    gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
                let text = NSAttributedString(
                    string: "♪", attributes: [.font: UIFont.systemFont(ofSize: 260, weight: .bold),
                                             .foregroundColor: UIColor.white.withAlphaComponent(0.85)])
                text.draw(at: CGPoint(x: 190, y: 120))
            }
            try? image.pngData()?.write(to: url)
            return url
        }
    }
#endif
