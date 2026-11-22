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
                        NavigationSplitView {
                            sidebar
                                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 340)
                        } detail: {
                            detailView
                        }
                        .navigationSplitViewStyle(.balanced)
                    } else {
                        ChatDrawerHost(
                            sidebar: AnyView(sidebar),
                            detail: AnyView(detailView),
                            isSidebarVisible: $isSidebarVisible,
                            dismissKeyboard: { isComposerFocused = false }
                        )
                    }
                }
                .tint(HaikuTheme.accent)
                .transition(.opacity)
            }
        }
        .background(HaikuTheme.background.ignoresSafeArea())
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

                Button(action: startNewChat) {
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

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text("Your chats")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HaikuTheme.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 22)
                        .padding(.top, 16)
                    // Conversation history will populate this list.
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(HaikuTheme.background)
            .scrollIndicators(.hidden)

            Divider().overlay(HaikuTheme.foreground.opacity(0.08))

            Button(action: openSettings) {
                Label("Account & settings", systemImage: "person.crop.circle")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .frame(height: 48)
                    .background(
                        HaikuTheme.surface,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .foregroundStyle(HaikuTheme.foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(HaikuTheme.background.ignoresSafeArea())
    }

    private func startNewChat() {
        messages.removeAll()
        messageText = ""
        selection = .chat
        if horizontalSizeClass != .regular {
            isSidebarVisible = false
        }
    }

    private func openSettings() {
        selection = .settings
        if horizontalSizeClass != .regular {
            isSidebarVisible = false
        }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(HaikuTheme.foreground)
        .background(HaikuTheme.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Spacer()
                .frame(width: 40)

            Spacer(minLength: 0)

            Text("Haiku")
                .font(.system(size: 22, weight: .semibold, design: .serif))

            Spacer(minLength: 0)

            Button(action: startNewChat) {
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


/// Full-height overlay drawer with a single, continuous interactive progress value.
private struct ChatDrawerHost: View {
    let sidebar: AnyView
    let detail: AnyView
    @Binding var isSidebarVisible: Bool
    let dismissKeyboard: () -> Void

    @State private var interactiveProgress: CGFloat? = nil
    @State private var hasStartedHorizontalDrag = false
    @State private var didFireThresholdHaptic = false

    private let drawerSpring = Animation.spring(response: 0.42, dampingFraction: 0.9, blendDuration: 0)

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.89, 420)
            let topInset = proxy.safeAreaInsets.top
            let bottomInset = proxy.safeAreaInsets.bottom
            let progress = min(max(interactiveProgress ?? (isSidebarVisible ? 1 : 0), 0), 1)
            let panelShape = UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 0, bottomLeading: 0, bottomTrailing: 30, topTrailing: 30),
                style: .continuous
            )

            ZStack(alignment: .leading) {
                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, topInset)
                    .padding(.bottom, bottomInset)
                    .overlay {
                        Color.black
                            .opacity(0.38 * progress)
                            .ignoresSafeArea()
                            .allowsHitTesting(progress > 0.02)
                            .onTapGesture { close() }
                    }
                    .contentShape(Rectangle())
                    .simultaneousGesture(drawerDrag(width: width))

                // Full-screen dim layer, including the status-bar/sensor area.
                Color.black
                    .opacity(0.38 * progress)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                sidebar
                    // Panel remains edge-to-edge; only its controls respect the status and home-indicator areas.
                    .padding(.top, topInset)
                    .padding(.bottom, bottomInset)
                    .frame(width: width, height: proxy.size.height + topInset + bottomInset, alignment: .top)
                    .background(HaikuTheme.background.ignoresSafeArea())
                    .clipShape(panelShape)
                    .overlay {
                        panelShape.strokeBorder(HaikuTheme.foreground.opacity(0.07), lineWidth: 0.7)
                    }
                    .offset(x: -width * (1 - progress), y: 0)
                    .shadow(color: .black.opacity(0.2 * progress), radius: 24, x: 8, y: 0)
                    .allowsHitTesting(progress > 0.96)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .background(HaikuTheme.background.ignoresSafeArea())
        }
        .ignoresSafeArea(edges: .top)
        .background(HaikuTheme.background.ignoresSafeArea())
    }

    private func drawerDrag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                guard abs(value.translation.width) > 6,
                      abs(value.translation.width) > abs(value.translation.height) else { return }
                if !hasStartedHorizontalDrag {
                    hasStartedHorizontalDrag = true
                    dismissKeyboard()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                let start = isSidebarVisible ? CGFloat(1) : CGFloat(0)
                let nextProgress = min(max(start + value.translation.width / width, 0), 1)
                if !didFireThresholdHaptic,
                   (start < 0.5 && nextProgress >= 0.5) || (start > 0.5 && nextProgress <= 0.5) {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
                    didFireThresholdHaptic = true
                }
                interactiveProgress = nextProgress
            }
            .onEnded { value in
                defer {
                    hasStartedHorizontalDrag = false
                    didFireThresholdHaptic = false
                }
                guard abs(value.translation.width) > abs(value.translation.height) else {
                    withAnimation(drawerSpring) { interactiveProgress = nil }
                    return
                }
                let current = interactiveProgress ?? (isSidebarVisible ? 1 : 0)
                let projected = min(max(current + value.predictedEndTranslation.width / width * 0.35, 0), 1)
                let shouldOpen = projected > 0.5
                withAnimation(drawerSpring) {
                    isSidebarVisible = shouldOpen
                    interactiveProgress = nil
                }
            }
    }

    private func close() {
        dismissKeyboard()
        withAnimation(drawerSpring) {
            isSidebarVisible = false
            interactiveProgress = nil
        }
    }
}
