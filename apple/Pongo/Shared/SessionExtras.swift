import CoreImage.CIFilterBuiltins
import PongoCore
import SwiftUI

/// A QR code of [text], drawn sharp at any size.
struct QRCode: View {
    let text: String

    var body: some View {
        if let image = Self.image(text) {
            Image(decorative: image, scale: 1)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        }
    }

    private static func image(_ text: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        return CIContext().createCGImage(output, from: output.extent)
    }
}

/// The session's join link as a QR code, which a phone's camera opens in
/// Pongo, and to share.
struct JoinCode: View {
    let link: URL

    var body: some View {
        VStack(spacing: 8) {
            QRCode(text: link.absoluteString)
                .padding(10)
                .background(.white, in: .rect(cornerRadius: 14, style: .continuous))
                .frame(width: 170, height: 170)
            Text(L10n.scantojoin)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Songs guests suggested, which the host adds or declines.
struct SuggestionsList: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let session = model.listening
        VStack(alignment: .leading, spacing: 8) {
            Label(L10n.suggestedsongs, systemImage: "lightbulb")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            ForEach(session.suggestions) { suggestion in
                HStack(spacing: 10) {
                    if let listener = session.listener(suggestion.from) {
                        ListenerAvatar(listener: listener, size: 28)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(suggestion.track.name).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                        Text(suggestion.track.artistNames).font(.system(size: 13)).foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 6)
                    Button {
                        Haptics.tap()
                        session.decline(suggestion)
                    } label: {
                        Image(systemName: "xmark").frame(width: 34, height: 34)
                            .background(Color.primary.opacity(0.1), in: .circle)
                    }
                    .accessibilityLabel(L10n.decline)
                    Button {
                        Haptics.tap()
                        session.accept(suggestion)
                    } label: {
                        Image(systemName: "plus").frame(width: 34, height: 34)
                            .foregroundStyle(.black)
                            .background(Color.pongoTeal, in: .circle)
                    }
                    .accessibilityLabel(L10n.lasttoqueue)
                }
                .font(.system(size: 14, weight: .bold))
                .buttonStyle(.press)
            }
        }
        .padding(12)
        .background(Color.pongoCard.opacity(0.6), in: .rect(cornerRadius: 16, style: .continuous))
    }
}

/// What played in the session that just ended, with who added what, to keep
/// as a playlist.
struct SessionRecapView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let recap: SessionRecap
    @State private var saved = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(recap.songs.count) \(L10n.plustracks)")
                            .font(.system(size: 28, weight: .bold))
                        if !recap.listeners.isEmpty {
                            Text("\(L10n.with) \(recap.listeners.formatted(.list(type: .and)))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    Button {
                        Task { await save() }
                    } label: {
                        Label(saved ? L10n.addedtoplaylist : L10n.saveasplaylist,
                              systemImage: saved ? "checkmark" : "music.note.list")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.pongoTeal)
                    .controlSize(.large)
                    .disabled(saved)
                }
                .groupedRowBackground()
                Section {
                    ForEach(Array(recap.songs.enumerated()), id: \.offset) { _, song in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.track.name).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                            HStack(spacing: 4) {
                                Text(song.track.artistNames).lineLimit(1)
                                if let addedBy = song.addedBy {
                                    Text("· \(L10n.addedby.lowercased()) \(addedBy)").foregroundStyle(Color.pongoTeal).lineLimit(1)
                                }
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .groupedRowBackground()
            }
            #if os(iOS)
                .listStyle(.insetGrouped)
            #endif
            .navigationTitle(L10n.sessionrecap)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
        #if os(macOS)
            .frame(width: 460, height: 560)
        #endif
    }

    private func save() async {
        let date = recap.started.formatted(.dateTime.day().month(.abbreviated).hour().minute())
        var title = "\(L10n.listentogether) · \(date)"
        var attempt = 2
        while await model.playlists(.online).contains(where: { $0.title == title }) {
            title = "\(L10n.listentogether) · \(date) (\(attempt))"
            attempt += 1
        }
        guard let opid = await model.createPlaylist(.online, title: title, cover: nil) else { return }
        for song in recap.songs {
            let track = song.track
            _ = try? await model.database.addOnlineTrack(OnlinePlaylistTrack(opid: opid, track: track))
        }
        model.libraryChanged()
        Haptics.tap()
        saved = true
    }
}

extension AppModel {
    /// Joins the session a `pongo://join/CODE` link is of; returns whether it
    /// was one.
    func openJoinLink(_ url: URL) -> Bool {
        guard let code = ListeningSession.code(in: url) else { return false }
        guard auth.isSignedIn else { return true }
        if listening.code != code { listening.join(code) }
        router.showsPlayer = false
        showsListenTogether = true
        return true
    }
}
