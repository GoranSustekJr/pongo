import Charts
import PongoCore
import SwiftUI

/// What the user listened to most, by month or by year, on all their devices:
/// how much they played, their top artists and their top songs, which play
/// from here. A year also shows how much each of its months played.
struct StatsView: View {
    @Environment(AppModel.self) private var model
    @State private var byYear = false
    @State private var months: [String] = []
    @State private var years: [String] = []
    @State private var month: String?
    @State private var year: String?
    @State private var stats: MonthStats?
    @State private var yearMonths: [YearStats.Month] = []
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if !months.isEmpty {
                    Picker(L10n.stats, selection: $byYear) {
                        Text(L10n.month).tag(false)
                        Text(L10n.year).tag(true)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .padding(.horizontal, 15)
                    if byYear {
                        periodPicker(years, selection: $year, title: { $0 })
                    } else {
                        periodPicker(months, selection: $month, title: { Self.title(of: $0) })
                    }
                }
                if let stats, stats.plays > 0 {
                    summary(stats)
                    if byYear, yearMonths.count > 0 { monthsChart }
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
        .toolbar {
            // Your most played songs of all time, which used to be a screen of their own
            NavigationLink(value: Route.topSongs) {
                Label(L10n.top25, systemImage: "flame")
            }
        }
        .task(id: model.libraryRevision) { await load() }
        .task(id: "\(byYear)|\(month ?? "")|\(year ?? "")") { await loadStats() }
        .animation(.snappy, value: byYear)
    }

    private func load() async {
        let database = model.database
        months = (try? await database.playMonths()) ?? []
        years = (try? await database.playYears()) ?? []
        if month == nil || !months.contains(month!) { month = months.first }
        if year == nil || !years.contains(year!) { year = years.first }
        await loadStats()
        loaded = true
    }

    private func loadStats() async {
        let database = model.database
        if byYear, let year, let yearStats = try? await database.yearStats(year) {
            stats = yearStats.total
            yearMonths = yearStats.months
        } else if !byYear, let month {
            stats = try? await database.monthStats(month)
            yearMonths = []
        } else {
            stats = nil
            yearMonths = []
        }
    }

    // MARK: - Sections

    private func periodPicker(
        _ options: [String], selection: Binding<String?>, title: @escaping (String) -> String
    ) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let selected = option == selection.wrappedValue
                    Button {
                        Haptics.select()
                        selection.wrappedValue = option
                    } label: {
                        Text(title(option))
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .foregroundStyle(selected ? Color.black : Color.primary)
                            .background(selected ? Color.pongoTeal : Color.primary.opacity(0.08), in: .capsule)
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

    /// Minutes listened in each month of the year, the biggest one lit.
    private var monthsChart: some View {
        let biggest = yearMonths.max { $0.seconds < $1.seconds }
        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(L10n.minutespermonth)
            VStack(alignment: .leading, spacing: 10) {
                if let biggest {
                    Label {
                        Text("\(L10n.biggestmonth): \(Text(Self.title(of: biggest.month, year: false)).bold())")
                    } icon: {
                        Image(systemName: "crown.fill").foregroundStyle(Color.pongoTeal)
                    }
                    .font(.system(size: 14))
                }
                Chart(yearMonths) { month in
                    BarMark(
                        x: .value(L10n.month, Self.title(of: month.month, year: false, short: true)),
                        y: .value(L10n.minuteslistened, Int((month.seconds / 60).rounded()))
                    )
                    .foregroundStyle(month.id == biggest?.id ? Color.pongoTeal : Color.pongoTeal.opacity(0.45))
                    .cornerRadius(5)
                    .annotation(position: .top) {
                        Text("\(Int((month.seconds / 60).rounded()))")
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 170)
            }
            .padding(14)
            .background(Color.pongoCard.opacity(0.55), in: .rect(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 15)
        }
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
            RankedTracks(stats: stats.tracks, collectionID: collectionID)
        }
    }

    private func playsText(_ plays: Int) -> String {
        "\(plays) \(plays == 1 ? L10n.play1 : L10n.plays)"
    }

    /// `2026-11` as the month's name, with its year unless [year] is false,
    /// in the app's language.
    static func title(of month: String, year: Bool = true, short: Bool = false) -> String {
        let parts = month.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2,
            let date = Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: 1))
        else { return month }
        var style = Date.FormatStyle().month(short ? .abbreviated : .wide)
        if year { style = style.year() }
        style.locale = Locale(identifier: L10n.selectedLanguage)
        return date.formatted(style)
    }
}

/// Tracks ranked by plays, each playing the list from itself.
private struct RankedTracks: View {
    @Environment(AppModel.self) private var model
    let stats: [PlayStat]
    let collectionID: String

    var body: some View {
        let tracks = stats.map(\.track)
        LazyVStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
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
                        Text("\(stat.plays) \(stat.plays == 1 ? L10n.play1 : L10n.plays)")
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

/// The 25 songs played most this month, as a playlist that keeps itself up
/// to date; before anything played this month, last month's.
struct TopSongsView: View {
    @Environment(AppModel.self) private var model
    @State private var stats: MonthStats?
    @State private var loaded = false

    static let count = 25

    var body: some View {
        let collectionID = "stats.top25"
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let stats, !stats.tracks.isEmpty {
                    RankedTracks(stats: stats.tracks, collectionID: collectionID)
                } else if loaded {
                    EmptyMessage(systemImage: "chart.bar", title: L10n.nostatsyet, detail: L10n.nostatsyetdetail)
                        .padding(.top, 40)
                }
            }
            .padding(.vertical, 15)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background { AppBackground() }
        .navigationTitle(L10n.top25)
        .task(id: model.libraryRevision) {
            stats = try? await Self.load(model.database)
            loaded = true
        }
    }

    private var header: some View {
        let tracks = stats?.tracks.map(\.track) ?? []
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.top25).font(.system(size: 34, weight: .heavy))
                if let stats {
                    Text(StatsView.title(of: stats.month)).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    Task { await model.player.playOnline("stats.top25", tracks, durations: [:]) }
                } label: {
                    Label(L10n.play, systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                Button {
                    Haptics.tap()
                    Task { await model.player.playOnline("stats.top25", tracks, durations: [:], shuffle: true) }
                } label: {
                    Label(L10n.shuffle, systemImage: "shuffle").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
            }
            .controlSize(.large)
            .disabled(tracks.isEmpty)
        }
        .tint(.pongoTeal)
        .padding(.horizontal, 15)
    }

    /// This month's top songs, or the latest month's with plays.
    static func load(_ database: Database) async throws -> MonthStats? {
        let current = Database.month(of: .now)
        let month = try await database.playMonths().first { $0 <= current }
        guard let month else { return nil }
        return try await database.monthStats(month, limit: count)
    }
}
