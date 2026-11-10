import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme

    @State private var expandedBook: String?
    @State private var hoveredBook: String?
    @State private var hoveredSaved: UUID?
    @Namespace private var pill

    private let sidebarWidth: CGFloat = 264

    var body: some View {
        VStack(spacing: 0) {
            header
            sectionSwitcher
                .padding(.horizontal, 14)
                .padding(.bottom, 10)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        switch store.sidebarSection {
                        case .read: libraryList
                        case .saved: savedList
                        case .notes: notesList
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 18)
                }
                .scrollIndicators(.never)
                .overlay(alignment: .top) {
                    LinearGradient(colors: [Theme.sidebarBackground(scheme),
                                            Theme.sidebarBackground(scheme).opacity(0)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 10)
                        .allowsHitTesting(false)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        if let name = store.query.reference?.book.name {
                            proxy.scrollTo(name, anchor: .top)
                        }
                    }
                }
            }

            footer
        }
        .frame(width: sidebarWidth)
        .background(Theme.sidebarBackground(scheme))
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Theme.stroke(scheme))
                .frame(width: 1)
        }
        .onAppear { syncExpanded() }
        .onChange(of: store.query) { _, _ in syncExpanded() }
    }

    private func syncExpanded() {
        if let book = store.query.reference?.book {
            expandedBook = book.name
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.goldBright, Color(hex: 0xA9821C)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x221A08))
            }
            .frame(width: 27, height: 27)
            .shadow(color: Theme.gold.opacity(0.35), radius: 6, y: 2)

            VStack(alignment: .leading, spacing: 0) {
                Text("NET Study")
                    .font(.system(size: 14.5, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.text(scheme))
                Text("New English Translation")
                    .font(.system(size: 9.5))
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 26)
        .padding(.bottom, 14)
    }

    // MARK: - Section switcher

    private var sectionSwitcher: some View {
        HStack(spacing: 2) {
            ForEach(AppStore.SidebarSection.allCases, id: \.self) { section in
                let active = store.sidebarSection == section
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        store.sidebarSection = section
                    }
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(active ? Theme.text(scheme) : Theme.secondaryText(scheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background {
                            if active {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(scheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(scheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.045))
        )
    }

    // MARK: - Library

    private var libraryList: some View {
        VStack(alignment: .leading, spacing: 2) {
            testamentSection("Old Testament", books: Bible.oldTestament)
            testamentSection("New Testament", books: Bible.newTestament)
                .padding(.top, 10)
        }
    }

    private func testamentSection(_ title: String, books: [BibleBook]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            SectionLabel(text: title)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 4)

            ForEach(books) { book in
                bookRow(book)
            }
        }
    }

    private func bookRow(_ book: BibleBook) -> some View {
        let isCurrent = store.query.reference?.book == book
        let isOpen = expandedBook == book.name
        let hovered = hoveredBook == book.name

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(book.name)
                    .font(.system(size: 12.5, weight: isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? Theme.gold : Theme.text(scheme))
                Spacer()
                Text("\(book.chapters)")
                    .font(.system(size: 9.5, design: .rounded))
                    .foregroundStyle(Theme.secondaryText(scheme).opacity(0.7))
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(hovered ? Color.primary.opacity(0.055) : .clear)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) {
                    hoveredBook = hovering ? book.name : (hoveredBook == book.name ? nil : hoveredBook)
                }
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                    if isOpen {
                        expandedBook = nil
                    } else {
                        expandedBook = book.name
                    }
                    store.selectedBook = book
                }
            }

            .id(book.name)

            if isOpen {
                chapterGrid(for: book)
                    .padding(.leading, 8)
                    .padding(.trailing, 4)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func chapterGrid(for book: BibleBook) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
            ForEach(1...book.chapters, id: \.self) { chapter in
                ChapterChip(
                    number: chapter,
                    active: store.query.reference?.book == book && store.query.reference?.chapter == chapter
                ) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.open(book: book, chapter: chapter)
                    }
                }
            }
        }
    }

    // MARK: - Saved

    private var savedList: some View {
        VStack(alignment: .leading, spacing: 3) {
            if store.bookmarks.isEmpty {
                EmptyStateView(icon: "bookmark",
                               title: "Nothing saved yet",
                               message: "Open a verse, then hit the bookmark button to keep it here.")
            } else {
                SectionLabel(text: "Bookmarks")
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                ForEach(store.bookmarks) { bookmark in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(bookmark.reference)
                            .font(.system(size: 12, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.gold)
                        Text(bookmark.snippet)
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.secondaryText(scheme))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(hoveredSaved == bookmark.id ? Color.primary.opacity(0.06) : .clear)
                    )
                    .contentShape(Rectangle())
                    .onHover { h in withAnimation(.easeOut(duration: 0.12)) { hoveredSaved = h ? bookmark.id : nil } }
                    .onTapGesture { store.openSaved(queryString: bookmark.apiQuery) }
                    .contextMenu {
                        Button("Open") { store.openSaved(queryString: bookmark.apiQuery) }
                        Button("Remove", role: .destructive) { store.removeBookmark(bookmark) }
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Notes

    private var notesList: some View {
        VStack(alignment: .leading, spacing: 3) {
            if store.notes.isEmpty {
                EmptyStateView(icon: "note.text",
                               title: "No notes yet",
                               message: "Select a verse and add a note. Your study trail lands here.")
            } else {
                SectionLabel(text: "Study Notes")
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                ForEach(store.notes) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(note.reference)
                                .font(.system(size: 12, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.gold)
                            Spacer()
                            Text(note.updatedAt, format: .dateTime.month(.abbreviated).day())
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.secondaryText(scheme).opacity(0.8))
                        }
                        Text(note.body)
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.text(scheme))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { store.openSaved(queryString: note.reference) }
                    .contextMenu {
                        Button("Open Verse") { store.openSaved(queryString: note.reference) }
                        Button("Delete Note", role: .destructive) { store.removeNote(note) }
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Footer

    private static var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.stroke(scheme)).frame(height: 1)
            HStack(spacing: 6) {
                Button {
                    store.shuffleVerse()
                } label: {
                    Label("Random", systemImage: "shuffle")
                }
                .buttonStyle(SoftButtonStyle())

                Spacer()

                Text(verbatim: "v" + Self.appVersion)
                    .font(.system(size: 9.5))
                    .foregroundStyle(Theme.secondaryText(scheme).opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
    }
}

struct ChapterChip: View {
    let number: Int
    let active: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.system(size: 10.5, weight: active ? .semibold : .regular, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(active ? Color(hex: 0x241C06) : Theme.text(scheme))
                .frame(maxWidth: .infinity, minHeight: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(active ? Theme.gold
                              : (hovered ? Color.primary.opacity(0.09) : Color.primary.opacity(0.035)))
                )
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeOut(duration: 0.12)) { hovered = h } }
    }
}
