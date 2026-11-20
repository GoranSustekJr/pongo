import PDFKit
import PongoCore
import SwiftUI

/// The settings tab, as in the Flutter app: the profile, the preferences and
/// what Pongo is.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var profile: UserProfile?

    var body: some View {
        List {
            Section(L10n.profile) {
                NavigationLink(value: Route.profile) {
                    HStack(spacing: 14) {
                        CoverImage(profile?.picture, placeholder: "person.fill")
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile?.name ?? L10n.profile).font(.system(size: 17, weight: .semibold))
                            Text(L10n.yourprofile).font(.system(size: 13)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .groupedRowBackground()
            }
            Section(L10n.settings) {
                NavigationLink(value: Route.preferences) {
                    GroupedRow(systemImage: "slider.horizontal.3", title: L10n.preferences, subtitle: L10n.yourpreferences)
                }
                .groupedRowBackground()
            }
            Section(L10n.about) {
                NavigationLink(value: Route.about) {
                    GroupedRow(systemImage: "info.circle", title: L10n.about, subtitle: L10n.aboutpongo)
                }
                .groupedRowBackground()
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .navigationTitle(L10n.settings)
        .task { profile = try? await model.auth.fetchProfile() }
    }
}

extension SettingsRepository {
    /// A binding to one setting that saves it when changed.
    func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding { self.settings[keyPath: keyPath] } set: { value in self.update { $0[keyPath: keyPath] = value } }
    }
}

/// The signed in account and the app's language.
struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var profile: UserProfile?
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    var body: some View {
        let settings = model.settings
        List {
            Section {
                VStack(spacing: 10) {
                    CoverImage(profile?.picture, placeholder: "person.fill")
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                    Text(profile?.name ?? " ").font(.title2.bold())
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            Section {
                GroupedRow(systemImage: "person.fill", title: L10n.name, subtitle: profile?.name ?? "")
                    .groupedRowBackground()
                if profile?.hiddenAuth == true {
                    GroupedRow(systemImage: "eye.slash", title: L10n.hidden, subtitle: L10n.allofyourdataishidden)
                        .groupedRowBackground()
                } else {
                    GroupedRow(systemImage: "envelope.fill", title: L10n.email, subtitle: profile?.email ?? "")
                        .groupedRowBackground()
                }
                MenuRow(systemImage: "globe", title: L10n.language, selection: settings.binding(\.locale)) {
                    ForEach(SettingsRepository.languages, id: \.self) { code in
                        Text(Locale(identifier: code).localizedString(forLanguageCode: code)?.capitalized ?? code)
                            .tag(code)
                    }
                }
            }
            Section {
                Button(role: .destructive) {
                    confirmSignOut = true
                } label: {
                    GroupedRow(systemImage: "rectangle.portrait.and.arrow.right", title: L10n.signout)
                }
                .groupedRowBackground()
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    GroupedRow(systemImage: "trash", title: L10n.delete, subtitle: L10n.deleteyouraccount)
                }
                .groupedRowBackground()
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .navigationTitle(L10n.profile)
        .navigationBarTitleDisplayMode(.inline)
        .task { profile = try? await model.auth.fetchProfile() }
        .confirmationDialog(L10n.signout, isPresented: $confirmSignOut) {
            Button(L10n.signout, role: .destructive) { model.auth.signOut() }
        }
        .alert(L10n.deleteyouraccount, isPresented: $confirmDelete) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.delete, role: .destructive) {
                Task {
                    do { try await model.auth.deleteAccount() } catch {
                        model.messages.show(L10n.error, systemImage: "exclamationmark.triangle", isError: true)
                    }
                }
            }
        } message: {
            Text(L10n.areyousurezouwanttodeleteyouraccount)
        }
    }
}

/// Every preference, grouped and ordered as in the Flutter app.
struct PreferencesView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmHistory = false

    var body: some View {
        let settings = model.settings
        Form {
            Section(L10n.searchpreferences) {
                MenuRow(systemImage: "globe", title: L10n.searchmarket, selection: settings.binding(\.market)) {
                    ForEach(Markets.all, id: \.self) { code in
                        Text(verbatim: Locale.current.localizedString(forRegionCode: code) ?? code).tag(code)
                    }
                }
                count(L10n.artists, "music.microphone", \.searchArtistCount, 0...10)
                count(L10n.albums, "square.stack", \.searchAlbumCount, 0...10)
                count(L10n.tracks, "music.note", \.searchTrackCount, 0...50)
                count(L10n.playlists, "music.note.list", \.searchPlaylistCount, 0...20)
                Button {
                    confirmHistory = true
                } label: {
                    GroupedRow(systemImage: "clock.arrow.circlepath", title: L10n.clearallhistory)
                }
                .foregroundStyle(.red)
                .groupedRowBackground()
            }
            Section {
                toggle(L10n.showhistory, L10n.showhistoryonstartpage, "clock", \.enableHistory)
                toggle(L10n.showexplore, L10n.showexploreonstartpage, "sparkles", \.enableCategories)
                count(L10n.genres, "square.grid.2x2", \.categoryCount, 10...50, step: 10)
            } header: {
                Text(L10n.startpage)
            } footer: {
                Text(L10n.appmayneedtoberestartedinorderforchangestotakefullaffect)
            }
            Section(L10n.lyrics) {
                toggle(L10n.enablelyrics, L10n.enableusageoflyrics, "quote.bubble", \.enableLyrics)
                toggle(L10n.livelyrics, L10n.livelyricsdescription, "platter.filled.top.iphone", \.showLiveLyrics)
                MenuRow(
                    systemImage: "text.alignleft", title: L10n.lyircstextalignment,
                    selection: settings.binding(\.lyricsTextAlign)
                ) {
                    Text(L10n.lefttextalign).tag(LyricsAlignment.left)
                    Text(L10n.centertextalign).tag(LyricsAlignment.center)
                    Text(L10n.righttextalign).tag(LyricsAlignment.right)
                }
            }
            Section(L10n.audioplayer) {
                toggle(L10n.mix, L10n.usemixfeaturewhenplayingsearchedmusic, "sparkles", \.useMix)
                toggle(L10n.audioplayercaching, L10n.letaudioplayercachethesongs, "internaldrive", \.useCacheAudioSource)
                toggle(
                    L10n.streamwhiledownloading, L10n.streamwhiledownloadingdescription, "bolt.horizontal",
                    \.streamWhileDownloading)
                Stepper(value: settings.binding(\.crossfadeSeconds), in: 0...12) {
                    GroupedRow(systemImage: "wave.3.right", title: L10n.crossfade, subtitle: L10n.crossfadedescription) {
                        Text(model.settings.settings.crossfadeSeconds == 0
                            ? L10n.off : "\(model.settings.settings.crossfadeSeconds) s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .groupedRowBackground()
                toggle(L10n.gaplessalbums, L10n.gaplessalbumsdescription, "square.stack", \.gaplessAlbums)
                toggle(L10n.bassboost, L10n.bassboostdescription, "speaker.wave.2", \.bassBoost)
                toggle(L10n.smartshuffle, L10n.smartshuffledescription, "shuffle", \.smartShuffle)
                Button {
                    model.player.clearCache()
                    model.messages.show(L10n.successful, systemImage: "checkmark.circle")
                } label: {
                    GroupedRow(systemImage: "trash", title: L10n.clearaudioplayercache)
                }
                .foregroundStyle(.primary)
                .groupedRowBackground()
            }
            Section(L10n.images) {
                toggle(L10n.imagecaching, L10n.cacheimagestoreducenetworkactivity, "photo", \.cacheImages)
                Button {
                    Task {
                        await ImagePipeline.shared.clear()
                        model.messages.show(L10n.successful, systemImage: "checkmark.circle")
                    }
                } label: {
                    GroupedRow(systemImage: "trash", title: L10n.clearimagecache)
                }
                .foregroundStyle(.primary)
                .groupedRowBackground()
            }
            Section(L10n.userinterface) {
                toggle(L10n.useanimations, L10n.turnoffifanimationsaretoohardonthedevice, "wand.and.stars", \.useAnimations)
                toggle(L10n.liquidglass, L10n.useliquidglass, "drop", \.useLiquidGlass)
                toggle(L10n.dynamicblurhash, L10n.playingdetailsbackgroundwilldynamicallychange, "circle.hexagongrid", \.useDynamicBlurhash)
                toggle(
                    model.settings.settings.darkMode ? L10n.darkmode : L10n.lightmode,
                    model.settings.settings.darkMode ? L10n.currentlyusingdarkmode : L10n.currentlyusinglightmode,
                    model.settings.settings.darkMode ? "moon.fill" : "sun.max.fill", \.darkMode)
                toggle(L10n.useblur, L10n.turnoffifyourdeviceisgettinghotorhaslag, "camera.filters", \.useBlur)
            }
            Section(L10n.sleep) {
                toggle(L10n.linearsleepin, L10n.linearlydecreasevolumewhenusingsleepin, "moon.zzz", \.linearSleepIn)
                toggle(L10n.linearalarm, L10n.linearlyincreasevolumewhenusingalarm, "alarm", \.linearWakeUp)
            }
        }
        .formStyle(.grouped)
        .pongoBackground()
        .navigationTitle(L10n.preferences)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.settings.settings.enableLyrics) { model.nowPlaying.reloadLyrics() }
        .confirmationDialog(L10n.clearallhistory, isPresented: $confirmHistory, titleVisibility: .visible) {
            Button(L10n.clearallhistory, role: .destructive) {
                Task {
                    try? await model.database.clearSearches()
                    model.libraryChanged()
                }
            }
        } message: {
            Text(L10n.clearallhistorybody)
        }
    }

    private func toggle(
        _ title: String, _ subtitle: String, _ image: String, _ keyPath: WritableKeyPath<AppSettings, Bool>
    ) -> some View {
        Toggle(isOn: model.settings.binding(keyPath)) {
            GroupedRow(systemImage: image, title: title, subtitle: subtitle)
        }
        .tint(.pongoTeal)
        .groupedRowBackground()
    }

    private func count(
        _ title: String, _ image: String, _ keyPath: WritableKeyPath<AppSettings, Int>, _ range: ClosedRange<Int>,
        step: Int = 1
    ) -> some View {
        Stepper(value: model.settings.binding(keyPath), in: range, step: step) {
            GroupedRow(systemImage: image, title: title) {
                Text("\(model.settings.settings[keyPath: keyPath])")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .groupedRowBackground()
    }
}

/// What Pongo is and how to reach its makers.
struct AboutView: View {
    @Environment(AppModel.self) private var model
    private let mail = "pongo.group@gmail.com"

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    Image("Logo").resizable().scaledToFit().frame(width: 110, height: 110)
                    Text(verbatim: "Pongo").font(.title.bold())
                    Text("\(L10n.version) \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            Section(L10n.about) {
                Button {
                    copyToPasteboard(mail)
                    model.messages.show(mail, systemImage: "doc.on.doc")
                } label: {
                    GroupedRow(systemImage: "envelope.fill", title: mail, subtitle: L10n.contactusviamail) {
                        Image(systemName: "doc.on.doc").foregroundStyle(Color.pongoIcon)
                    }
                }
                .foregroundStyle(.primary)
                .groupedRowBackground()
                if let terms = Bundle.main.url(forResource: "Terms", withExtension: "pdf") {
                    NavigationLink {
                        PDFDocumentView(url: terms)
                            .ignoresSafeArea(edges: .bottom)
                            .navigationTitle(L10n.termsandconditions)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar { ShareLink(item: terms) }
                    } label: {
                        GroupedRow(
                            systemImage: "bookmark.fill", title: L10n.termsandconditions,
                            subtitle: L10n.ourtermsandconditions)
                    }
                    .groupedRowBackground()
                }
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .navigationTitle(L10n.aboutpongo)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A PDF shown page after page.
#if os(macOS)
    struct PDFDocumentView: NSViewRepresentable {
        let url: URL

        func makeNSView(context: Context) -> PDFView {
            let view = PDFView()
            view.autoScales = true
            view.backgroundColor = .clear
            view.document = PDFDocument(url: url)
            return view
        }

        func updateNSView(_ nsView: PDFView, context: Context) {}
    }
#else
    struct PDFDocumentView: UIViewRepresentable {
        let url: URL

        func makeUIView(context: Context) -> PDFView {
            let view = PDFView()
            view.autoScales = true
            view.backgroundColor = .clear
            view.document = PDFDocument(url: url)
            return view
        }

        func updateUIView(_ uiView: PDFView, context: Context) {}
    }
#endif

/// The countries whose catalogs search can use.
enum Markets {
    static let all = """
        AD AE AG AL AM AO AR AT AU AZ BA BB BD BE BF BG BH BI BJ BN BO BR BS BT BW BY BZ CA CD CG CH CI CL CM CO CR \
        CV CW CY CZ DE DJ DK DM DO DZ EC EE EG ES ET FI FJ FM FR GA GB GD GE GH GM GN GQ GR GT GW GY HK HN HR HT HU \
        ID IE IL IN IQ IS IT JM JO JP KE KG KH KI KM KN KR KW KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MG MH \
        MK ML MN MO MR MT MU MV MW MX MY MZ NA NE NG NI NL NO NP NR NZ OM PA PE PG PH PK PL PR PS PT PW PY QA RO RS \
        RW SA SB SC SE SG SI SK SL SM SN SR ST SV SZ TD TG TH TJ TL TN TO TR TT TV TW TZ UA UG US UY UZ VC VE VN VU \
        WS XK ZA ZM ZW
        """.split(separator: " ").map(String.init)
}
