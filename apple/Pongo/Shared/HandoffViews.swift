import PongoCore
import SwiftUI

extension LinkedDevice {
    /// The symbol of the kind of device it is, going by its name.
    var symbol: String {
        if name.localizedCaseInsensitiveContains("iPhone") { return "iphone" }
        if name.localizedCaseInsensitiveContains("iPad") { return "ipad" }
        return "laptopcomputer"
    }
}

/// Menu items that move the music to another of the user's open devices, or
/// bring another device's music here.
struct TransferMenuItems: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let handoff = model.handoff
        Section(L10n.transferto) {
            ForEach(handoff.devices) { device in
                Button(device.name, systemImage: device.symbol) {
                    Haptics.tap()
                    handoff.transfer(to: device)
                }
                .disabled(!handoff.canTransfer)
            }
        }
        Section(L10n.getqueuefrom) {
            ForEach(handoff.devices) { device in
                Button(device.name, systemImage: "arrow.down.circle") {
                    Haptics.tap()
                    handoff.requestQueue(from: device)
                }
                .disabled(handoff.busyWith != nil)
            }
        }
    }
}
