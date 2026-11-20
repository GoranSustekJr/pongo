import PongoCore
import SwiftUI

/// What the user listened to most, month by month, on all their devices: how
/// much they played, their top artists and their top songs, which play from
/// here.
struct StatsView: View {
    @Environment(AppModel.self) private var model
    @State private var months: [String] = []
    @State private var month: String?
    @State private var stats: MonthStats?
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if !months.isEmpty {
                    monthPicker
                }
                if let stats, stats.plays > 0 {
                    summary(stats)
                    if !stats.artists.isEmpty { topArtists(stats) }
                    topSongs(stats)
                } else if loaded {
                    EmptyMessage(systemImage: "chart.bar", title: L10n.nostatsyet, detail: L10n.nostatsyetdetail)
                        .padding(.top, 60)
                }
            }
            .padding(.vertical, 15)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background { AppBackground() }
        .navigationTitle(L10n.stats)
        .task(id: model.libraryRevision) { await load() }
        .task(id: month) { await loadStats() }
    }

    private func load() async {
        months = (try? await model.database.playMonths()) ?? []
        if month == nil || !months.contains(month!) { month = months.first }
        await loadStats()
        loaded = true
    }

    private func loadStats() async {
        guard let month else {
            stats = nil
            return
        }
        stats = try? await model.database.monthStats(month)
    }

    // MARK: - Sections

    private var monthPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(months, id: \.self) { option in
                    Button {
                        Haptics.select()
                        month = option
                    } label: {
                        Text(Self.title(of: option))
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .foregroundStyle(option == month ? Color.black : Color.primary)
                            .background(
                                option == month ? Color.pongoTeal : Color.primary.opacity(0.08), in: .capsule)
                    }
                    .buttonStyle(.press)
                }
            }
            .padding(.horizontal, 15)
        }
        .scrollIndicators(.hidden)
    }

    private func summary(_ stats: MonthStats) -> some View {
        HStack(spacing: 10) {
            card(L10n.playsfull, "\(stats.plays)", "play.fill")
            card(L10n.minuteslistened, "\(Int((stats.seconds / 60).rounded()))", "clock.fill")
            card(L10n.songsplayed, "\(stats.trackCount)", "music.note")
        }
        .padding(.horizontal, 15)
    }

    private func card(_ title: String, _ value: String, _ systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.pongoCard.opacity(0.55), in: .rect(cornerRadius: 18, style: .continuous))
    }

    private func topArtists(_ stats: MonthStats) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(L10n.topartists)
            VStack(spacing: 0) {
                ForEach(Array(stats.artists.prefix(5).enumerated()), id: \.element.id) { index, stat in
                    Button {
                        Task { await model.showArtist(stat.artist) }
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 17, weight: .bold).monospacedDigit())
                                .foregroundStyle(Color.pongoTeal)
                                .frame(width: 26)
                            Text(stat.artist.name ?? L10n.artist)
                                .font(.system(size: 16.5, weight: .semibold))
                                .lineLimit(1)
                            Spacer()
                            Text(playsText(stat.plays))
                                .font(.system(size: 13).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 44)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.row)
                }
            }
            .padding(.horizontal, 15)
        }
    }

    private func topSongs(_ stats: MonthStats) -> some View {
        let tracks = stats.tracks.map(\.track)
        let collectionID = "stats.\(stats.month)"
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionTitle(L10n.topsongs)
                Spacer()
                Button(L10n.playall, systemImage: "play.fill") {
                    Haptics.tap()
                    Task { await model.player.playOnline(collectionID, tracks, durations: [:]) }
                }
                .buttonStyle(.glass)
                .padding(.trailing, 15)
            }
            LazyVStack(spacing: 0) {
                ForEach(Array(stats.tracks.enumerated()), id: \.element.id) { index, stat in
                    Button {
                        Task {
                            await model.player.playCollectionTrack(
                                collectionID: collectionID, stid: stat.track.id, index: index
                            ) { await model.player.playOnline(collectionID, tracks, durations: [:], index: index) }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 15, weight: .bold).monospacedDigit())
                                .foregroundStyle(index < 3 ? Color.pongoTeal : .secondary)
                                .frame(width: 26)
                            TrackRow(track: stat.track, collectionID: collectionID)
                            Text(playsText(stat.plays))
                                .font(.system(size: 13).monospacedDigit())
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                    }
                    .buttonStyle(.row)
                    .contextMenu { TrackMenu(track: stat.track, collectionID: collectionID) }
                }
            }
            .padding(.horizontal, 15)
        }
    }

    private func playsText(_ plays: Int) -> String {
        "\(plays) \(plays == 1 ? L10n.play1 : L10n.plays)"
    }

    /// `2026-11` as the month's name and year in the app's language.
    static func title(of month: String) -> String {
        let parts = month.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2,
            let date = Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: 1))
        else { return month }
        var style = Date.FormatStyle().year().month(.wide)
        style.locale = Locale(identifier: L10n.selectedLanguage)
        return date.formatted(style)
    }
}
