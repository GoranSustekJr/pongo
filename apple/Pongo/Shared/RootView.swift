import Observation
import PongoCore
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var toasts = ToastWindow()

    var body: some View {
        let settings = model.settings.settings
        Group {
            if model.auth.isSignedIn || isDemo {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .id(settings.locale)
        .environment(\.locale, Locale(identifier: settings.locale))
        .preferredColorScheme(settings.darkMode ? .dark : .light)
        .tint(.pongoTeal)
        .environment(\.usesLiquidGlass, settings.useLiquidGlass)
        // A tap on the live lyrics
        .onOpenURL { url in
            if model.openJoinLink(url) || model.openFriendLink(url) { return }
            switch url {
            case PongoLinks.lyrics where model.player.current != nil:
                model.nowPlaying.lyricsOn = true
                model.router.showsPlayer = true
            case PongoLinks.player where model.player.current != nil:
                model.router.showsPlayer = true
            case PongoLinks.topSongs:
                model.router.showsPlayer = false
                model.router.tab = .library
                model.router.library = [.topSongs]
            default:
                break
            }
        }
        .onAppear {
            toasts.install(model: model)
            #if DEBUG
                if DemoMode.isOn { DemoMode.open(model) }
            #endif
        }
        .task(id: model.auth.isSignedIn) { await model.sessionChanged() }
        .onChange(of: model.settings.settings) { model.applyPreferences() }
        .onChange(of: model.sync.revision) { Task { await model.reloadLibraryIDs() } }
        .onChange(of: model.auth.disabledCount) {
            model.messages.show(L10n.accountdisabled, systemImage: "person.crop.circle.badge.xmark", isError: true)
        }
    }
}

private var isDemo: Bool {
    #if DEBUG
        DemoMode.isOn
    #else
        false
    #endif
}

struct MainTabView: View {
    @Environment(AppModel.self) private var model
    @Namespace private var playerTransition

    var body: some View {
        @Bindable var router = model.router
        TabView(selection: $router.tab) {
            Tab(L10n.home, systemImage: "house.fill", value: AppTab.home) {
                NavigationStack(path: $router.home) {
                    HomeView().navigationDestination(for: Route.self, destination: RouteView.init)
                }
                // Controls are white; teal marks what is on or selected
                .tint(.primary)
            }
            Tab(L10n.library, systemImage: "square.stack.fill", value: AppTab.library) {
                NavigationStack(path: $router.library) {
                    LibraryView().navigationDestination(for: Route.self, destination: RouteView.init)
                }
                // Controls are white; teal marks what is on or selected
                .tint(.primary)
            }
            Tab(L10n.search, systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                SearchScreen()
            }
        }
        // Lists run behind the glass bars without being blurred under them
        .scrollEdgeEffectHidden(true, for: .all)
        .tabBarMinimizeBehavior(.onScrollDown)
        #if DEBUG
            .defaultScrollAnchor(DemoMode.scrolled ? .bottom : DemoMode.middle ? .center : nil)
        #endif
        .tabViewBottomAccessory(isEnabled: model.player.current != nil) {
            MiniPlayer()
                .matchedTransitionSource(id: "player", in: playerTransition)
        }
        .overlay { ReactionsOverlay() }
        // Joining from a link, with no player open to show the session in
        .sheet(isPresented: Binding { model.showsListenTogether && !model.router.showsPlayer } set: { model.showsListenTogether = $0 }) {
            ListenTogetherView()
        }
        .sheet(item: Binding { model.listening.recap } set: { if $0 == nil { model.listening.dismissRecap() } }) { recap in
            SessionRecapView(recap: recap)
        }
        .sheet(isPresented: $router.showsSettings) {
            NavigationStack(path: $router.settings) {
                SettingsView()
                    .navigationDestination(for: Route.self, destination: RouteView.init)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(L10n.done, systemImage: "checkmark") { router.showsSettings = false }
                        }
                    }
            }
            .tint(.primary)
        }
        .fullScreenCover(isPresented: $router.showsPlayer) {
            NowPlayingView()
                .overlay { ReactionsOverlay() }
                .navigationTransition(.zoom(sourceID: "player", in: playerTransition))
        }
        // The player shows the picker itself while it's open
        .sheet(
            item: Binding {
                router.showsPlayer ? nil : model.playlistRequest
            } set: { model.playlistRequest = $0 }
        ) { request in
            PlaylistPicker(request: request)
        }
        .sheet(
            item: Binding {
                router.showsPlayer ? nil : model.versionRequest
            } set: { model.versionRequest = $0 }
        ) { track in
            NavigationStack { TrackVersionsView(track: track) }
        }
        .alert(
            L10n.invitetitle,
            isPresented: Binding { model.invites.first != nil } set: { _ in },
            presenting: model.invites.first
        ) { invite in
            Button(L10n.join) { model.answer(invite, accept: true) }
            Button(L10n.notnow, role: .cancel) { model.answer(invite, accept: false) }
        } message: { invite in
            Text("\(invite.from.name) \(L10n.invitebody)")
        }
        .alert(L10n.haltmusicplayer, isPresented: $router.confirmsHalt) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.halt, role: .destructive) { model.player.halt() }
        } message: {
            Text(L10n.haltmusicplayerbody)
        }
    }
}
