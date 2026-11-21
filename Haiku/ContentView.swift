import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

private enum HaikuDestination: Hashable {
    case chat
    case settings
}

struct ContentView: View {
    @State private var isShowingSplash = true
    @State private var selection: HaikuDestination? = .chat
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []

    var body: some View {
        Group {
            if isShowingSplash {
                HaikuTheme.background
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else {
                NavigationSplitView {
                    sidebar
                } detail: {
                    detailView
                }
                .navigationSplitViewStyle(.balanced)
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
                .tint(HaikuTheme.accent)
                .transition(.opacity)
            }
        }
        .preferredColorScheme(nil)
        .task {
            try? await Task.sleep(for: .milliseconds(650))
            withAnimation(.easeInOut(duration: 0.45)) {
                isShowingSplash = false
            }
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section {
                NavigationLink(value: HaikuDestination.chat) {
                    Label("New chat", systemImage: "square.and.pencil")
                }
                .simultaneousGesture(TapGesture().onEnded {
                    messages.removeAll()
                    messageText = ""
                })
            }

            Section("Recent") {
                Text("Your conversations will appear here.")
                    .font(.footnote)
                    .foregroundStyle(HaikuTheme.secondary)
                    .listRowBackground(Color.clear)
                    .selectionDisabled()
            }

            Section {
                NavigationLink(value: HaikuDestination.settings) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(HaikuTheme.background)
        .navigationTitle("Haiku")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .settings:
            settingsScreen
        case .chat, .none:
            chatScreen
        }
    }

    private var settingsScreen: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 28, weight: .semibold))
            Text("Settings will be available in a future build.")
                .font(.system(size: 15))
                .foregroundStyle(HaikuTheme.secondary)
            Spacer()
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(HaikuTheme.foreground)
        .background(HaikuTheme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chatScreen: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(messages) { message in
                        messageRow(message)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .scrollDismissesKeyboard(.interactively)

            composer
        }
        .foregroundStyle(HaikuTheme.foreground)
        .background(HaikuTheme.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("Haiku")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Spacer()
            Button {
                messages.removeAll()
                messageText = ""
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .regular))
                    .frame(width: 42, height: 42)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("New chat")
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .foregroundStyle(HaikuTheme.foreground)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message Haiku", text: $messageText, axis: .vertical)
                .font(.system(size: 16))
                .lineLimit(1...5)
                .padding(.vertical, 12)
                .padding(.leading, 15)
                .tint(HaikuTheme.accent)
                .submitLabel(.send)
                .onSubmit(sendMessage)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HaikuTheme.surface)
                    .frame(width: 34, height: 34)
                    .background(HaikuTheme.foreground, in: Circle())
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .accessibilityLabel("Send message")
            .padding(.trailing, 8)
            .padding(.bottom, 6)
        }
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .environment(\.colorScheme, colorScheme)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(HaikuTheme.surface.opacity(0.48))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(HaikuTheme.foreground.opacity(0.08), lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(HaikuTheme.background)
    }

    @Environment(\.colorScheme) private var colorScheme

    private func messageRow(_ message: ChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 44) }

            Text(message.text)
                .font(.system(size: 16))
                .padding(.horizontal, 15)
                .padding(.vertical, 11)
                .background(
                    message.isUser ? HaikuTheme.surface : Color.clear,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            if !message.isUser { Spacer(minLength: 44) }
        }
        .frame(maxWidth: .infinity)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(text: text, isUser: true))
        messageText = ""
        // Model inference will be connected in a later milestone.
    }
}
