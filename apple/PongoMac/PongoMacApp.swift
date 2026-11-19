import PongoCore
import SwiftUI

@main
struct PongoMacApp: App {
    @State private var model: AppModel? = try? AppModel()

    var body: some Scene {
        WindowGroup("Pongo", id: "main") {
            if let model {
                MacRootView()
                    .environment(model)
                    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                        model.player.saveState()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                        model.player.saveState()
                    }
            } else {
                ContentUnavailableView("Pongo", systemImage: "exclamationmark.triangle", description: Text(L10n.error))
            }
        }
        .defaultSize(width: 1240, height: 800)
        .windowToolbarStyle(.unified)
        .commands {
            if let model { PlayerCommands(model: model) }
            // One window holds the whole library, as in Mac music apps
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            if let model {
                MacSettingsView().environment(model)
            }
        }
    }
}
