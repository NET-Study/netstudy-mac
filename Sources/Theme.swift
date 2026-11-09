import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

enum Theme {
    static let gold = Color(hex: 0xC9A227)
    static let goldBright = Color(hex: 0xE6BE49)
    static let ink = Color(hex: 0x1E1B18)

    static func background(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(colors: [Color(hex: 0x141217), Color(hex: 0x0D0C10)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(colors: [Color(hex: 0xFBF8F3), Color(hex: 0xF1EBE1)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func sidebarBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0x1A171E).opacity(0.78) : Color(hex: 0xF2EADF).opacity(0.92)
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.55)
    }

    static func stroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.075)
    }

    static func text(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0xE9E4DD) : Color(hex: 0x2A2622)
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0xA29B92) : Color(hex: 0x7A736A)
    }

    static var readingFont: Font? { nil }
}

// MARK: - Buttons

struct IconButtonStyle: ButtonStyle {
    var active: Bool = false
    var size: CGFloat = 30

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(active ? Theme.gold : .primary)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(active ? Theme.gold.opacity(0.16) : Color.primary.opacity(configuration.isPressed ? 0.12 : 0.0001))
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(prominent ? Theme.gold.opacity(configuration.isPressed ? 0.3 : 0.18)
                                          : Color.primary.opacity(configuration.isPressed ? 0.1 : 0.05))
            )
            .foregroundStyle(prominent ? Theme.gold : .primary)
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Window tweaks

final class WindowConfiguringView: NSView {
    private var configured = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window, !configured else { return }
        configured = true

        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.minSize = NSSize(width: 940, height: 620)

        let screen = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        guard screen.width > 200 else { return }
        let target = NSSize(width: min(1240, screen.width - 90),
                            height: min(830, screen.height - 30))

        // SwiftUI re-applies the content's ideal size right after the window is
        // attached, so settle the frame once layout has finished.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            var frame = window.frame
            frame.size = target
            frame.origin = NSPoint(x: screen.minX + (screen.width - target.width) / 2,
                                   y: screen.minY + (screen.height - target.height) / 2)
            window.setFrame(frame, display: true)
        }
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { WindowConfiguringView() }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Small pieces

struct SectionLabel: View {
    let text: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.1)
            .foregroundStyle(Theme.secondaryText(scheme))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.gold.opacity(0.8))
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.text(scheme))
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 230)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

struct ShimmerBar: View {
    @State private var phase: CGFloat = -1
    var width: CGFloat
    var height: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(Color.primary.opacity(0.07))
            .frame(width: width, height: height)
            .overlay(
                LinearGradient(colors: [.clear, Color.primary.opacity(0.09), .clear],
                               startPoint: .leading, endPoint: .trailing)
                    .offset(x: phase * width)
            )
            .clipShape(RoundedRectangle(cornerRadius: height / 2))
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1.4
                }
            }
    }
}
