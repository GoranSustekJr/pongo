import AuthenticationServices
import PongoCore
import SwiftUI

struct SignInView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @State private var signingIn = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("Logo").resizable().scaledToFit().frame(width: 170, height: 170)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            Text(verbatim: "Pongo").font(.system(size: 44, weight: .heavy)).tracking(-1)
            Spacer()
            Button {
                Task { await signIn() }
            } label: {
                HStack {
                    if signingIn { ProgressView() } else { Image(systemName: "person.crop.circle") }
                    Text(L10n.signinwithgoogle)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.pongoTeal)
            .controlSize(.extraLarge)
            .disabled(signingIn)
            Text(L10n.bysigninginyou).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(32)
        .background { AppBackground() }
    }

    private func signIn() async {
        signingIn = true
        defer { signingIn = false }
        let google = GoogleOAuth(clientID: model.config.googleClientID)
        do {
            let callback = try await webAuthenticationSession.authenticate(
                using: google.authorizationURL, callback: .customScheme(google.callbackScheme),
                preferredBrowserSession: .ephemeral, additionalHeaderFields: [:])
            let idToken = try await google.idToken(for: callback)
            if try await !model.auth.signIn(googleIDToken: idToken) {
                model.messages.show(L10n.signinfailed, systemImage: "exclamationmark.triangle", isError: true)
            }
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            return
        } catch {
            model.messages.show(L10n.signinfailed, systemImage: "exclamationmark.triangle", isError: true)
        }
    }
}
