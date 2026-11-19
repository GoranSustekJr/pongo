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
            guard url == PongoLinks.lyrics, model.player.current != nil else { return }
            model.nowPlaying.lyricsOn = true
            model.router.showsPlayer = true
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
            Tab(L10n.settings, systemImage: "gearshape.fill", value: AppTab.settings) {
                NavigationStack(path: $router.settings) {
                    SettingsView().navigationDestination(for: Route.self, destination: RouteView.init)
                }
                // Controls are white; teal marks what is on or selected
                .tint(.primary)
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
        .fullScreenCover(isPresented: $router.showsPlayer) {
            NowPlayingView()
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
        .alert(L10n.haltmusicplayer, isPresented: $router.confirmsHalt) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.halt, role: .destructive) { model.player.halt() }
        } message: {
            Text(L10n.haltmusicplayerbody)
        }
    }
}
