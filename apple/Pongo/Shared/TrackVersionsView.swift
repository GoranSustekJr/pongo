import PongoCore
import SwiftUI

extension AppModel {
    /// Makes the server play [track] from the YouTube [video], an ID or link,
    /// and drops this device's copies of the old recording. Returns whether it worked.
    func useVersion(_ video: String, for track: Track) async -> Bool {
        let duration: Double
        do {
            duration = try await versions.use(video, for: track.id)
        } catch APIError.status(422, let detail) {
            messages.show(
                detail == "not_a_video" ? L10n.versionnotvideo : L10n.versionfailed,
                systemImage: "exclamationmark.triangle", isError: true)
            return false
        } catch {
            messages.show(L10n.versionfailed, systemImage: "exclamationmark.triangle", isError: true)
            return false
        }
        await player.forgetAudio(of: track.id)
        // A downloaded copy is the old recording, so it's downloaded again
        do {
            if try await downloads.refreshAudio(of: track, durationSeconds: duration) { libraryChanged() }
        } catch {
            messages.show(L10n.downloadfailed, detail: track.name, systemImage: "exclamationmark.triangle", isError: true)
            return true
        }
        messages.show(L10n.versionchanged, detail: track.name, systemImage: "checkmark.circle")
        return true
    }
}

/// The YouTube recordings a track could play from, to pick the right one when
/// Pongo matched another, such as a later re-recording.
struct TrackVersionsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let track: Track
    @State private var versions: [TrackVersion]?
    @State private var link = ""
    @State private var switching: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    CoverImage(url: track.coverURL(size: 150)).frame(width: 50, height: 50).coverShape(7.5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.name).font(.headline)
                        Text([track.artistNames, track.album?.name].compactMap { $0 }.joined(separator: " · "))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                }
                .groupedRowBackground()
            } footer: {
                Text(L10n.versionsfooter)
            }

            if let versions {
                Section {
                    ForEach(versions) { version in
                        Button {
                            choose(version.id)
                        } label: {
                            VersionRow(version: version, switching: switching == version.id)
                        }
                        .buttonStyle(.tappable)
                        .disabled(switching != nil)
                        .groupedRowBackground()
                    }
                }
            }

            Section {
                HStack {
                    TextField(L10n.versionpaste, text: $link)
                        .autocorrectionDisabled()
                        #if os(iOS)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                        #endif
                        .onSubmit { choose(link) }
                    if !link.isEmpty {
                        Button(L10n.versionuse) { choose(link) }
                            .buttonStyle(.borderless)
                            .disabled(switching != nil)
                    }
                }
                .groupedRowBackground()
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .overlay {
            if versions == nil {
                ProgressView()
            } else if versions?.isEmpty == true {
                EmptyMessage(systemImage: "waveform.slash", title: L10n.versionsnone)
            }
        }
        .navigationTitle(L10n.versionstitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(L10n.close) { dismiss() } }
        }
        .interactiveDismissDisabled(switching != nil)
        .task {
            versions = (try? await model.versions.versions(of: track.id)) ?? []
        }
    }

    private func choose(_ video: String) {
        let video = video.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !video.isEmpty, switching == nil else { return }
        switching = video
        Task {
            let worked = await model.useVersion(video, for: track)
            switching = nil
            if worked { dismiss() }
        }
    }
}

private struct VersionRow: View {
    let version: TrackVersion
    var switching: Bool

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: version.image.flatMap(URL.init(string:)))
                .frame(width: 50, height: 50)
                .coverShape(7.5)
            VStack(alignment: .leading, spacing: 2) {
                Text(version.title).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                Text(version.artists.joined(separator: ", ")).font(.system(size: 13)).opacity(0.78).lineLimit(1)
                Text(details).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if switching {
                ProgressView()
            } else if version.isCurrent {
                Label(L10n.versionplaying, systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.pongoTeal)
            }
        }
        .padding(.vertical, 2)
        .contentShape(.rect)
    }

    private var details: String {
        var parts: [String] = []
        if let album = version.album { parts.append(album) }
        if let year = version.year { parts.append(year) }
        if let duration = version.duration { parts.append(String(format: "%d:%02d", duration / 60, duration % 60)) }
        if version.isVideo { parts.append(L10n.versionvideo) }
        return parts.joined(separator: " · ")
    }
}
