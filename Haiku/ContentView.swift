import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

private struct HaikuModelOption: Identifiable {
    let id: String
    let name: String
    let detail: String
    let isPaid: Bool
}

private enum HaikuModelCatalog {
    static let free = [
        HaikuModelOption(id: "luna", name: "Luna", detail: "Free", isPaid: false)
    ]

    static let paid = [
        HaikuModelOption(id: "orion", name: "Orion", detail: "Paid", isPaid: true)
    ]

    static let all = free + paid
}

private enum HaikuDestination: Hashable {
    case chat
    case settings
}

struct ContentView: View {
    @State private var isShowingSplash = true
    @StateObject private var auth = HaikuAuthStore()
    @State private var selection: HaikuDestination? = .chat
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isPhoneSidebarPresented = false
    @State private var messageText = ""
    @State private var selectedModelID = "luna"
    @State private var messages: [ChatMessage] = []
    @FocusState private var isComposerFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if isShowingSplash {
                HaikuTheme.background
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else if auth.session == nil {
                HaikuAccountView(auth: auth)
                    .transition(.opacity)
            } else {
                Group {
                    if horizontalSizeClass == .regular {
                        NavigationSplitView(columnVisibility: $columnVisibility) {
                            sidebar
                        } detail: {
                            detailView
                        }
                        .navigationSplitViewStyle(.balanced)
                        .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
                        .tint(HaikuTheme.accent)
                    } else {
                        compactPhoneLayout
                    }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(nil)
        .task {
            Task { await auth.observeSession() }
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
                .listRowBackground(Color.clear)
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
                .listRowBackground(Color.clear)
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
            if let email = auth.session?.user.email {
                Text(email)
                    .font(.system(size: 15))
                    .foregroundStyle(HaikuTheme.secondary)
            }
            Button("Sign out", role: .destructive) {
                Task { await auth.signOut() }
            }
            .padding(.top, 8)
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

    private var compactPhoneLayout: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Group {
                    switch selection {
                    case .settings:
                        settingsScreen
                    case .chat, .none:
                        chatScreen
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isPhoneSidebarPresented {
                    Color.black.opacity(0.22)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.38, bounce: 0.12)) {
                                isPhoneSidebarPresented = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(1)

                    phoneSidebar
                        .frame(width: min(geometry.size.width * 0.84, 340))
                        .frame(maxHeight: .infinity)
                        .background(HaikuTheme.background.ignoresSafeArea())
                        .shadow(color: .black.opacity(0.12), radius: 18, x: 8, y: 0)
                        .transition(.move(edge: .leading))
                        .zIndex(2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 18)
                    .onEnded { value in
                        let beganAtLeadingEdge = value.startLocation.x <= 28
                        if !isPhoneSidebarPresented && beganAtLeadingEdge && value.translation.width > 65 {
                            isComposerFocused = false
                            withAnimation(.spring(duration: 0.38, bounce: 0.12)) {
                                isPhoneSidebarPresented = true
                            }
                        } else if isPhoneSidebarPresented && value.translation.width < -65 {
                            withAnimation(.spring(duration: 0.38, bounce: 0.12)) {
                                isPhoneSidebarPresented = false
                            }
                        }
                    }
            )
            .animation(.spring(duration: 0.38, bounce: 0.12), value: isPhoneSidebarPresented)
        }
    }

    private var phoneSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Haiku")
                    .font(.system(size: 23, weight: .semibold, design: .serif))
                    .foregroundStyle(HaikuTheme.foreground)
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.38, bounce: 0.12)) {
                        isPhoneSidebarPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(HaikuTheme.secondary)
                        .frame(width: 36, height: 36)
                        .background(HaikuTheme.surface, in: Circle())
                }
                .accessibilityLabel("Close sidebar")
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)

            Button {
                messages.removeAll()
                messageText = ""
                selection = .chat
                withAnimation(.spring(duration: 0.38, bounce: 0.12)) {
                    isPhoneSidebarPresented = false
                }
            } label: {
                Label("New chat", systemImage: "square.and.pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HaikuTheme.foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(HaikuTheme.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)

            Text("Recent")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(HaikuTheme.secondary)
                .padding(.horizontal, 18)
                .padding(.top, 28)
                .padding(.bottom, 10)

            Text("Your conversations will appear here.")
                .font(.system(size: 14))
                .foregroundStyle(HaikuTheme.secondary.opacity(0.8))
                .padding(.horizontal, 18)

            Spacer(minLength: 20)

            Button {
                selection = .settings
                withAnimation(.spring(duration: 0.38, bounce: 0.12)) {
                    isPhoneSidebarPresented = false
                }
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HaikuTheme.foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(HaikuTheme.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        ZStack {
            Text("Haiku")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .frame(maxWidth: .infinity)
            HStack {
                if horizontalSizeClass == .compact {
                    Button {
                        isComposerFocused = false
                        withAnimation(.spring(duration: 0.38, bounce: 0.12)) {
                            isPhoneSidebarPresented = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20, weight: .regular))
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Show sidebar")
                } else {
                    Color.clear.frame(width: 40, height: 40)
                }

                Spacer()

                Button {
                    messages.removeAll()
                    messageText = ""
                    selection = .chat
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .regular))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("New chat")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .foregroundStyle(HaikuTheme.foreground)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Message Haiku", text: $messageText, axis: .vertical)
                .focused($isComposerFocused)
                .font(.system(size: 17))
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .tint(HaikuTheme.accent)
                .submitLabel(.send)
                .onSubmit(sendMessage)

            HStack(spacing: 10) {
                Menu {
                    Section("Free") {
                        ForEach(HaikuModelCatalog.free) { model in
                            Button {
                                selectedModelID = model.id
                            } label: {
                                if selectedModelID == model.id {
                                    Label(model.name, systemImage: "checkmark")
                                } else {
                                    Text(model.name)
                                }
                            }
                        }
                    }

                    Section("Paid") {
                        ForEach(HaikuModelCatalog.paid) { model in
                            Button {} label: {
                                Label(model.name + " · " + model.detail, systemImage: "lock.fill")
                            }
                            .disabled(true)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Haiku 1.0-" + (HaikuModelCatalog.all.first(where: { $0.id == selectedModelID })?.name ?? "Luna"))
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(HaikuTheme.foreground)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(HaikuTheme.background.opacity(0.7), in: Capsule())
                }
                .accessibilityLabel("Choose Haiku model")

                Spacer()

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(HaikuTheme.background)
                        .frame(width: 34, height: 34)
                        .background(HaikuTheme.foreground, in: Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.42 : 1)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
                .environment(\.colorScheme, colorScheme)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(HaikuTheme.surface.opacity(0.72))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(HaikuTheme.foreground.opacity(0.07), lineWidth: 1)
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 10)
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
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
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
