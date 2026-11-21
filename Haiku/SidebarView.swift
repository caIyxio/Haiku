import SwiftUI

struct SidebarView: View {
    @Binding var isOpen: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()
                    .onTapGesture { close() }

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Haiku")
                            .font(.system(size: 21, weight: .semibold, design: .rounded))
                        Spacer()
                        Button(action: close) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .medium))
                                .frame(width: 36, height: 36)
                                .background(HaikuTheme.foreground.opacity(0.07), in: Circle())
                        }
                        .accessibilityLabel("Close sidebar")
                    }
                    .padding(.bottom, 28)

                    Button(action: close) {
                        Label("New chat", systemImage: "square.and.pencil")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                    }

                    Text("RECENT")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.1)
                        .foregroundStyle(HaikuTheme.secondary)
                        .padding(.top, 28)
                        .padding(.bottom, 12)

                    Text("Your conversations will appear here.")
                        .font(.system(size: 14))
                        .foregroundStyle(HaikuTheme.secondary)

                    Spacer()

                    Divider().overlay(HaikuTheme.foreground.opacity(0.12))

                    HStack(spacing: 12) {
                        Image(systemName: "gearshape")
                        Text("Settings")
                        Spacer()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .padding(.top, 18)
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)
                .padding(.bottom, 28)
                .frame(width: min(geometry.size.width * 0.82, 330))
                .frame(maxHeight: .infinity)
                .background(HaikuTheme.surface)
                .foregroundStyle(HaikuTheme.foreground)
                .shadow(color: .black.opacity(0.12), radius: 24, x: 8, y: 0)
                .offset(x: isOpen ? 0 : -geometry.size.width)
            }
            .ignoresSafeArea()
        }
    }

    private func close() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isOpen = false
        }
    }
}
