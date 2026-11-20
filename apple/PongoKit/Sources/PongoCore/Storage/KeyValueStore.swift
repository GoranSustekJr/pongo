import Foundation
import Security

/// Keys of the values the app stores, kept from the Flutter app.
public enum StorageKey: String, Sendable {
    case signedIn = "SIGNEDIN"
    case accessToken = "ACCESSTOKENKEY"
    case refreshToken = "REFRESHTOKENKEY"
    case streamToken = "STREAMTOKEN"
    case locale = "LOCALEKEY"
    case market = "MARKETKEY"
    case syncDelay = "SYNCDELAYKEY"
    case useSyncedLyrics = "USESYNCEDLYRICSKEY"
    case searchArtistCount = "NUMOFSEARCHARTISTSKEY"
    case searchAlbumCount = "NUMOFSEARCHALBUMSKEY"
    case searchTrackCount = "NUMOFSEARCHTRACKSKEY"
    case searchPlaylistCount = "NUMOFSEARCHPLAYLISTSKEY"
    case lyricsTextAlign = "LYRICSTEXTALIGNKEY"
    case useCacheAudioSource = "CACHEAUDIOSOURCEKEY"
    case enableLyrics = "ENABLEYRCSKEY"
    case loopMode = "LOOPMODEKEY"
    case shuffleMode = "SHUFFLEMODEKEY"
    case enableHistory = "ENABLEHISTORYKEY"
    case enableCategories = "ENABLECATEGORIESKEY"
    case categoryCount = "NUMOFCATEGORIESKEY"
    case queue = "QUEUEKEY"
    case queueIndex = "QUEUEINDEXKEY"
    case playingPosition = "CURRENTPLAYINGPOSITIONKEY"
    case cacheImages = "CACHEIMAGESKEY"
    case localsSort = "LOCALSSORTKEY"
    case useBlur = "USEBLURKEY"
    case useMix = "USEMIXKEY"
    case useDetailedBlurhash = "USEDETAILEDBLURHASHKEY"
    case sleepAlarmDeviceVolume = "SLEEPALARMDEVICEVOLUMEKEY"
    case darkMode = "DARKMODEKEY"
    case linearSleepIn = "LINEARSLEEPINKEY"
    case linearWakeUp = "LINEARWAKEUPKEY"
    case dynamicBlurhash = "DYNAMICBLURHASH"
    case useAnimations = "USEANIMATIONSKEY"
    case useLiquidGlass = "USELIQUIDGLASSKEY"
    case streamWhileDownloading = "STREAMWHILEDOWNLOADINGKEY"
    case showLiveLyrics = "SHOWLIVELYRICSKEY"
    case crossfadeSeconds = "CROSSFADESECONDSKEY"
    case gaplessAlbums = "GAPLESSALBUMSKEY"
    case bassBoost = "BASSBOOSTKEY"
    case smartShuffle = "SMARTSHUFFLEKEY"
}

/// Stores string values by key.
public protocol KeyValueStore: Sendable {
    func string(_ key: StorageKey) -> String?
    func set(_ value: String?, for key: StorageKey)
}

extension KeyValueStore {
    public func bool(_ key: StorageKey, fallback: Bool) -> Bool {
        string(key).map { $0 == "true" } ?? fallback
    }

    public func int(_ key: StorageKey, fallback: Int) -> Int {
        string(key).flatMap(Int.init) ?? fallback
    }

    public func double(_ key: StorageKey) -> Double? {
        string(key).flatMap(Double.init)
    }

    public func set(_ value: Bool, for key: StorageKey) { set(String(value), for: key) }
    public func set(_ value: Int, for key: StorageKey) { set(String(value), for: key) }
    public func set(_ value: Double, for key: StorageKey) { set(String(value), for: key) }
}

/// Values in the keychain, for the session tokens.
public final class KeychainStore: KeyValueStore {
    private let service: String

    public init(service: String = "pongo") { self.service = service }

    private func query(_ key: StorageKey) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
    }

    public func string(_ key: StorageKey) -> String? {
        var query = query(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
            let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func set(_ value: String?, for key: StorageKey) {
        let query = query(key)
        guard let value else {
            SecItemDelete(query as CFDictionary)
            return
        }
        let data = Data(value.utf8)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            // The player restores its session after the phone restarts, before
            // it's unlocked
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecItemNotFound {
            SecItemAdd(query.merging(attributes) { $1 } as CFDictionary, nil)
        }
    }
}

/// Values in user defaults, for preferences and the saved queue.
public final class DefaultsStore: KeyValueStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func string(_ key: StorageKey) -> String? { defaults.string(forKey: key.rawValue) }

    public func set(_ value: String?, for key: StorageKey) {
        defaults.set(value, forKey: key.rawValue)
    }
}

/// Values in memory, for tests and previews.
public final class MemoryStore: KeyValueStore, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [StorageKey: String] = [:]

    public init() {}

    public func string(_ key: StorageKey) -> String? { lock.withLock { values[key] } }

    public func set(_ value: String?, for key: StorageKey) { lock.withLock { values[key] = value } }
}
