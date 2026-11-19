import FoundationModels
import PongoCore
import SwiftUI

extension Mood {
    var title: String {
        switch self {
        case .chill: L10n.moodchill
        case .happy: L10n.moodhappy
        case .energetic: L10n.moodenergetic
        case .party: L10n.moodparty
        case .intense: L10n.moodintense
        case .melancholy: L10n.moodmelancholy
        }
    }

    var systemImage: String {
        switch self {
        case .chill: "leaf.fill"
        case .happy: "sun.max.fill"
        case .energetic: "bolt.fill"
        case .party: "party.popper.fill"
        case .intense: "flame.fill"
        case .melancholy: "cloud.rain.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .chill: [Color(red: 0.2, green: 0.7, blue: 0.65), Color(red: 0.2, green: 0.25, blue: 0.6)]
        case .happy: [Color(red: 1, green: 0.78, blue: 0.2), Color(red: 0.95, green: 0.45, blue: 0.25)]
        case .energetic: [Color(red: 1, green: 0.55, blue: 0.1), Color(red: 0.85, green: 0.15, blue: 0.3)]
        case .party: [Color(red: 1, green: 0.3, blue: 0.65), Color(red: 0.5, green: 0.2, blue: 0.85)]
        case .intense: [Color(red: 0.85, green: 0.1, blue: 0.15), Color(red: 0.2, green: 0.05, blue: 0.1)]
        case .melancholy: [Color(red: 0.4, green: 0.5, blue: 0.75), Color(red: 0.15, green: 0.15, blue: 0.3)]
        }
    }
}

/// The user's songs of one mood, which play as a mix that keeps to it.
struct MoodMix: Identifiable {
    let mood: Mood
    let tracks: [Track]
    /// A name the on-device model gave the mix, if it could.
    var name: String?

    var id: Mood { mood }
    var collectionID: String { "mix.mood.\(mood.rawValue)" }

    /// The artists with the most songs in the mix, most first.
    var artists: [String] {
        let names = tracks.compactMap { $0.artists.first?.name }
        let counts = Dictionary(names.map { ($0, 1) }, uniquingKeysWith: +)
        return counts.sorted { ($0.value, $1.key) > ($1.value, $0.key) }.map(\.key)
    }

    var covers: [URL] {
        var seen = Set<URL>()
        return tracks.compactMap { $0.coverURL(size: 150) }.filter { seen.insert($0).inserted }.prefix(3).map { $0 }
    }

    /// A mix for each mood with at least three of [tracks], the biggest
    /// first.
    static func make(tracks: [Track], moods: [String: TrackMood]) -> [MoodMix] {
        var seen = Set<String>()
        let unique = tracks.filter { seen.insert($0.id).inserted }
        let grouped = Dictionary(grouping: unique.filter { moods[$0.id] != nil }) { moods[$0.id]!.mood }
        return grouped.filter { $0.value.count >= 3 }
            .sorted { ($0.value.count, $1.key.rawValue) > ($1.value.count, $0.key.rawValue) }
            .map { MoodMix(mood: $0.key, tracks: $0.value) }
    }
}

/// Names mood mixes after what's in them with the on-device model, on
/// iPhones that have Apple Intelligence. Names are kept, so a mix keeps its
/// name until its artists change.
enum MoodNamer {
    @Generable
    struct MixName {
        @Guide(description: "A catchy playlist name of two to four words, without quotes or emoji")
        var name: String
    }

    private static let storeKey = "moodMixNames"

    static func names(for mixes: [MoodMix], locale: String) async -> [Mood: String] {
        var stored = UserDefaults.standard.dictionary(forKey: storeKey) as? [String: String] ?? [:]
        var names: [Mood: String] = [:]
        let model = SystemLanguageModel.default
        let wanted = Locale.Language(identifier: locale)
        let language = model.supportedLanguages.contains { $0.languageCode == wanted.languageCode }
            ? wanted : Locale.Language(identifier: "en")
        let languageName = Locale(identifier: "en").localizedString(forLanguageCode: language.languageCode?.identifier ?? "en") ?? "English"
        for mix in mixes {
            let artists = mix.artists.prefix(4)
            let key = "\(language.languageCode?.identifier ?? "en")|\(mix.mood.rawValue)|\(artists.joined(separator: ","))"
            if let name = stored[key] {
                names[mix.mood] = name
                continue
            }
            guard model.availability == .available else { continue }
            let session = LanguageModelSession(
                instructions: """
                    You name music playlists. Names are short, evocative and specific to the music, \
                    like "Late-Night Synthpop" or "Adriatic Sunset Ballads". Answer in \(languageName).
                    """)
            let songs = mix.tracks.prefix(8).map { "\($0.name) by \($0.artists.first?.name ?? "")" }
            let prompt = """
                Name a playlist that feels \(mix.mood.rawValue), with songs like: \(songs.joined(separator: "; ")).
                """
            guard let response = try? await session.respond(to: prompt, generating: MixName.self) else { continue }
            let name = response.content.name.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”' ."))
            guard !name.isEmpty, name.count <= 40 else { continue }
            names[mix.mood] = name
            stored[key] = name
        }
        UserDefaults.standard.set(stored, forKey: storeKey)
        return names
    }
}

/// A mood mix as a card in the mood's colors, with a few of its covers.
struct MoodCard: View {
    @Environment(AppModel.self) private var model
    let mix: MoodMix

    var body: some View {
        let playing = model.player.current?.collectionID == mix.collectionID
        Button {
            if playing {
                model.player.togglePlayback()
            } else {
                Haptics.tap()
                let seeds = Array(mix.tracks.shuffled().prefix(30))
                Task { await model.player.playMix(mix.collectionID, seeds: seeds, mood: mix.mood) }
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                LinearGradient(colors: mix.mood.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: mix.mood.systemImage)
                            .font(.system(size: 84, weight: .bold))
                            .foregroundStyle(.white.opacity(0.18))
                            .rotationEffect(.degrees(-12))
                            .offset(x: 16, y: 10)
                    }
                    .overlay(alignment: .topLeading) { covers.padding(10) }
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Image(systemName: mix.mood.systemImage)
                                .font(.system(size: 15, weight: .bold))
                            Text(mix.mood.title)
                                .font(.system(size: 20, weight: .heavy))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 6)
                        .padding(10)
                    }
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: playing && model.player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(.white, in: .circle)
                            .contentTransition(.symbolEffect(.replace))
                            .padding(8)
                    }
                    .frame(width: 160, height: 160)
                    .coverShape(14)
                Text(mix.name ?? mix.artists.prefix(3).joined(separator: ", "))
                    .font(.system(size: 12, weight: mix.name == nil ? .regular : .semibold))
                    .opacity(0.69)
                    .lineLimit(2)
                    .frame(width: 160, alignment: .leading)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: mix.name)
            }
            .contentShape(.rect)
        }
    }

    /// A few of the mix's covers, overlapping.
    private var covers: some View {
        HStack(spacing: -14) {
            ForEach(Array(mix.covers.enumerated()), id: \.offset) { index, url in
                CoverImage(url: url)
                    .frame(width: 38, height: 38)
                    .clipShape(.circle)
                    .overlay { Circle().stroke(.white.opacity(0.85), lineWidth: 2) }
                    .zIndex(Double(-index))
            }
        }
    }
}
