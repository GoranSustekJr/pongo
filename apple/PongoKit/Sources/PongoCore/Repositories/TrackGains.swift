import Foundation

/// Loudness gains of tracks, in decibels, so tracks play about equally loud.
///
/// Gains are kept in memory and in the database, so downloaded tracks keep
/// theirs offline, and fetched from the server for the rest.
public actor TrackGains {
    private let client: APIClient
    private let database: Database
    private var gains: [String: Double] = [:]
    private var unknownUntil: [String: Date] = [:]

    static let batchSize = 500
    // Tracks the server doesn't have yet aren't asked about again before this
    static let retryAfter: TimeInterval = 60

    public init(client: APIClient, database: Database) {
        self.client = client
        self.database = database
    }

    /// The gain of the track with [stid], or `nil` if it isn't known.
    public func gain(for stid: String) async -> Double? {
        if gains[stid] == nil { await prefetch([stid]) }
        return gains[stid]
    }

    /// Looks up the gains of [stids] that aren't known yet.
    public func prefetch(_ stids: [String]) async {
        let now = Date()
        let missing = Array(Set(stids.filter { gains[$0] == nil && !(unknownUntil[$0].map { $0 > now } ?? false) }))
        guard !missing.isEmpty else { return }
        gains.merge((try? await database.trackGains(missing)) ?? [:]) { $1 }
        let remote = missing.filter { gains[$0] == nil }
        for start in stride(from: 0, to: remote.count, by: Self.batchSize) {
            let batch = Array(remote[start..<min(start + Self.batchSize, remote.count)])
            if let response = try? await client.post("track_gains", ["stids": JSONValue(batch)]) {
                var fetched: [String: Double] = [:]
                for (stid, value) in response["gains"]?.object ?? [:] {
                    if let gain = value.double { fetched[stid] = gain }
                }
                gains.merge(fetched) { $1 }
                try? await database.saveTrackGains(fetched)
            }
            for stid in batch where gains[stid] == nil {
                unknownUntil[stid] = now.addingTimeInterval(Self.retryAfter)
            }
        }
    }
}
