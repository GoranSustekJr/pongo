import PongoCore
import SwiftUI

/// Sign-in until there's a session, then the main window. Applies the
/// user's language, appearance and glass to everything in the window.
struct MacRootView: View {
    @Environment(AppModel.self) private var model
    @State private var keys = PlayerKeyMonitor()

    var body: some View {
        let settings = model.settings.settings
        Group {
            if model.auth.isSignedIn || isDemo {
                MainWindow()
            } else {
                SignInView()
                    .frame(minWidth: 520, minHeight: 560)
            }
        }
        .id(settings.locale)
        .environment(\.locale, Locale(identifier: settings.locale))
        .preferredColorScheme(settings.darkMode ? .dark : .light)
        .tint(.pongoTeal)
        .environment(\.usesLiquidGlass, settings.useLiquidGlass)
        .overlay(alignment: .top) { MacToasts() }
        .onAppear {
            keys.start(model)
            #if DEBUG
                if DemoMode.isOn { DemoMode.open(model) }
            #endif
        }
        .task(id: model.auth.isSignedIn) { await model.sessionChanged() }
        .onOpenURL { url in
            if model.openJoinLink(url) { return }
            switch url {
            case PongoLinks.player where model.player.current != nil:
                model.router.showsPlayer = true
            case PongoLinks.lyrics where model.player.current != nil:
                model.nowPlaying.lyricsOn = true
                model.router.showsPlayer = true
            case PongoLinks.topSongs:
                model.router.showsPlayer = false
                model.router.section = .topSongs
            default:
                break
            }
        }
        .sheet(item: Binding { model.listening.recap } set: { if $0 == nil { model.listening.dismissRecap() } }) { recap in
            SessionRecapView(recap: recap)
        }
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

/// The toasts, sliding down under the toolbar.
private struct MacToasts: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack {
            if let toast = model.messages.current {
                ToastView(toast: toast)
                    .frame(maxWidth: 440)
                    .onTapGesture { model.messages.dismiss() }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 8)
        .animation(.spring(duration: 0.4, bounce: 0.25), value: model.messages.current)
    }
}
