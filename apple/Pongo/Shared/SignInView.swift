import AuthenticationServices
import PongoCore
import SwiftUI

/// The first screen: which server to use, then signing in to it with a
/// username and password or with Google, whichever the server offers.
struct SignInView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @State private var info: ServerInfo?
    @State private var infoFailed = false
    @State private var editingServer = false
    @State private var username = ""
    @State private var password = ""
    @State private var creating = false
    @State private var busy = false
    @State private var problem: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image("Logo").resizable().scaledToFit().frame(width: 140, height: 140)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    .padding(.top, 40)
                Text(verbatim: info?.name ?? "Pongo").font(.system(size: 40, weight: .heavy)).tracking(-1)
                if !model.hasServer || editingServer {
                    ServerForm(editing: $editingServer)
                } else {
                    serverRow
                    signInOptions
                }
            }
            .frame(maxWidth: 420)
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background { AppBackground() }
        .task(id: "\(model.hasServer) \(model.chosenServer ?? "")") { await loadInfo() }
        .onAppear {
            if model.editServerOnSignIn {
                editingServer = true
                model.editServerOnSignIn = false
            }
        }
    }

    private var serverRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "server.rack").foregroundStyle(.secondary)
            Text(verbatim: Self.shortAddress(model.config.serverURL))
                .font(.subheadline).lineLimit(1).truncationMode(.middle)
            Spacer()
            Button(L10n.changeserver) { editingServer = true }.font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder private var signInOptions: some View {
        if let info {
            let google = info.google && !model.config.googleClientID.isEmpty
            if info.passwords {
                passwordForm(signup: info.signup)
            }
            if google {
                if info.passwords { Text(L10n.or).font(.footnote).foregroundStyle(.secondary) }
                Button {
                    Task { await signInWithGoogle() }
                } label: {
                    Label(L10n.signinwithgoogle, systemImage: "person.crop.circle").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.extraLarge)
                .disabled(busy)
            }
            if !info.passwords && !google {
                Text(L10n.nosigninmethod).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            if let problem {
                Text(problem).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }
            Text(L10n.bysigninginyou).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
        } else if infoFailed {
            Text(L10n.noserveranswered).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button(L10n.tryagain) { Task { await loadInfo() } }
        } else {
            ProgressView()
        }
    }

    private func passwordForm(signup: Bool) -> some View {
        VStack(spacing: 12) {
            FieldBox {
                TextField(L10n.username, text: $username)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                    #endif
            }
            FieldBox {
                SecureField(creating ? "\(L10n.password) (\(L10n.passwordrules))" : L10n.password, text: $password)
                    .textContentType(creating ? .newPassword : .password)
                    .onSubmit { Task { await signInWithPassword() } }
            }
            Button {
                Task { await signInWithPassword() }
            } label: {
                HStack {
                    if busy { ProgressView() }
                    Text(creating ? L10n.createaccount : L10n.signin)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.pongoTeal)
            .controlSize(.extraLarge)
            .disabled(busy || username.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)
            if signup {
                Button(creating ? L10n.haveanaccount : L10n.newhere) {
                    creating.toggle()
                    problem = nil
                }
                .font(.subheadline)
            }
        }
    }

    private func loadInfo() async {
        info = nil
        infoFailed = false
        problem = nil
        guard model.hasServer else { return }
        await model.config.servers.choose()
        do {
            let loaded = try await ServerInfo.fetch(baseURL: model.config.serverURL)
            info = loaded
            if !loaded.signup { creating = false }
        } catch {
            infoFailed = true
        }
    }

    private func signInWithPassword() async {
        guard !busy else { return }
        busy = true
        problem = nil
        defer { busy = false }
        do {
            try await model.auth.signIn(
                username: username.trimmingCharacters(in: .whitespaces), password: password, create: creating)
            password = ""
        } catch let APIError.status(_, detail) where !detail.isEmpty {
            problem = detail
        } catch {
            problem = L10n.signinfailed
        }
    }

    private func signInWithGoogle() async {
        busy = true
        problem = nil
        defer { busy = false }
        let google = GoogleOAuth(clientID: model.config.googleClientID)
        do {
            let callback = try await webAuthenticationSession.authenticate(
                using: google.authorizationURL, callback: .customScheme(google.callbackScheme),
                preferredBrowserSession: .ephemeral, additionalHeaderFields: [:])
            let idToken = try await google.idToken(for: callback)
            if try await !model.auth.signIn(googleIDToken: idToken) { problem = L10n.signinfailed }
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            return
        } catch let APIError.status(_, detail) where !detail.isEmpty {
            problem = detail
        } catch {
            problem = L10n.signinfailed
        }
    }

    /// The host and port of a base URL, without the scheme.
    static func shortAddress(_ url: String) -> String {
        guard let components = URLComponents(string: url), let host = components.host else { return url }
        return components.port.map { "\(host):\($0)" } ?? host
    }
}

/// Asks for the address of the user's Pongo server and checks that one
/// answers there before using it.
struct ServerForm: View {
    @Environment(AppModel.self) private var model
    @Binding var editing: Bool
    @State private var address = ""
    @State private var checking = false
    @State private var failed = false

    var body: some View {
        VStack(spacing: 14) {
            Text(L10n.connecttoserver).font(.title3.bold())
            Text(L10n.connecttoserverhint).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            FieldBox {
                TextField(L10n.serveraddress, text: $address, prompt: Text(verbatim: "192.168.1.10"))
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    #endif
                    .onSubmit { Task { await connect() } }
            }
            if failed {
                Text(L10n.noserveranswered).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }
            Button {
                Task { await connect() }
            } label: {
                HStack {
                    if checking { ProgressView() }
                    Text(L10n.connect)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.pongoTeal)
            .controlSize(.extraLarge)
            .disabled(checking || ServerInfo.normalize(address) == nil)
            if model.chosenServer != nil, !AppModel.builtInServers.isEmpty {
                Button(L10n.usebuiltinserver) {
                    Task {
                        await model.setServer(nil)
                        editing = false
                    }
                }
                .font(.subheadline)
            }
            if model.hasServer {
                Button(L10n.cancel) { editing = false }.font(.subheadline)
            }
        }
        .onAppear {
            if model.hasServer { address = model.config.serverURL }
        }
    }

    private func connect() async {
        guard let url = ServerInfo.normalize(address) else { return }
        checking = true
        failed = false
        defer { checking = false }
        do {
            _ = try await ServerInfo.fetch(baseURL: url)
            await model.setServer(url)
            editing = false
        } catch {
            failed = true
        }
    }
}

/// A text field on a rounded background.
private struct FieldBox<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .textFieldStyle(.plain)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
