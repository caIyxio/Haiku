import SwiftUI
import UIKit

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
    @State private var isSidebarVisible = false
    @State private var messageText = ""
    @State private var selectedModelID = "luna"
    @State private var messages: [ChatMessage] = []
    @State private var sendingMessage: ChatMessage?
    @Namespace private var messageSendNamespace
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
                        NativeChatSidebarHost(
                            sidebar: AnyView(sidebar),
                            detail: AnyView(detailView(onToggleSidebar: { isSidebarVisible = true })),
                            isRegularWidth: true,
                            isSidebarVisible: $isSidebarVisible
                        )
                    } else {
                        CompactChatSidebarOverlay(
                            sidebar: AnyView(sidebar),
                            detail: AnyView(detailView(onToggleSidebar: { isSidebarVisible = true })),
                            isSidebarVisible: $isSidebarVisible
                        )
                    }
                }
                .tint(HaikuTheme.accent)
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
        VStack(spacing: 0) {
            HStack {
                Text("Haiku")
                    .font(.system(size: 23, weight: .semibold, design: .serif))
                    .foregroundStyle(HaikuTheme.foreground)
                Spacer()
                Button {
                    messages.removeAll()
                    messageText = ""
                    selection = .chat
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 42, height: 42)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New chat")
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider().overlay(HaikuTheme.foreground.opacity(0.08))

            List {
                Section {
                    Button {
                        messages.removeAll()
                        messageText = ""
                        selection = .chat
                    } label: {
                        Label("New chat", systemImage: "square.and.pencil")
                    }
                    .listRowSeparator(.hidden)
                }

                Section("Your chats") {

                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Divider().overlay(HaikuTheme.foreground.opacity(0.08))

            HStack(spacing: 12) {
                Button {
                    messages.removeAll()
                    messageText = ""
                    selection = .chat
                } label: {
                    Label("Chat", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 13)
                        .frame(height: 44)
                        .background(HaikuTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    selection = .settings
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 23))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Account and settings")
            }
            .foregroundStyle(HaikuTheme.foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(HaikuTheme.background.ignoresSafeArea())
    }

    @ViewBuilder
    private func detailView(onToggleSidebar: @escaping () -> Void) -> some View {
        switch selection {
        case .settings:
            settingsScreen
        case .chat, .none:
            chatScreen(onToggleSidebar: onToggleSidebar)
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

    private func chatScreen(onToggleSidebar: @escaping () -> Void) -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header(onToggleSidebar: onToggleSidebar)
                    .padding(.top, geometry.safeAreaInsets.top)

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
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(HaikuTheme.foreground)
            .background(HaikuTheme.background.ignoresSafeArea())
        }
        .ignoresSafeArea()
    }

    private func header(onToggleSidebar: @escaping () -> Void) -> some View {
        HStack {
            Button(action: onToggleSidebar) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 19, weight: .medium))
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open sidebar")

            Spacer(minLength: 0)

            Text("Haiku")
                .font(.system(size: 22, weight: .semibold, design: .serif))

            Spacer(minLength: 0)

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
            .buttonStyle(.plain)
            .accessibilityLabel("New chat")
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
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
                .opacity(sendingMessage == nil ? 1 : 0)
                .overlay(alignment: .topLeading) {
                    if let sendingMessage {
                        Text(sendingMessage.text)
                            .font(.system(size: 16))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 11)
                            .background(HaikuTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .matchedGeometryEffect(id: sendingMessage.id, in: messageSendNamespace, isSource: true)
                            .padding(.leading, 16)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }
                .tint(HaikuTheme.accent)
                .submitLabel(.send)
                .onSubmit(sendMessage)

            HStack(spacing: 10) {
                Menu {
                    ForEach(HaikuModelCatalog.free) { model in
                        Button {
                            selectedModelID = model.id
                        } label: {
                            if selectedModelID == model.id {
                                Label("Haiku 1.0-" + model.name, systemImage: "checkmark")
                            } else {
                                Text("Haiku 1.0-" + model.name)
                            }
                        }
                    }
                    ForEach(HaikuModelCatalog.paid) { model in
                        Button {} label: {
                            Label("Haiku 1.0-" + model.name, systemImage: "lock.fill")
                        }
                        .disabled(true)
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
                .matchedGeometryEffect(id: message.id, in: messageSendNamespace, isSource: sendingMessage?.id != message.id)

            if !message.isUser { Spacer(minLength: 44) }
        }
        .frame(maxWidth: .infinity)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard sendingMessage == nil else { return }
        let message = ChatMessage(text: text, isUser: true)
        withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
            sendingMessage = message
            messages.append(message)
            messageText = ""
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(560))
            withAnimation(.easeOut(duration: 0.16)) {
                sendingMessage = nil
            }
        }
        // Model inference will be connected in a later milestone.
    }
}


/// Compact iPhone presentation: keep the live chat underneath and slide the drawer over it.
private struct CompactChatSidebarOverlay: View {
    let sidebar: AnyView
    let detail: AnyView
    @Binding var isSidebarVisible: Bool

    var body: some View {
        GeometryReader { proxy in
            let drawerWidth = proxy.size.width * 0.80

            ZStack(alignment: .leading) {
                detail
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .overlay {
                        if isSidebarVisible {
                            Color.black.opacity(0.34)
                                .contentShape(Rectangle())
                                .onTapGesture { closeSidebar() }
                        }
                    }
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: isSidebarVisible ? 28 : 0,
                            bottomLeadingRadius: isSidebarVisible ? 28 : 0,
                            style: .continuous
                        )
                    )
                    .offset(x: isSidebarVisible ? drawerWidth : 0)

                if isSidebarVisible {
                    sidebar
                        .frame(width: drawerWidth, height: proxy.size.height)
                        .background(HaikuTheme.background.ignoresSafeArea())
                        .clipShape(
                            UnevenRoundedRectangle(
                                topTrailingRadius: 26,
                                bottomTrailingRadius: 26,
                                style: .continuous
                            )
                        )
                        .transition(.move(edge: .leading))
                        .zIndex(2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HaikuTheme.background.ignoresSafeArea())
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 18)
                    .onEnded { value in
                        if !isSidebarVisible && value.startLocation.x < 28 && value.translation.width > 70 {
                            openSidebar()
                        } else if isSidebarVisible && value.translation.width < -70 {
                            closeSidebar()
                        }
                    }
            )
            .animation(.spring(response: 0.38, dampingFraction: 0.90), value: isSidebarVisible)
        }
        .ignoresSafeArea()
    }

    private func openSidebar() {
        isSidebarVisible = true
    }

    private func closeSidebar() {
        isSidebarVisible = false
    }
}

/// UIKit owns the real system sidebar, including its edge-swipe gesture.
private struct NativeChatSidebarHost: UIViewControllerRepresentable {
    let sidebar: AnyView
    let detail: AnyView
    let isRegularWidth: Bool
    @Binding var isSidebarVisible: Bool

    func makeUIViewController(context: Context) -> UISplitViewController {
        let split = UISplitViewController(style: .doubleColumn)
        split.delegate = context.coordinator
        split.presentsWithGesture = true
        split.displayModeButtonVisibility = .never
        configure(split)

        let primary = UIHostingController(rootView: sidebar)
        let secondary = UIHostingController(rootView: detail)
        primary.safeAreaRegions = []
        secondary.safeAreaRegions = []
        primary.view.backgroundColor = UIColor.clear
        secondary.view.backgroundColor = UIColor.clear
        context.coordinator.primary = primary
        context.coordinator.secondary = secondary
        context.coordinator.split = split
        context.coordinator.visibility = $isSidebarVisible

        split.setViewController(primary, for: .primary)
        split.setViewController(secondary, for: .secondary)
        return split
    }

    func updateUIViewController(_ split: UISplitViewController, context: Context) {
        context.coordinator.primary?.rootView = sidebar
        context.coordinator.secondary?.rootView = detail
        context.coordinator.visibility = $isSidebarVisible
        configure(split)

        if isRegularWidth {
            if split.displayMode == .secondaryOnly {
                split.show(.primary)
            }
            context.coordinator.lastRequestedVisibility = true
        } else if context.coordinator.lastRequestedVisibility != isSidebarVisible {
            if isSidebarVisible {
                split.show(.primary)
            } else {
                split.hide(.primary)
            }
            context.coordinator.lastRequestedVisibility = isSidebarVisible
        }
    }

    private func configure(_ split: UISplitViewController) {
        split.preferredSplitBehavior = isRegularWidth ? .tile : .overlay
        split.preferredDisplayMode = isRegularWidth ? .oneBesideSecondary : .secondaryOnly
        split.presentsWithGesture = true
        split.displayModeButtonVisibility = .never
        split.preferredPrimaryColumnWidth = 320
        split.minimumPrimaryColumnWidth = 280
        split.maximumPrimaryColumnWidth = 360
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UISplitViewControllerDelegate {
        var primary: UIHostingController<AnyView>?
        var secondary: UIHostingController<AnyView>?
        weak var split: UISplitViewController?
        var visibility: Binding<Bool>?
        var lastRequestedVisibility = false

        func splitViewControllerDidChangeDisplayMode(_ svc: UISplitViewController) {
            guard !svc.isCollapsed, svc.splitBehavior == .overlay else { return }
            let visible = svc.displayMode == .oneOverSecondary
            lastRequestedVisibility = visible
            visibility?.wrappedValue = visible
        }
    }
}
