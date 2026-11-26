import Foundation
import Testing

@testable import PongoCore

/// Answers requests from the handler tests set, recording each one's method.
final class FakeServer: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (URLRequest) -> (Int, Data) = { _ in (404, Data()) }
    nonisolated(unsafe) static var methods: [String] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.methods.append("\(request.httpMethod ?? "GET") \(request.url?.path ?? "")")
        let (status, data) = Self.handler(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite(.serialized)
struct DownloadAudioTests {
    private func downloads(_ handler: @escaping (URLRequest) -> (Int, Data)) throws -> DownloadsRepository {
        FakeServer.handler = handler
        FakeServer.methods = []
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FakeServer.self]
        let session = URLSession(configuration: configuration)
        let client = APIClient(config: AppConfig(serverURL: "https://pongo.example/", googleClientID: ""), session: session)
        return DownloadsRepository(
            client: client, socket: TrackSocket(client: client), database: try Database(), session: session,
            audioURL: { URL(string: "https://pongo.example/play_song/\($0)?st=token") })
    }

    @Test func downloadsTheAudioTheWayThePlayerStreamsIt() async throws {
        let repository = try downloads { request in
            // The proxy only sends files for GET
            request.httpMethod == "GET" ? (200, Data("audio".utf8)) : (405, Data())
        }
        #expect(try await repository.fetchAudio("42") == Data("audio".utf8))
        #expect(FakeServer.methods == ["GET /play_song/42"])
    }

    @Test func fallsBackToThePostWhenTheStreamIsRefused() async throws {
        let repository = try downloads { request in
            request.httpMethod == "GET" ? (403, Data()) : (200, Data("audio".utf8))
        }
        #expect(try await repository.fetchAudio("42") == Data("audio".utf8))
        #expect(FakeServer.methods == ["GET /play_song/42", "POST /download_track/42"])
    }

    @Test func anEmptyAnswerIsNoDownload() async throws {
        let repository = try downloads { _ in (200, Data()) }
        await #expect(throws: APIError.self) { try await repository.fetchAudio("42") }
    }

    @MainActor @Test func manyDownloadsFinishEachOnceWithoutCrashing() async throws {
        // Nothing listens there, so each track fails at once, the fastest the group sees them finish
        let client = APIClient(config: AppConfig(serverURL: "http://127.0.0.1:9/", googleClientID: ""))
        let repository = DownloadsRepository(client: client, socket: TrackSocket(client: client), database: try Database())
        let tracks = (0..<25).map { (track: Track(id: "\($0)", name: "Song \($0)", artists: [], album: nil), cover: String?.none) }
        let finished = FinishedTracks()
        await #expect(throws: (any Error).self) {
            try await repository.downloadAll(tracks) { stid, saved in finished.add(stid, saved) }
        }
        #expect(finished.stids.sorted() == tracks.map { $0.track.id }.sorted())
        #expect(!finished.anySaved)
    }

    @Test func downloadedLengthsAreKnownWithoutTheServer() async throws {
        let database = try Database()
        try await database.addDownload(
            stid: "7", audioPath: "/x/7.m4a", artists: [], title: "Seven", durationMilliseconds: 183_500, imagePath: nil)
        #expect(try await database.downloadedDurations(["7", "8"]) == ["7": 183.5])
        try await database.setDownloadDuration("7", milliseconds: 200_000)
        #expect(try await database.downloadedDurations(["7"]) == ["7": 200])
    }
}

@MainActor
final class FinishedTracks {
    var stids: [String] = []
    var anySaved = false

    func add(_ stid: String, _ saved: Bool) {
        stids.append(stid)
        anySaved = anySaved || saved
    }
}

struct WebSocketCallTests {
    @Test func aRefusedSocketThrowsInsteadOfHanging() async {
        let task = URLSession.shared.webSocketTask(with: URL(string: "ws://127.0.0.1:9/devices")!)
        task.resume()
        await #expect(throws: (any Error).self) { _ = try await task.receiveOnce() }
        await #expect(throws: (any Error).self) { try await task.sendOnce(.string("{}")) }
    }

    @Test func onlyTheFirstAnswerCounts() async {
        let once = Once()
        let claimed = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<200 { group.addTask { once.claim() } }
            var count = 0
            for await won in group where won { count += 1 }
            return count
        }
        #expect(claimed == 1)
    }
}

/// Many downloads against a fake server on this machine
/// (`PONGO_FAKE_SERVER=http://127.0.0.1:8765/`), run under the sanitizers to
/// catch the races and memory errors a phone only shows as a crash.
@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["PONGO_FAKE_SERVER"] != nil))
struct DownloadStressTests {
    @MainActor @Test func manyDownloadsAtOnceAgainstAServer() async throws {
        let server = ProcessInfo.processInfo.environment["PONGO_FAKE_SERVER"]!
        let folder = URL.temporaryDirectory.appending(path: "pongo-stress-\(UUID().uuidString)")
        Downloads.testDirectory = folder
        defer {
            Downloads.testDirectory = nil
            try? FileManager.default.removeItem(at: folder)
        }
        for round in 0..<5 {
            let client = APIClient(config: AppConfig(serverURL: server, googleClientID: ""))
            let database = try Database()
            let repository = DownloadsRepository(
                client: client, socket: TrackSocket(client: client), database: database,
                audioURL: { URL(string: "\(server)play_song/\($0)?st=x") })
            let tracks = (0..<40).map {
                (track: Track(id: "\(round)\($0)", name: "Song \($0)", artists: [], album: nil), cover: String?.none)
            }
            let finished = FinishedTracks()
            #expect(try await repository.downloadAll(tracks) { stid, saved in finished.add(stid, saved) })
            #expect(finished.stids.count == 40)
            #expect(try await database.missingDownloads(tracks.map { $0.track.id }).isEmpty)
        }
    }
}
