import Foundation
import Observation

/// The user's preferences, kept in user defaults.
@MainActor
@Observable
public final class SettingsRepository {
    public private(set) var settings: AppSettings

    @ObservationIgnored private let store: KeyValueStore

    /// Loads the saved preferences. The [deviceVolume] is the alarm volume
    /// until the user picks one.
    public init(store: KeyValueStore, deviceVolume: Double = 0.5) {
        self.store = store
        var settings = AppSettings()
        settings.locale = store.string(.locale) ?? Self.systemLocale
        settings.market = store.string(.market) ?? settings.market
        settings.useSyncTimeDelay = store.bool(.syncDelay, fallback: settings.useSyncTimeDelay)
        settings.useSyncedLyrics = store.bool(.useSyncedLyrics, fallback: settings.useSyncedLyrics)
        settings.searchArtistCount = store.int(.searchArtistCount, fallback: settings.searchArtistCount)
        settings.searchAlbumCount = store.int(.searchAlbumCount, fallback: settings.searchAlbumCount)
        settings.searchTrackCount = store.int(.searchTrackCount, fallback: settings.searchTrackCount)
        settings.searchPlaylistCount = store.int(.searchPlaylistCount, fallback: settings.searchPlaylistCount)
        settings.lyricsTextAlign =
            store.string(.lyricsTextAlign).flatMap(LyricsAlignment.init) ?? settings.lyricsTextAlign
        settings.useCacheAudioSource = store.bool(.useCacheAudioSource, fallback: settings.useCacheAudioSource)
        settings.enableLyrics = store.bool(.enableLyrics, fallback: settings.enableLyrics)
        settings.enableHistory = store.bool(.enableHistory, fallback: settings.enableHistory)
        settings.enableCategories = store.bool(.enableCategories, fallback: settings.enableCategories)
        settings.categoryCount = store.int(.categoryCount, fallback: settings.categoryCount)
        settings.cacheImages = store.bool(.cacheImages, fallback: settings.cacheImages)
        settings.localsSort = store.string(.localsSort).map(LocalsSort.fromStorage) ?? settings.localsSort
        settings.useBlur = store.bool(.useBlur, fallback: settings.useBlur)
        settings.useMix = store.bool(.useMix, fallback: settings.useMix)
        settings.useDetailedBlurhash = store.bool(.useDetailedBlurhash, fallback: settings.useDetailedBlurhash)
        settings.sleepAlarmDeviceVolume = store.double(.sleepAlarmDeviceVolume) ?? deviceVolume
        settings.darkMode = store.bool(.darkMode, fallback: settings.darkMode)
        settings.linearSleepIn = store.bool(.linearSleepIn, fallback: settings.linearSleepIn)
        settings.linearWakeUp = store.bool(.linearWakeUp, fallback: settings.linearWakeUp)
        settings.useDynamicBlurhash = store.bool(.dynamicBlurhash, fallback: settings.useDynamicBlurhash)
        settings.useAnimations = store.bool(.useAnimations, fallback: settings.useAnimations)
        settings.useLiquidGlass = store.bool(.useLiquidGlass, fallback: settings.useLiquidGlass)
        settings.streamWhileDownloading = store.bool(
            .streamWhileDownloading, fallback: settings.streamWhileDownloading)
        settings.showLiveLyrics = store.bool(.showLiveLyrics, fallback: settings.showLiveLyrics)
        settings.crossfadeSeconds = store.int(.crossfadeSeconds, fallback: settings.crossfadeSeconds)
        settings.gaplessAlbums = store.bool(.gaplessAlbums, fallback: settings.gaplessAlbums)
        settings.bassBoost = store.bool(.bassBoost, fallback: settings.bassBoost)
        settings.smartShuffle = store.bool(.smartShuffle, fallback: settings.smartShuffle)
        self.settings = settings
    }

    /// The app's languages, picked from the device's until the user chooses.
    public static let languages = ["en", "de", "hr"]

    static var systemLocale: String {
        let preferred = Locale.preferredLanguages.first.map { Locale(identifier: $0).language.languageCode?.identifier }
        return languages.first { $0 == preferred ?? nil } ?? "en"
    }

    /// Saves the preferences [change] makes to the current ones.
    public func update(_ change: (inout AppSettings) -> Void) {
        var new = settings
        change(&new)
        save(new)
    }

    public func save(_ new: AppSettings) {
        let old = settings
        guard new != old else { return }
        settings = new

        func save<T: Equatable>(_ key: StorageKey, _ field: KeyPath<AppSettings, T>, _ text: (T) -> String) {
            if new[keyPath: field] != old[keyPath: field] { store.set(text(new[keyPath: field]), for: key) }
        }
        save(.locale, \.locale) { $0 }
        save(.market, \.market) { $0 }
        save(.lyricsTextAlign, \.lyricsTextAlign) { $0.rawValue }
        save(.localsSort, \.localsSort) { $0.rawValue }
        save(.sleepAlarmDeviceVolume, \.sleepAlarmDeviceVolume) { String($0) }
        for (key, field) in Self.bools { save(key, field) { String($0) } }
        for (key, field) in Self.ints { save(key, field) { String($0) } }
    }

    private static let bools: [(StorageKey, KeyPath<AppSettings, Bool>)] = [
        (.syncDelay, \.useSyncTimeDelay), (.useSyncedLyrics, \.useSyncedLyrics),
        (.useCacheAudioSource, \.useCacheAudioSource), (.enableLyrics, \.enableLyrics),
        (.enableHistory, \.enableHistory), (.enableCategories, \.enableCategories),
        (.cacheImages, \.cacheImages), (.useBlur, \.useBlur), (.useMix, \.useMix),
        (.useDetailedBlurhash, \.useDetailedBlurhash), (.darkMode, \.darkMode),
        (.linearSleepIn, \.linearSleepIn), (.linearWakeUp, \.linearWakeUp),
        (.dynamicBlurhash, \.useDynamicBlurhash), (.useAnimations, \.useAnimations),
        (.useLiquidGlass, \.useLiquidGlass), (.streamWhileDownloading, \.streamWhileDownloading),
        (.showLiveLyrics, \.showLiveLyrics), (.gaplessAlbums, \.gaplessAlbums),
        (.smartShuffle, \.smartShuffle), (.bassBoost, \.bassBoost),
    ]

    private static let ints: [(StorageKey, KeyPath<AppSettings, Int>)] = [
        (.searchArtistCount, \.searchArtistCount), (.searchAlbumCount, \.searchAlbumCount),
        (.searchTrackCount, \.searchTrackCount), (.searchPlaylistCount, \.searchPlaylistCount),
        (.categoryCount, \.categoryCount), (.crossfadeSeconds, \.crossfadeSeconds),
    ]
}

/// The settings that are the same on all of the user's devices, as sync
/// items, one per setting. Settings that depend on the device, such as how
/// much it can animate or cache and the alarm volume, aren't synced.
@MainActor
public final class SettingsSyncSource: SyncSource {
    private let settings: SettingsRepository
    private nonisolated static let kind = "setting"

    public init(settings: SettingsRepository) { self.settings = settings }

    public nonisolated var kinds: Set<String> { [Self.kind] }

    private struct Field {
        var read: (AppSettings) -> JSONValue
        var write: (inout AppSettings, JSONValue) -> Void
    }

    private static func bool(_ path: WritableKeyPath<AppSettings, Bool>) -> Field {
        Field(read: { .bool($0[keyPath: path]) }, write: { if let v = $1.bool { $0[keyPath: path] = v } })
    }

    private static func int(_ path: WritableKeyPath<AppSettings, Int>) -> Field {
        Field(read: { .int($0[keyPath: path]) }, write: { if let v = $1.int { $0[keyPath: path] = v } })
    }

    private static func string(_ path: WritableKeyPath<AppSettings, String>) -> Field {
        Field(read: { .string($0[keyPath: path]) }, write: { if let v = $1.string { $0[keyPath: path] = v } })
    }

    // The names and values are the Flutter app's
    private static let fields: [String: Field] = [
        "locale": string(\.locale),
        "market": string(\.market),
        "useSyncTimeDelay": bool(\.useSyncTimeDelay),
        "useSyncedLyrics": bool(\.useSyncedLyrics),
        "searchArtistCount": int(\.searchArtistCount),
        "searchAlbumCount": int(\.searchAlbumCount),
        "searchTrackCount": int(\.searchTrackCount),
        "searchPlaylistCount": int(\.searchPlaylistCount),
        "lyricsTextAlign": Field(
            read: { .string($0.lyricsTextAlign.rawValue) },
            write: { if let v = $1.string.flatMap(LyricsAlignment.init) { $0.lyricsTextAlign = v } }),
        "enableLyrics": bool(\.enableLyrics),
        "enableHistory": bool(\.enableHistory),
        "enableCategories": bool(\.enableCategories),
        "categoryCount": int(\.categoryCount),
        "localsSort": Field(
            read: { .string($0.localsSort.rawValue) },
            write: { if let v = $1.string { $0.localsSort = .fromStorage(v) } }),
        "useMix": bool(\.useMix),
        "darkMode": bool(\.darkMode),
        "linearSleepIn": bool(\.linearSleepIn),
        "linearWakeUp": bool(\.linearWakeUp),
    ]

    public func snapshot() async throws -> [SyncKey: SyncItem] {
        var items: [SyncKey: SyncItem] = [:]
        for (name, field) in Self.fields {
            items[SyncKey(kind: Self.kind, key: name)] = SyncItem(data: ["v": field.read(settings.settings)])
        }
        return items
    }

    public func item(_ key: SyncKey) async throws -> SyncItem {
        SyncItem(data: Self.fields[key.key].map { ["v": $0.read(settings.settings)] })
    }

    public func apply(_ key: SyncKey, _ data: [String: JSONValue]?) async throws {
        // A setting always has a value, so it can't be deleted
        guard let field = Self.fields[key.key], let value = data?["v"] else { return }
        settings.update { field.write(&$0, value) }
    }
}
