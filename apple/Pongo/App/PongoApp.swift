import PongoCore
import SwiftUI

@main
struct PongoApp: App {
    @State private var model: AppModel? = try? AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if let model {
                RootView()
                    .environment(model)
                    .onChange(of: scenePhase) { _, phase in
                        if phase != .active { model.player.saveState() }
                        // Away from home or back on its network, a different address may answer
                        if phase == .active { Task { await model.config.servers.choose() } }
                    }
            } else {
                ContentUnavailableView("Pongo", systemImage: "exclamationmark.triangle", description: Text(L10n.error))
            }
        }
    }
}
