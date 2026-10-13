import KnotenCore
import SwiftUI

struct LoginView: View {
    @Environment(SessionModel.self) private var session
    @State private var handle = ""

    var body: some View {
        List {
            Section {
                TextField("Handle", text: $handle)
                    .font(.identifier())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)

                Button("Sign in") {
                    Task { await session.login(handle: handle.trimmingCharacters(in: .whitespaces)) }
                }
                .disabled(signingIn)
            }

            if case .failed(let error) = session.state {
                Section {
                    Text(error.localizedDescription)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sign in")
    }

    private var signingIn: Bool {
        if case .signingIn = session.state { return true }
        return false
    }
}
