import SwiftUI

extension Notification.Name {
    static let netStudyRandom = Notification.Name("netStudy.random")
    static let netStudyVOTD = Notification.Name("netStudy.votd")
    static let netStudyNext = Notification.Name("netStudy.next")
    static let netStudyPrevious = Notification.Name("netStudy.previous")
    static let netStudyToggleSidebar = Notification.Name("netStudy.toggleSidebar")
}

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 0) {
            if store.showSidebar {
                SidebarView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .zIndex(1)
            }
            ReaderView()
        }
        .background(Theme.background(scheme).ignoresSafeArea())
        .preferredColorScheme(store.preferredColorScheme)
        .background(WindowConfigurator())
        .frame(minWidth: 940, minHeight: 620)
        .onReceive(NotificationCenter.default.publisher(for: .netStudyRandom)) { _ in
            store.shuffleVerse()
        }
        .onReceive(NotificationCenter.default.publisher(for: .netStudyVOTD)) { _ in
            Task { await store.load(.verseOfTheDay) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .netStudyNext)) { _ in
            store.goNextChapter()
        }
        .onReceive(NotificationCenter.default.publisher(for: .netStudyPrevious)) { _ in
            store.goPreviousChapter()
        }
        .onReceive(NotificationCenter.default.publisher(for: .netStudyToggleSidebar)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                store.showSidebar.toggle()
            }
        }
    }
}

@main
struct NETStudyApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup("NET Study") {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Study") {
                Button("Go to Reference…") {
                    NotificationCenter.default.post(name: .netStudyFocusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Divider()

                Button("Verse of the Day") {
                    NotificationCenter.default.post(name: .netStudyVOTD, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)

                Button("Random Verse") {
                    NotificationCenter.default.post(name: .netStudyRandom, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("Next Chapter") {
                    NotificationCenter.default.post(name: .netStudyNext, object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)

                Button("Previous Chapter") {
                    NotificationCenter.default.post(name: .netStudyPrevious, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)

                Divider()

                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .netStudyToggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
        }
    }
}
