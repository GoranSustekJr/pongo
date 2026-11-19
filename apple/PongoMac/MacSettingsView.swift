import PongoCore
import SwiftUI

/// The Settings window, in tabs as Mac apps have them: the preferences, the
/// account and about Pongo.
struct MacSettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let settings = model.settings.settings
        TabView {
            Tab(L10n.general, systemImage: "gearshape") {
                NavigationStack { PreferencesView() }
            }
            Tab(L10n.profile, systemImage: "person.crop.circle") {
                NavigationStack { ProfileView() }
            }
            .disabled(!model.auth.isSignedIn)
            Tab(L10n.about, systemImage: "info.circle") {
                NavigationStack { AboutView() }
            }
        }
        .scenePadding()
        .frame(width: 620, height: 640)
        .id(settings.locale)
        .environment(\.locale, Locale(identifier: settings.locale))
        .preferredColorScheme(settings.darkMode ? .dark : .light)
        .tint(.pongoTeal)
        .environment(\.usesLiquidGlass, settings.useLiquidGlass)
    }
}
