import PongoCore
import SwiftUI

/// Starting, joining and running a session of listening together: the code
/// friends join with, what guests may do, and who's listening.
struct ListenTogetherView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var startRights = ListenPreset.party.rights
    @State private var code = ""

    var body: some View {
        let session = model.listening
        NavigationStack {
            Form {
                if session.isActive {
                    activeSections(session)
                } else {
                    idleSections(session)
                }
            }
            .formStyle(.grouped)
            .tint(.pongoTeal)
            .pongoBackground()
            .navigationTitle(L10n.listentogether)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(L10n.done) { dismiss() } }
            }
            .animation(.snappy, value: session.state)
            .animation(.snappy, value: session.listeners)
        }
        #if os(macOS)
            .frame(width: 480, height: 640)
        #endif
    }

    // MARK: - Not in a session

    @ViewBuilder private func idleSections(_ session: ListeningSession) -> some View {
        Section {
            VStack(spacing: 10) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.pongoTeal)
                Text(L10n.listentogetherbody)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .groupedRowBackground()
        Section(L10n.guestscan) {
            RightsEditor(rights: startRights) { startRights = $0 }
        }
        .groupedRowBackground()
        Section {
            Button {
                Haptics.tap()
                session.host(rights: startRights)
            } label: {
                Label(L10n.startsession, systemImage: "dot.radiowaves.left.and.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .disabled(model.player.current == nil)
        }
        .listRowBackground(Color.clear)
        Section(L10n.joinsession) {
            HStack {
                TextField(L10n.sessioncode, text: $code)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.characters)
                    #endif
                    .onChange(of: code) { code = String(code.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6)) }
                    .onSubmit(join)
                Button(L10n.join, action: join)
                    .buttonStyle(.glass)
                    .disabled(code.count < 6)
            }
        }
        .groupedRowBackground()
    }

    private func join() {
        guard code.count == 6 else { return }
        Haptics.tap()
        model.listening.join(code)
    }

    // MARK: - In a session

    @ViewBuilder private func activeSections(_ session: ListeningSession) -> some View {
        Section {
            if let code = session.code {
                VStack(spacing: 6) {
                    Text(code)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .tracking(6)
                        .textSelection(.enabled)
                    Text(L10n.sharesessioncode)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button(L10n.copycode, systemImage: "doc.on.doc") {
                            copyToPasteboard(code)
                            Haptics.tap()
                        }
                        ShareLink(item: "\(L10n.listentogether) · Pongo: \(code)") {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .buttonStyle(.glass)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            if session.state != .live {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text(session.state == .reconnecting ? L10n.reconnecting : L10n.connecting)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            if session.isPausedHere {
                Label(L10n.pausedhere, systemImage: "pause.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .groupedRowBackground()
        if session.state == .live || session.code != nil {
            if session.isHost {
                Section(L10n.guestscan) {
                    RightsEditor(rights: session.guestRights) { session.setGuestRights($0) }
                }
                .groupedRowBackground()
            } else {
                Section(L10n.youcan) {
                    RightsList(rights: session.rights)
                }
                .groupedRowBackground()
            }
            Section(L10n.listeners) {
                ForEach(session.listeners) { listener in
                    ListenerRow(listener: listener)
                }
            }
            .groupedRowBackground()
        }
        Section {
            Button(L10n.leavesession, systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                Haptics.tap()
                session.leave()
            }
            .frame(maxWidth: .infinity)
        }
        .groupedRowBackground()
    }
}

/// The presets, and switches for each right once the user picks their own.
private struct RightsEditor: View {
    let rights: Set<ListenRight>
    let change: (Set<ListenRight>) -> Void
    @State private var customizing = false

    var body: some View {
        let preset = customizing ? nil : ListenPreset.matching(rights)
        ForEach(ListenPreset.allCases, id: \.self) { option in
            PresetRow(
                title: option.title, detail: option.detail, systemImage: option.systemImage, selected: preset == option
            ) {
                customizing = false
                change(option.rights)
            }
        }
        PresetRow(
            title: L10n.presetcustom, detail: nil, systemImage: "slider.horizontal.3", selected: preset == nil
        ) {
            customizing = true
        }
        if preset == nil {
            ForEach(ListenRight.allCases, id: \.self) { right in
                Toggle(isOn: Binding {
                    rights.contains(right)
                } set: { on in
                    var rights = rights
                    if on { rights.insert(right) } else { rights.remove(right) }
                    change(rights)
                }) {
                    Label(right.title, systemImage: right.systemImage)
                }
                .padding(.leading, 30)
            }
        }
    }
}

private struct PresetRow: View {
    let title: String
    let detail: String?
    let systemImage: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.pongoTeal)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).foregroundStyle(.primary)
                    if let detail {
                        Text(detail).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark").fontWeight(.semibold).foregroundStyle(Color.pongoTeal)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// What a guest may do, as a list.
private struct RightsList: View {
    let rights: Set<ListenRight>

    var body: some View {
        if rights.isEmpty {
            Label(L10n.onlylisten, systemImage: "headphones")
        } else {
            ForEach(ListenRight.allCases.filter(rights.contains), id: \.self) { right in
                Label(right.title, systemImage: right.systemImage)
            }
        }
    }
}

/// Someone in the session; the host can pass them the aux or give them
/// rights of their own.
private struct ListenerRow: View {
    @Environment(AppModel.self) private var model
    let listener: Listener

    var body: some View {
        let session = model.listening
        let isHost = listener.id == session.hostID
        let isMe = listener.id == session.userID
        HStack(spacing: 12) {
            ListenerAvatar(listener: listener, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(listener.name.isEmpty ? L10n.listeners : listener.name).lineLimit(1)
                    if isMe { Text("(\(L10n.you))").foregroundStyle(.secondary) }
                }
                if isHost {
                    Label(L10n.host, systemImage: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(Color.pongoTeal)
                } else if !listener.isPresent {
                    Text(L10n.away).font(.caption).foregroundStyle(.secondary)
                } else if listener.hasOwnRights {
                    Text(L10n.theirownrights).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if session.isHost && !isHost {
                Menu {
                    Button(L10n.makehost, systemImage: "crown") { session.handOver(to: listener.id) }
                        .disabled(!listener.isPresent)
                    Section(L10n.theirownrights) {
                        ForEach(ListenRight.allCases, id: \.self) { right in
                            Toggle(isOn: Binding {
                                listener.rights.contains(right)
                            } set: { on in
                                var rights = listener.rights
                                if on { rights.insert(right) } else { rights.remove(right) }
                                session.setRights(rights, for: listener.id)
                            }) {
                                Label(right.title, systemImage: right.systemImage)
                            }
                        }
                    }
                    if listener.hasOwnRights {
                        Button(L10n.sameaseveryone, systemImage: "arrow.uturn.backward") {
                            session.setRights(nil, for: listener.id)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.system(size: 20))
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .opacity(listener.isPresent ? 1 : 0.55)
    }
}

/// A listener's profile picture.
struct ListenerAvatar: View {
    let listener: Listener
    var size: CGFloat

    var body: some View {
        CoverImage(listener.picture.isEmpty ? nil : listener.picture, placeholder: "person.fill")
            .frame(width: size, height: size)
            .clipShape(.circle)
    }
}

/// Who's listening along, above the queue, which opens the session.
struct ListeningBanner: View {
    @Environment(AppModel.self) private var model
    let open: () -> Void

    var body: some View {
        let session = model.listening
        let others = session.listeners.filter { $0.id != session.userID && $0.isPresent }
        Button(action: open) {
            HStack(spacing: 10) {
                HStack(spacing: -8) {
                    ForEach(others.prefix(4)) { listener in
                        ListenerAvatar(listener: listener, size: 26)
                            .overlay(Circle().stroke(.black.opacity(0.4), lineWidth: 1.5))
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(L10n.listentogether).font(.system(size: 14, weight: .semibold))
                    Text(subtitle(session, others))
                        .font(.system(size: 12))
                        .opacity(0.7)
                        .lineLimit(1)
                }
                Spacer()
                if session.state == .reconnecting || session.state == .connecting {
                    ProgressView().controlSize(.small).tint(.white)
                } else if let code = session.code {
                    Text(code).font(.system(size: 13, weight: .semibold, design: .monospaced)).opacity(0.75)
                }
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).opacity(0.6)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(.white.opacity(0.12), in: .rect(cornerRadius: 14, style: .continuous))
            .contentShape(.rect)
        }
        .buttonStyle(.press)
    }

    private func subtitle(_ session: ListeningSession, _ others: [Listener]) -> String {
        if session.isPausedHere { return L10n.pausedhere }
        let names = others.map(\.name).filter { !$0.isEmpty }
        if names.isEmpty { return session.isHost ? L10n.sharesessioncode : L10n.connecting }
        return "\(L10n.listeningwith) \(ListFormatter.localizedString(byJoining: names))"
    }
}

extension ListenRight {
    var title: String {
        switch self {
        case .add: L10n.rightadd
        case .playback: L10n.rightplayback
        case .manage: L10n.rightmanage
        case .modes: L10n.rightmodes
        case .takeover: L10n.righttakeover
        }
    }

    var systemImage: String {
        switch self {
        case .add: "plus.circle"
        case .playback: "playpause"
        case .manage: "arrow.up.arrow.down"
        case .modes: "shuffle"
        case .takeover: "music.note.list"
        }
    }
}

extension ListenPreset {
    var title: String {
        switch self {
        case .listenAlong: L10n.presetlistenalong
        case .party: L10n.presetparty
        case .coPilot: L10n.presetcopilot
        }
    }

    var detail: String {
        switch self {
        case .listenAlong: L10n.presetlistenalongbody
        case .party: L10n.presetpartybody
        case .coPilot: L10n.presetcopilotbody
        }
    }

    var systemImage: String {
        switch self {
        case .listenAlong: "headphones"
        case .party: "party.popper"
        case .coPilot: "person.2"
        }
    }
}
