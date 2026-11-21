import SwiftUI

struct HaikuAccountView: View {
    @ObservedObject var auth: HaikuAuthStore
    @State private var email = ""
    @State private var password = ""
    @State private var isCreatingAccount = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("Haiku")
                .font(.system(size: 42, weight: .semibold, design: .serif))
                .foregroundStyle(HaikuTheme.foreground)
            Text("Your Carbyne account, everywhere.")
                .font(.system(size: 15))
                .foregroundStyle(HaikuTheme.secondary)
                .padding(.top, 8)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(15)
                    .background(HaikuTheme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                SecureField("Password", text: $password)
                    .textContentType(isCreatingAccount ? .newPassword : .password)
                    .padding(15)
                    .background(HaikuTheme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    Task {
                        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                        if isCreatingAccount {
                            await auth.signUp(email: cleanEmail, password: password)
                        } else {
                            await auth.signIn(email: cleanEmail, password: password)
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if auth.isLoading { ProgressView().tint(HaikuTheme.background) }
                        else { Text(isCreatingAccount ? "Create account" : "Continue") }
                        Spacer()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HaikuTheme.background)
                    .padding(.vertical, 15)
                    .background(HaikuTheme.foreground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(auth.isLoading || email.isEmpty || password.count < 6)

                Button(isCreatingAccount ? "Already have an account? Sign in" : "Create a Carbyne account") {
                    isCreatingAccount.toggle()
                    auth.errorMessage = nil
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(HaikuTheme.secondary)
                .padding(.top, 4)

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(20)
            .background(HaikuTheme.surface.opacity(0.82), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 24)
            .padding(.top, 34)
            Spacer()
            Text("One account for Haiku and Carbyne")
                .font(.system(size: 12))
                .foregroundStyle(HaikuTheme.secondary)
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HaikuTheme.background.ignoresSafeArea())
    }
}
