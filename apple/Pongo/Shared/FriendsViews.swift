import PongoCore
import SwiftUI

extension AppModel {
    /// Opens the profile a pongo://friend/ link names; returns whether [url] was one.
    func openFriendLink(_ url: URL) -> Bool {
        guard let code = SocialRepository.code(in: url) else { return false }
        guard auth.isSignedIn else { return true }
        router.showsPlayer = false
        #if os(macOS)
            router.section = .friends
            router.path = [.person(code)]
        #else
            router.tab = .library
            router.library = [.friends, .person(code)]
        #endif
        return true
    }

    /// Saves [playlist] as a new online playlist of the user's own, to change
    /// as they like.
    func saveCopy(of playlist: SharedPlaylist) async {
        let existing = Set(await playlists(.online).map(\.title))
        var title = playlist.info.title
        var number = 2
        while existing.contains(title) {
            title = "\(playlist.info.title) (\(number))"
            number += 1
        }
        do {
            let opid = try await database.createOnlinePlaylist(title, cover: playlist.cover)
            _ = try await database.addOnlineTracks(
                opid, playlist.tracks.map { OnlinePlaylistTrack(opid: opid, track: $0) })
            libraryChanged()
            messages.show(L10n.savedcopy, detail: title, systemImage: "plus.square.on.square")
        } catch {
            messages.show(L10n.error, systemImage: "exclamationmark.triangle", isError: true)
        }
    }

    /// Has the server download [stids], then calls [refresh], which reloads
    /// and returns how many are still missing, every few seconds until they
    /// stop arriving.
    func prepareOnServer(_ stids: [String], refresh: () async -> Int?) async {
        guard let result = try? await catalog.prepare(stids) else {
            messages.show(L10n.serverunreachable, systemImage: "exclamationmark.triangle", isError: true)
            return
        }
        if result.limited {
            messages.show(L10n.serverdownloadlimit, systemImage: "exclamationmark.triangle", isError: true)
        } else if result.started > 0 {
            messages.show(L10n.serverdownloading, systemImage: "icloud.and.arrow.down")
        }
        guard result.started > 0 else { return }
        // Each download takes a few seconds; stop once nothing changed for a while
        var unchanged = 0
        var left = stids.count
        while unchanged < 8, left > 0, !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            guard let now = await refresh() else { continue }
            unchanged = now == left ? unchanged + 1 : 0
            left = now
        }
    }
}

// MARK: - Friends

/// The user's friend code, finding people by name or code, and whom the user
/// follows and who follows them.
struct FriendsView: View {
    @Environment(AppModel.self) private var model
    @State private var account: SocialAccount?
    @State private var following: [Person] = []
    @State private var followers: [Person] = []
    @State private var query = ""
    @State private var results: [Person]?
    @State private var failed = false
    @State private var copied = false

    private var searching: Bool { query.trimmingCharacters(in: .whitespaces).count >= 2 }

    var body: some View {
        List {
            Section {
                TrackSearchField(prompt: L10n.searchpeople, text: $query)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }
            if searching {
                Section(L10n.search) {
                    if let results {
                        if results.isEmpty {
                            Text(L10n.nopeoplefound).foregroundStyle(.secondary).groupedRowBackground()
                        }
                        ForEach(results) { person in
                            PersonRow(person: person) { update(person.code, following: $0) }
                        }
                    } else {
                        ProgressView().frame(maxWidth: .infinity).groupedRowBackground()
                    }
                }
            } else {
                Section { ListenTogetherRow() }
                if let account { codeSection(account) }
                Section(L10n.following) {
                    if following.isEmpty, account != nil {
                        Text(L10n.notfollowinganyone).foregroundStyle(.secondary).groupedRowBackground()
                    }
                    ForEach(following) { person in
                        PersonRow(person: person) { update(person.code, following: $0) }
                    }
                }
                Section(L10n.followers) {
                    if followers.isEmpty, account != nil {
                        Text(L10n.nofollowers).foregroundStyle(.secondary).groupedRowBackground()
                    }
                    ForEach(followers) { person in
                        PersonRow(person: person) { update(person.code, following: $0) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .overlay {
            if !model.auth.isSignedIn {
                EmptyMessage(systemImage: "person.2", title: L10n.friendssignin)
            } else if failed, account == nil {
                EmptyMessage(systemImage: "wifi.exclamationmark", title: L10n.serverunreachable)
            }
        }
        .navigationTitle(L10n.friends)
        .task(id: model.libraryRevision) { await load() }
        .refreshable { await load() }
        .task(id: query) {
            guard searching else {
                results = nil
                return
            }
            // Waits for a pause in typing
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            let found = try? await model.social.search(query)
            if !Task.isCancelled { results = found ?? [] }
        }
    }

    private func codeSection(_ account: SocialAccount) -> some View {
        Section {
            NavigationLink(value: Route.person(account.person.code)) {
                HStack(spacing: 12) {
                    Avatar(url: account.person.picture, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.person.name.isEmpty ? L10n.yourfriendprofile : account.person.name)
                            .font(.system(size: 16, weight: .semibold))
                        Text(
                            "\(account.followers) \(L10n.followers) · \(account.following) \(L10n.following)"
                        )
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                }
            }
            .groupedRowBackground()
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.yourfriendcode).font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                Text(account.person.code)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .kerning(3)
                    .textSelection(.enabled)
                Text(L10n.friendcodehint).font(.system(size: 13)).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    ShareLink(
                        item: SocialRepository.link(for: account.person.code),
                        message: Text("\(L10n.followmeonpongo): \(account.person.code)")
                    ) {
                        Label(L10n.sharecode, systemImage: "square.and.arrow.up")
                    }
                    Button(copied ? L10n.copied : L10n.copycode, systemImage: copied ? "checkmark" : "doc.on.doc") {
                        copyToPasteboard(account.person.code)
                        copied = true
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            copied = false
                        }
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
            .padding(.vertical, 4)
            .groupedRowBackground()
        }
    }

    private func load() async {
        guard model.auth.isSignedIn else { return }
        do {
            async let account = model.social.account()
            async let following = model.social.people()
            async let followers = model.social.people(followers: true)
            (self.account, self.following, self.followers) = try await (account, following, followers)
            failed = false
        } catch {
            failed = true
        }
    }

    private func update(_ code: String, following value: Bool) {
        for index in following.indices where following[index].code == code { following[index].following = value }
        for index in followers.indices where followers[index].code == code { followers[index].following = value }
        for index in (results ?? []).indices where results?[index].code == code { results?[index].following = value }
        Task {
            if let account = try? await model.social.account() { self.account = account }
            if let people = try? await model.social.people() { following = people }
        }
    }
}

/// A person in a list: their picture and name, opening their profile, with a
/// button to follow them.
private struct PersonRow: View {
    let person: Person
    var changed: (Bool) -> Void

    var body: some View {
        NavigationLink(value: Route.person(person.code)) {
            HStack(spacing: 12) {
                Avatar(url: person.picture, size: 44)
                Text(person.isYou ? "\(person.name) (\(L10n.you))" : person.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !person.isYou {
                    FollowButton(code: person.code, following: person.following, compact: true, changed: changed)
                }
            }
        }
        .groupedRowBackground()
    }
}

/// Asks a friend to listen along, starting a session first if the user
/// isn't in one.
struct ListenInviteButton: View {
    @Environment(AppModel.self) private var model
    let person: Person
    @State private var sending = false

    var body: some View {
        Button {
            sending = true
            Task {
                await model.inviteToListen(person)
                sending = false
            }
        } label: {
            HStack(spacing: 6) {
                if sending { ProgressView().controlSize(.small) } else { Image(systemName: "person.2.wave.2") }
                Text(model.listening.isActive ? L10n.invitetolisten : L10n.listentogether)
            }
            .font(.system(size: 15, weight: .semibold))
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .disabled(sending)
    }
}

/// Follows or unfollows a person.
struct FollowButton: View {
    @Environment(AppModel.self) private var model
    let code: String
    var following: Bool
    var compact = false
    var changed: (Bool) -> Void = { _ in }
    @State private var busy = false

    var body: some View {
        Button {
            busy = true
            Task {
                do {
                    try await model.social.follow(code, !following)
                    Haptics.tap()
                    changed(!following)
                } catch {
                    model.messages.show(L10n.serverunreachable, systemImage: "exclamationmark.triangle", isError: true)
                }
                busy = false
            }
        } label: {
            Text(following ? L10n.following : L10n.follow)
                .font(.system(size: compact ? 13 : 15, weight: .semibold))
                .padding(.horizontal, compact ? 2 : 10)
        }
        .buttonBorderShape(.capsule)
        .tint(following ? .secondary : .pongoTeal)
        .prominent(!following)
        .controlSize(compact ? .small : .regular)
        .disabled(busy)
    }
}

/// A person's round picture, or a symbol without one.
struct Avatar: View {
    var url: URL?
    var size: CGFloat

    var body: some View {
        CoverImage(url: url, placeholder: "person.fill")
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

// MARK: - Profile

/// Someone's profile: who they are, whether the user follows them, and the
/// playlists they show.
struct PersonView: View {
    @Environment(AppModel.self) private var model
    let code: String
    @State private var profile: Profile?
    @State private var missing = false
    @State private var failed = false

    var body: some View {
        List {
            if let profile {
                Section {
                    VStack(spacing: 10) {
                        Avatar(url: profile.person.picture, size: 96)
                        Text(profile.person.name).font(.system(size: 24, weight: .bold)).multilineTextAlignment(.center)
                        Text("\(profile.followers) \(L10n.followers) · \(profile.followingCount) \(L10n.following)")
                            .font(.system(size: 14)).foregroundStyle(.secondary)
                        if profile.followsYou && !profile.person.isYou {
                            Text(L10n.followsyou)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(.secondary.opacity(0.2), in: Capsule())
                        }
                        if profile.person.isYou {
                            Text(L10n.yourprofilehint).font(.system(size: 13)).foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 10) {
                                FollowButton(code: profile.person.code, following: profile.person.following) { _ in
                                    Task { await load() }
                                }
                                if profile.followsYou || profile.person.following {
                                    ListenInviteButton(person: profile.person)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }
                Section(L10n.playlists) {
                    if profile.playlists.isEmpty {
                        Text(profile.person.isYou ? L10n.nosharedplaylistsyou : L10n.nosharedplaylists)
                            .foregroundStyle(.secondary)
                            .groupedRowBackground()
                    }
                    ForEach(profile.playlists) { info in
                        SharedPlaylistRow(info: info, showsOwner: false)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .overlay {
            if missing {
                EmptyMessage(systemImage: "person.crop.circle.badge.questionmark", title: L10n.personnotfound)
            } else if failed {
                EmptyMessage(systemImage: "wifi.exclamationmark", title: L10n.serverunreachable)
            } else if profile == nil {
                ProgressView()
            }
        }
        .navigationTitle(profile?.person.name ?? L10n.profile)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: model.libraryRevision) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            profile = try await model.social.profile(code)
            failed = false
        } catch APIError.status(404, _) {
            missing = true
        } catch {
            failed = profile == nil
        }
    }
}

/// A shared playlist in a list, opening it.
struct SharedPlaylistRow: View {
    let info: SharedPlaylistInfo
    var showsOwner = true

    var body: some View {
        NavigationLink(value: Route.sharedPlaylist(info)) {
            HStack(spacing: 14) {
                SharedCover(info: info).frame(width: 60, height: 60).coverShape(10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.title).font(.system(size: 17, weight: .semibold)).lineLimit(1)
                    Text(
                        showsOwner
                            ? "\(L10n.byperson) \(info.owner.name) · \(info.trackCount) \(L10n.plustracks)"
                            : "\(info.trackCount) \(L10n.plustracks)"
                    )
                    .font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                }
            }
        }
        .groupedRowBackground()
    }
}

/// The cover a shared playlist's owner set, loaded on its own since covers
/// are large, or one of its tracks' images.
struct SharedCover: View {
    @Environment(AppModel.self) private var model
    let info: SharedPlaylistInfo
    @State private var data: Data?

    /// Covers already loaded, by playlist.
    private static var loaded: [String: Data] = [:]

    var body: some View {
        Group {
            if let data = data ?? Self.loaded[info.id] {
                CoverImage(data: data, placeholder: "music.note.list")
            } else {
                CoverImage(url: info.image, placeholder: "music.note.list")
            }
        }
        .task(id: info.id) {
            guard info.hasCover, Self.loaded[info.id] == nil,
                let cover = try? await model.social.cover(info.owner.code, key: info.key)
            else { return }
            Self.loaded[info.id] = cover
            data = cover
        }
    }
}

// MARK: - Shared playlists

/// A playlist someone shows on their profile: plays like the user's own,
/// and can be added to the user's library or saved as a copy.
struct SharedPlaylistView: View {
    @Environment(AppModel.self) private var model
    let info: SharedPlaylistInfo
    @State private var playlist: SharedPlaylist?
    @State private var availability = TrackAvailability()
    @State private var gone = false
    @State private var query = ""
    @State private var preparing = false
    @State private var onlyMissing = false

    private var collectionID: String { "shared.playlist:\(info.owner.code):\(info.key)" }
    private var tracks: [Track] { playlist?.tracks ?? [] }

    private var missing: [String] {
        let known = availability.durations.merging(model.player.fetchedDurations) { first, _ in first }
        return tracks.map(\.id).filter { known[$0] == nil }
    }

    private var visible: [Track] {
        let notOnServer = onlyMissing ? Set(missing) : []
        return tracks.filter { (!onlyMissing || notOnServer.contains($0.id)) && $0.matches(query) }
    }

    var body: some View {
        let current = playlist?.info ?? info
        CollectionScreen(
            title: current.title,
            subtitle: "\(L10n.byperson) \(current.owner.name) · \(current.trackCount) \(L10n.plustracks)",
            coverURL: current.image, coverData: playlist?.cover
        ) {
            PlayShuffleBar(collectionID: collectionID, canShuffle: tracks.count > missing.count) {
                await play(index: 0)
            } shuffle: {
                await play(shuffle: true)
            }
            .disabled(tracks.isEmpty)
        } content: {
            if gone {
                EmptyMessage(systemImage: "lock", title: L10n.playlistnotshared).padding(.top, 30)
            } else if let playlist {
                content(playlist)
            } else {
                ProgressView().padding(.top, 40)
            }
        } actions: {
            if let playlist, !playlist.info.owner.isYou {
                Button(
                    playlist.followed ? L10n.removefromlibrary : L10n.addtolibrary,
                    systemImage: playlist.followed ? "heart.slash" : "heart"
                ) {
                    Task { await setFollowed(!playlist.followed) }
                }
            }
            if let playlist, !playlist.tracks.isEmpty {
                Button(L10n.savecopy, systemImage: "plus.square.on.square") {
                    Task { await model.saveCopy(of: playlist) }
                }
            }
            Button(current.owner.name, systemImage: "person.crop.circle") {
                model.router.show(.person(current.owner.code))
            }
        }
        .task { await load() }
    }

    @ViewBuilder private func content(_ playlist: SharedPlaylist) -> some View {
        let notOnServer = missing
        VStack(spacing: 12) {
            if !playlist.info.owner.isYou {
                HStack(spacing: 12) {
                    Button {
                        Task { await setFollowed(!playlist.followed) }
                    } label: {
                        Label(
                            playlist.followed ? L10n.inlibrary : L10n.addtolibrary,
                            systemImage: playlist.followed ? "heart.fill" : "heart")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .buttonBorderShape(.capsule)
                    .tint(playlist.followed ? .secondary : .pongoTeal)
                    .prominent(!playlist.followed)
                    if playlist.followers > 0 {
                        Text("\(playlist.followers) \(L10n.followers)")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            if !notOnServer.isEmpty {
                ServerMissingBanner(
                    missing: notOnServer.count, failed: notOnServer.filter { availability.failed[$0] != nil }.count,
                    onlyMissing: $onlyMissing, preparing: preparing
                ) {
                    Task {
                        preparing = true
                        await model.prepareOnServer(missing) { await refreshAvailability() }
                        preparing = false
                    }
                }
            }
            if tracks.count > 1 { TrackSearchField(text: $query) }
        }
        .padding(.horizontal, 15)
        if playlist.tracks.isEmpty {
            EmptyMessage(systemImage: "music.note", title: L10n.notracks).padding(.top, 30)
        } else if visible.isEmpty {
            EmptyMessage(systemImage: "magnifyingglass", title: L10n.noresults).padding(.top, 30)
        }
        let listed = visible
        TrackList(
            tracks: listed, collectionID: collectionID, missing: Set(notOnServer), explainsMissing: true,
            failed: availability.failed
        ) { index in
            let track = listed[index]
            guard let position = tracks.firstIndex(of: track) else { return }
            Task {
                await model.player.playCollectionTrack(collectionID: collectionID, stid: track.id, index: position) {
                    await play(index: position)
                }
            }
        }
        .onChange(of: notOnServer.isEmpty) { if notOnServer.isEmpty { onlyMissing = false } }
    }

    private func load() async {
        do {
            let loaded = try await model.social.playlist(info.owner.code, key: info.key)
            playlist = loaded
            _ = await refreshAvailability()
        } catch APIError.status(404, _) {
            gone = true
        } catch {
            model.messages.show(L10n.serverunreachable, systemImage: "exclamationmark.triangle", isError: true)
        }
    }

    /// Reloads which tracks the server has; returns how many it hasn't.
    private func refreshAvailability() async -> Int? {
        guard !tracks.isEmpty, let found = try? await model.catalog.availability(tracks.map(\.id)) else { return nil }
        availability = found
        return missing.count
    }

    private func setFollowed(_ followed: Bool) async {
        do {
            try await model.social.followPlaylist(info.owner.code, key: info.key, followed)
            playlist?.followed = followed
            playlist?.followers += followed ? 1 : -1
            Haptics.tap()
            if followed { model.messages.show(L10n.addedtolibrary, systemImage: "heart.fill") }
            model.libraryChanged()
        } catch {
            model.messages.show(L10n.serverunreachable, systemImage: "exclamationmark.triangle", isError: true)
        }
    }

    private func play(index: Int? = nil, shuffle: Bool = false) async {
        let durations = availability.durations.merging(model.player.fetchedDurations) { first, _ in first }
        let notOnServer = Set(missing)
        let list = shuffle ? tracks.filter { !notOnServer.contains($0.id) } : tracks
        if shuffle, !notOnServer.isEmpty {
            model.messages.show(L10n.shuffleleavesout, systemImage: "shuffle")
        }
        await model.player.playOnline(collectionID, list, durations: durations, index: index, shuffle: shuffle)
        if shuffle { model.suggestSongs(for: collectionID, trackCount: list.count) }
    }
}

/// The shared playlists the user added to their library.
struct FollowedPlaylistsView: View {
    @Environment(AppModel.self) private var model
    @State private var playlists: [SharedPlaylistInfo]?
    @State private var failed = false

    var body: some View {
        List {
            ForEach(playlists ?? []) { info in
                SharedPlaylistRow(info: info)
                    .swipeActions {
                        Button(L10n.removefromlibrary, systemImage: "heart.slash", role: .destructive) {
                            Task { await remove(info) }
                        }
                    }
                    .contextMenu {
                        Button(L10n.removefromlibrary, systemImage: "heart.slash", role: .destructive) {
                            Task { await remove(info) }
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .overlay {
            if !model.auth.isSignedIn {
                EmptyMessage(systemImage: "person.2", title: L10n.friendssignin)
            } else if failed, playlists == nil {
                EmptyMessage(systemImage: "wifi.exclamationmark", title: L10n.serverunreachable)
            } else if playlists?.isEmpty == true {
                EmptyMessage(systemImage: "heart.text.square", title: L10n.nofollowedplaylists)
            } else if playlists == nil {
                ProgressView()
            }
        }
        .navigationTitle(L10n.followedplaylists)
        .task(id: model.libraryRevision) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        guard model.auth.isSignedIn else { return }
        do {
            playlists = try await model.social.followedPlaylists()
            failed = false
        } catch {
            failed = true
        }
    }

    private func remove(_ info: SharedPlaylistInfo) async {
        do {
            try await model.social.followPlaylist(info.owner.code, key: info.key, false)
            playlists?.removeAll { $0.id == info.id }
        } catch {
            model.messages.show(L10n.serverunreachable, systemImage: "exclamationmark.triangle", isError: true)
        }
    }
}

extension View {
    /// A filled button when [prominent], an outlined one otherwise.
    @ViewBuilder func prominent(_ prominent: Bool) -> some View {
        if prominent { buttonStyle(.borderedProminent) } else { buttonStyle(.bordered) }
    }
}
