import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ContentView: View {
    @State private var isShowingSplash = true
    @State private var isSidebarOpen = false
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []

    var body: some View {
        ZStack {
            HaikuTheme.background.ignoresSafeArea()

            if isShowingSplash {
                // Intentionally blank. The launch experience uses the same
                // background as the chat so the transition feels seamless.
                HaikuTheme.background
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else {
                chatScreen
                    .transition(.opacity)
            }

            if isSidebarOpen && !isShowingSplash {
                SidebarView(isOpen: $isSidebarOpen)
                    .transition(.opacity)
                    .zIndex(2)
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
    }

    private var header: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isSidebarOpen = true
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 19, weight: .medium))
                    .frame(width: 42, height: 42)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Open sidebar")

            Spacer()

            Text("Haiku")
                .font(.system(size: 17, weight: .semibold, design: .rounded))

            Spacer()

            Button {
                messages.removeAll()
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
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(.regularMaterial)
                .environment(\.colorScheme, colorScheme)
                .overlay {
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(HaikuTheme.surface.opacity(0.48))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
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
