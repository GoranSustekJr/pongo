import PongoCore
import SwiftUI

/// The Settings window, in tabs as Mac apps have them: the preferences, the
/// account and about Pongo.
struct MacSettingsView: View {
    enum Pane: String {
        case general, profile, about
    }

    /// Where the open tab is kept, so the sidebar's account button can pick it.
    static let tabKey = "macSettingsTab"

    @Environment(AppModel.self) private var model
    @AppStorage(tabKey) private var tab = Pane.general

    var body: some View {
        let settings = model.settings.settings
        TabView(selection: $tab) {
            Tab(L10n.general, systemImage: "gearshape", value: Pane.general) {
                NavigationStack { PreferencesView() }
            }
            Tab(L10n.profile, systemImage: "person.crop.circle", value: Pane.profile) {
                NavigationStack { ProfileView() }
            }
            .disabled(!model.auth.isSignedIn)
            Tab(L10n.about, systemImage: "info.circle", value: Pane.about) {
                NavigationStack { AboutView() }
            }
        }
        .frame(width: 620, height: 640)
        .id(settings.locale)
        .environment(\.locale, Locale(identifier: settings.locale))
        .preferredColorScheme(settings.darkMode ? .dark : .light)
        .tint(.pongoTeal)
        .environment(\.usesLiquidGlass, settings.useLiquidGlass)
    }
}
