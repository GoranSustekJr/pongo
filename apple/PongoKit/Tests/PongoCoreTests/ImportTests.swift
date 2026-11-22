import Foundation
import Testing

@testable import PongoCore

@Suite struct ImportFileTests {
    @Test func readsSpotifyPlaylistsWithLocalFilesAndWithoutEpisodes() {
        let json = """
            {"playlists": [
              {"name": "Road trip", "items": [
                {"track": {"trackName": "Song", "artistName": "Artist", "albumName": "Album", "trackUri": "spotify:track:1"},
                 "episode": null, "localTrack": null},
                {"track": null, "episode": {"episodeName": "Talk"}, "localTrack": null},
                {"track": null, "episode": null, "localTrack": {"uri": "spotify:local:Some+Band:LP:Kava+%C5%A1alica:215"}}
              ]},
              {"name": "", "items": []}
            ]}
            """
        let playlists = ImportFiles.playlists(in: Data(json.utf8), named: "Playlist1.json")
        #expect(playlists.count == 1)
        #expect(playlists[0].name == "Road trip")
        #expect(playlists[0].skipped == 1)
        #expect(playlists[0].songs == [
            ImportSong(title: "Song", artists: ["Artist"], album: "Album"),
            ImportSong(title: "Kava šalica", artists: ["Some Band"], album: "LP", durationMs: 215_000),
        ])
    }

    @Test func likedSongsBecomeFavourites() {
        let json = #"{"tracks": [{"artist": "A", "album": "B", "track": "C", "uri": "spotify:track:1"}], "albums": []}"#
        let playlists = ImportFiles.playlists(in: Data(json.utf8), named: "YourLibrary.json")
        #expect(playlists.map(\.destination) == [.favourites])
        #expect(playlists[0].songs == [ImportSong(title: "C", artists: ["A"], album: "B")])
    }

    @Test func readsExporterCSVsGroupedByPlaylist() {
        let csv = [
            "Track Name,Artist Name(s),Album Name,Duration (ms),ISRC,Playlist Name",
            #""Hello, World","A,B",Album,200000,USUG11904206,Mix"#,
            #""Say ""Hi""",C,,,,Other"#,
            "Plain,D,,,,Mix",
            "",
        ].joined(separator: "\r\n")
        let playlists = ImportFiles.playlists(in: Data(csv.utf8), named: "export.csv")
        #expect(playlists.map(\.name) == ["Mix", "Other"])
        #expect(playlists[0].songs[0] == ImportSong(
            title: "Hello, World", artists: ["A", "B"], album: "Album", durationMs: 200_000, isrc: "USUG11904206"))
        #expect(playlists[0].songs[1].title == "Plain")
        #expect(playlists[1].songs[0].title == "Say \"Hi\"")
    }

    @Test func readsTheMusicAppsTextExport() {
        let text = "Name\tArtist\tComposer\tAlbum\tTime\nCesarica\tOliver Dragojević\t\tVjeruj u ljubav\t245\n"
        var data = Data([0xFF, 0xFE])
        data.append(text.data(using: .utf16LittleEndian)!)
        let playlists = ImportFiles.playlists(in: data, named: "Klapa.txt")
        #expect(playlists.map(\.name) == ["Klapa"])
        #expect(playlists[0].songs == [
            ImportSong(title: "Cesarica", artists: ["Oliver Dragojević"], album: "Vjeruj u ljubav", durationMs: 245_000)
        ])
    }

    @Test func understandsDurations() {
        #expect(ImportFiles.milliseconds("3:25") == 205_000)
        #expect(ImportFiles.milliseconds("1:02:03") == 3_723_000)
        #expect(ImportFiles.milliseconds("245") == 245_000)
        #expect(ImportFiles.milliseconds("245000") == 245_000)
        #expect(ImportFiles.milliseconds("x") == nil)
    }

    @Test func aTableWithoutTitlesHasNoPlaylists() {
        #expect(ImportFiles.playlists(in: Data("a,b\n1,2\n".utf8), named: "x.csv").isEmpty)
    }
}

/// Finds songs whose title starts with "ok", as catalog tracks named after them.
private final class FakeMatcher: SongMatching, @unchecked Sendable {
    private let lock = NSLock()
    private var _asked: [ImportSong] = []
    var asked: [ImportSong] { lock.withLock { _asked } }

    func match(_ songs: [ImportSong]) async throws -> [SongMatch] {
        lock.withLock { _asked += songs }
        return songs.map { song in
            song.title.hasPrefix("ok")
                ? SongMatch(track: Track(id: "id-\(song.title)", name: song.title, artists: [], album: nil), score: 1)
                : SongMatch(track: nil, score: 0.5, alternatives: [Track(id: "alt", name: "Alt", artists: [], album: nil)])
        }
    }
}

@Suite struct PlaylistImporterTests {
    private func song(_ title: String) -> ImportSong { ImportSong(title: title, artists: ["A"]) }

    @Test func importsIntoNewPlaylistsAndListsWhatWasntFound() async throws {
        let database = try Database()
        let matcher = FakeMatcher()
        let importer = PlaylistImporter(database: database, matcher: matcher)
        let first = ImportPlaylist(name: "One", source: .spotify, songs: [song("ok1"), song("nope"), song("ok2")])
        let second = ImportPlaylist(name: "Two", source: .appleMusic, songs: [song("ok1"), song("ok1")])

        let outcomes = try await importer.run([first, second])

        #expect(matcher.asked.count == 3)
        #expect(outcomes[0].added == 2)
        #expect(outcomes[0].unmatched.map(\.position) == [1])
        #expect(outcomes[0].unmatched[0].alternatives.map(\.id) == ["alt"])
        #expect(outcomes[1].added == 1 && outcomes[1].alreadyThere == 1)
        let playlists = try await database.onlinePlaylists()
        #expect(Set(playlists.map(\.title)) == ["One", "Two"])
        let tracks = try await database.onlineTracks(try #require(outcomes[0].opid))
        #expect(tracks.map(\.stid) == ["id-ok1", "id-ok2"])
    }

    @Test func importingAgainOnlyAddsWhatsNew() async throws {
        let database = try Database()
        let importer = PlaylistImporter(database: database, matcher: FakeMatcher())
        _ = try await importer.run([ImportPlaylist(name: "Mix", source: .spotify, songs: [song("ok1")])])
        let again = try await importer.run([
            ImportPlaylist(name: "Mix", source: .spotify, songs: [song("ok1"), song("ok3")])
        ])
        #expect(again[0].merged && again[0].added == 1 && again[0].alreadyThere == 1)
        #expect(try await database.onlinePlaylists().count == 1)
        #expect(try await database.onlineTracks(try #require(again[0].opid)).map(\.stid) == ["id-ok1", "id-ok3"])
    }

    @Test func likedSongsGoToFavouritesAndNothingEmptyIsCreated() async throws {
        let database = try Database()
        let importer = PlaylistImporter(database: database, matcher: FakeMatcher())
        let outcomes = try await importer.run([
            ImportPlaylist(name: "Liked", source: .spotify, songs: [song("ok1")], destination: .favourites),
            ImportPlaylist(name: "Nothing found", source: .spotify, songs: [song("no")]),
        ])
        #expect(outcomes[0].added == 1)
        #expect(try await database.favourites().map(\.stid) == ["id-ok1"])
        #expect(outcomes[1].opid == nil && outcomes[1].unmatched.count == 1)
        #expect(try await database.onlinePlaylists().isEmpty)
    }
}

@Suite struct ChoosingSongsTests {
    private func song(_ title: String) -> ImportSong { ImportSong(title: title, artists: ["A"]) }

    @Test func aPickedSongGoesWhereItWas() async throws {
        let database = try Database()
        let importer = PlaylistImporter(database: database, matcher: FakeMatcher())
        let playlist = ImportPlaylist(name: "Mix", source: .spotify, songs: [song("ok1"), song("lost"), song("ok2")])
        let outcome = try await importer.run([playlist])[0]
        let picked = Track(id: "picked", name: "Picked", artists: [], album: nil)

        let after = try await importer.choose(picked, for: outcome.unmatched[0], in: outcome)

        #expect(after.unmatched.isEmpty && after.added == 3)
        #expect(try await database.onlineTracks(try #require(after.opid)).map(\.stid) == ["id-ok1", "picked", "id-ok2"])
    }

    @Test func pickingTheOnlySongMakesThePlaylist() async throws {
        let database = try Database()
        let importer = PlaylistImporter(database: database, matcher: FakeMatcher())
        let outcome = try await importer.run([ImportPlaylist(name: "Lost", source: .spotify, songs: [song("lost")])])[0]
        #expect(outcome.opid == nil)
        let picked = Track(id: "picked", name: "Picked", artists: [], album: nil)
        let after = try await importer.choose(picked, for: outcome.unmatched[0], in: outcome)
        #expect(try await database.onlinePlaylists().map(\.title) == ["Lost"])
        #expect(try await database.onlineTracks(try #require(after.opid)).map(\.stid) == ["picked"])
    }
}

@Suite struct ExporterFileTests {
    @Test func readsTuneMyMusicFiles() {
        let csv = [
            "Track name,Artist name,Album,Playlist name,Type,ISRC,Spotify - id",
            "Minut' srca tvog,Magazin,Best Of,Ljeto,Playlist,HRA019800123,4uLU6hMCjMI75M1A2tKUQC",
            "Cesarica,Oliver Dragojević,Cesarica,Ljeto,Playlist,,1",
        ].joined(separator: "\n")
        let playlists = ImportFiles.playlists(in: Data(csv.utf8), named: "My Spotify Library.csv")
        #expect(playlists.map(\.name) == ["Ljeto"])
        #expect(playlists[0].songs[0] == ImportSong(
            title: "Minut' srca tvog", artists: ["Magazin"], album: "Best Of", isrc: "HRA019800123"))
        #expect(playlists[0].songs.count == 2)
    }

    @Test func readsExportifyFiles() {
        let csv = [
            #""Track URI","Track Name","Artist URI(s)","Artist Name(s)","Album URI","Album Name","Album Artist URI(s)","Album Artist Name(s)","Album Release Date","Disc Number","Track Number","Track Duration (ms)","Explicit","Popularity","ISRC""#,
            #""spotify:track:1","Uptown Funk (feat. Bruno Mars)","spotify:artist:1,spotify:artist:2","Mark Ronson,Bruno Mars","spotify:album:1","Uptown Special","spotify:artist:1","Mark Ronson","2015-01-12","1","4","269733","false","80","GBARL1401524""#,
        ].joined(separator: "\n")
        let playlists = ImportFiles.playlists(in: Data(csv.utf8), named: "dance_mix.csv")
        #expect(playlists.map(\.name) == ["dance_mix"])
        #expect(playlists[0].songs == [
            ImportSong(
                title: "Uptown Funk (feat. Bruno Mars)", artists: ["Mark Ronson", "Bruno Mars"], album: "Uptown Special",
                durationMs: 269_733, isrc: "GBARL1401524")
        ])
    }
}
