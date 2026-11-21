import Foundation
import Combine
import Supabase

@MainActor
final class HaikuAuthStore: ObservableObject {
    @Published private(set) var session: Session?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let client = SupabaseClient(
        supabaseURL: URL(string: "https://vezpcrvdswyvcwdzyxnr.supabase.co")!,
        supabaseKey: "sb_publishable_M--uSWMfn3aXRzCf_9DceA_M1ttIkz4"
    )

    func observeSession() async {
        for await state in client.auth.authStateChanges {
            session = state.session
        }
    }

    func signIn(email: String, password: String) async {
        await perform {
            let response = try await client.auth.signIn(email: email, password: password)
            session = response
        }
    }

    func signUp(email: String, password: String) async {
        await perform {
            let response = try await client.auth.signUp(email: email, password: password)
            session = response.session
            if response.session == nil {
                errorMessage = "Check your email to confirm your account, then sign in."
            }
        }
    }

    func signOut() async {
        await perform {
            try await client.auth.signOut()
            session = nil
        }
    }

    private func perform(_ action: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await action()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
