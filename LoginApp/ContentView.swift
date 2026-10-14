import SwiftUI

struct ContentView: View {

    private enum Field: Hashable {
        case email
        case password
    }

    private struct LoginAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @State private var email = ""
    @State private var password = ""
    @State private var validationMessage: String?
    @State private var isLoggingIn = false
    @State private var loginAlert: LoginAlert?

    @FocusState private var focusedField: Field?

    private let networkingService = NetworkingService()

    var body: some View {
        VStack(spacing: 24) {
            header
            form
            validationHint
            loginButton
            ProgressView("Logging in…")
                // Kept in the layout at zero opacity so nothing jumps around.
                .opacity(isLoggingIn ? 1 : 0)
                .accessibilityHidden(!isLoggingIn)
            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
        .disabled(isLoggingIn)
        .animation(.default, value: validationMessage)
        .animation(.default, value: isLoggingIn)
        .alert(
            loginAlert?.title ?? "",
            isPresented: Binding(
                get: { loginAlert != nil },
                set: { isPresented in
                    if !isPresented { loginAlert = nil }
                }
            ),
            presenting: loginAlert
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { alert in
            Text(alert.message)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Welcome back")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Sign in to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
        .multilineTextAlignment(.center)
    }

    private var form: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Email")
                    .frame(width: 80, alignment: .leading)
                // `verbatim` keeps SwiftUI from turning the placeholder into
                // an auto-detected mailto link.
                TextField(text: $email, prompt: Text(verbatim: "name@example.com")) {
                    Text("Email")
                }
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focusedField, equals: .email)
            }

            Divider()

            HStack {
                Text("Password")
                    .frame(width: 80, alignment: .leading)
                SecureField("Required", text: $password)
                    .textContentType(.password)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
            }
        }
        .textFieldStyle(.plain)
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                login()
            case nil:
                break
            }
        }
    }

    @ViewBuilder
    private var validationHint: some View {
        if let validationMessage {
            Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
        }
    }

    private var loginButton: some View {
        Button(action: login) {
            Text("Log in")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private func login() {
        focusedField = nil

        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Please enter your email address."
            focusedField = .email
            return
        }

        guard !password.isEmpty else {
            validationMessage = "Please enter your password."
            focusedField = .password
            return
        }

        validationMessage = nil
        isLoggingIn = true

        networkingService.login(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password
        ) { user, error in
            if let user {
                loginAlert = LoginAlert(
                    title: "Login successful",
                    message: "Welcome back, \(user.displayName.isEmpty ? user.email : user.displayName)!"
                )
                password = ""
            } else if let error {
                loginAlert = LoginAlert(title: error.title, message: error.message)
            }

            isLoggingIn = false
        }
    }
}

#Preview {
    ContentView()
}
