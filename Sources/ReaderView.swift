import SwiftUI
import AppKit

// MARK: - Reader

struct ReaderView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme

    @State private var editingVerse: Verse?
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            ReadingHeader(showSettings: $showSettings)
            Rectangle()
                .fill(Theme.stroke(scheme))
                .frame(height: 1)
            content
        }
        .background(Theme.background(scheme).ignoresSafeArea())
        .sheet(item: $editingVerse) { verse in
            NoteEditorSheet(verse: verse)
                .environmentObject(store)
        }
        .overlay(alignment: .topTrailing) {
            if showSettings {
                ZStack(alignment: .topTrailing) {
                    Color.black.opacity(0.0005)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                showSettings = false
                            }
                        }

                    ReadingSettings()
                        .environmentObject(store)
                        .background(Theme.background(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Theme.stroke(scheme), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(scheme == .dark ? 0.55 : 0.18), radius: 22, y: 10)
                        .padding(.top, 76)
                        .padding(.trailing, 14)
                        .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .topTrailing)))
                }
                .zIndex(50)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.88), value: showSettings)
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            if store.isLoading && store.verses.isEmpty {
                LoadingPassage()
            } else if let error = store.errorMessage {
                ErrorPassage(message: error)
            } else if store.verses.isEmpty {
                WelcomeView()
            } else {
                passage
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if let id = store.selectedVerseID,
               let verse = store.verses.first(where: { $0.id == id }) {
                VerseActionBar(verse: verse, onNote: { editingVerse = verse })
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.85), value: store.selectedVerseID)
    }

    private var passage: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    passageHeader
                        .id("top")
                        .padding(.bottom, 22)

                    ForEach(groups) { group in
                        if groups.count > 1 {
                            groupHeader(group)
                                .padding(.top, 26)
                                .padding(.bottom, 10)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(group.verses) { verse in
                                VerseRow(
                                    verse: verse,
                                    fontSize: store.fontSize,
                                    serif: store.serif,
                                    highlight: store.highlightColor(for: verse),
                                    selected: store.selectedVerseID == verse.id,
                                    bookmarked: store.isBookmarked(verse),
                                    hasNote: store.note(for: verse.reference) != nil
                                ) {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                        store.selectedVerseID = (store.selectedVerseID == verse.id) ? nil : verse.id
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: store.columnWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 36)
                .padding(.top, 40)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.never)
            .onChange(of: store.query) { _, _ in
                proxy.scrollTo("top", anchor: .top)
            }
        }
        .overlay(alignment: .topTrailing) {
            LinearGradient(colors: [Theme.gold.opacity(scheme == .dark ? 0.06 : 0.09), .clear],
                           startPoint: .topTrailing, endPoint: .bottomLeading)
                .frame(width: 340, height: 220)
                .blur(radius: 40)
                .allowsHitTesting(false)
        }
    }

    private var passageHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch store.query.kind {
            case .verseOfTheDay:
                Text("VERSE OF THE DAY")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(Theme.gold)
                Text("A word for today")
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .foregroundStyle(Theme.text(scheme))
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText(scheme))
            case .random:
                Text("RANDOM PASSAGE")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(Theme.gold)
                Text("Where the pages fell open")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .foregroundStyle(Theme.text(scheme))
            case .custom:
                Text("PASSAGES")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(Theme.gold)
                Text(store.query.raw)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(Theme.text(scheme))
            case .reference:
                if let ref = store.query.reference {
                    Text(ref.book.testament == .old ? "OLD TESTAMENT" : "NEW TESTAMENT")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.2)
                        .foregroundStyle(Theme.gold)
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(ref.book.name)
                            .font(.system(size: 36, weight: .regular, design: .serif))
                            .foregroundStyle(Theme.text(scheme))
                        if ref.verseStart == nil {
                            Text("\(ref.chapter)")
                                .font(.system(size: 36, weight: .light, design: .serif))
                                .foregroundStyle(Theme.gold)
                        } else {
                            Text("\(ref.chapter):\(ref.verseStart!)" + (ref.verseEnd.map { "-\($0)" } ?? ""))
                                .font(.system(size: 20, weight: .regular, design: .serif))
                                .foregroundStyle(Theme.secondaryText(scheme))
                        }
                    }
                } else {
                    Text(store.query.raw)
                        .font(.system(size: 30, weight: .regular, design: .serif))
                        .foregroundStyle(Theme.text(scheme))
                }
            }
        }
    }

    private func groupHeader(_ group: VerseGroup) -> some View {
        HStack(spacing: 10) {
            Text("\(group.book) \(group.chapter)")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.gold)
            Rectangle()
                .fill(Theme.stroke(scheme))
                .frame(height: 1)
        }
    }

    private var groups: [VerseGroup] {
        var result: [VerseGroup] = []
        for verse in store.verses {
            if let index = result.indices.last,
               result[index].book.caseInsensitiveCompare(verse.bookname) == .orderedSame,
               result[index].chapter == verse.chapter {
                result[index].verses.append(verse)
            } else {
                result.append(VerseGroup(id: "\(verse.bookname)-\(verse.chapter)-\(verse.id)",
                                         book: verse.bookname,
                                         chapter: verse.chapter,
                                         verses: [verse]))
            }
        }
        return result
    }
}

struct VerseGroup: Identifiable {
    let id: String
    let book: String
    let chapter: String
    var verses: [Verse]
}

// MARK: - Header

struct ReadingHeader: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 4) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    store.showSidebar.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
            }
            .buttonStyle(IconButtonStyle())

            Divider().frame(height: 15).padding(.horizontal, 5)

            Button { store.goPreviousChapter() } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(IconButtonStyle())
            .disabled(store.query.reference?.previousChapter == nil)
            .opacity(store.query.reference?.previousChapter == nil ? 0.35 : 1)
            .help("Previous chapter")

            Button { store.goNextChapter() } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(IconButtonStyle())
            .disabled(store.query.reference?.nextChapter == nil)
            .opacity(store.query.reference?.nextChapter == nil ? 0.35 : 1)
            .help("Next chapter")

            VStack(alignment: .leading, spacing: 1) {
                Text(store.query.title)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.text(scheme))
                    .lineLimit(1)
                Text(store.contextLabel)
                    .font(.system(size: 9.5))
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .lineLimit(1)
            }
            .padding(.leading, 6)
            .animation(.easeOut(duration: 0.2), value: store.query.title)

            Spacer(minLength: 16)

            ReferenceSearchField()

            Button {
                Task { await store.load(.verseOfTheDay) }
            } label: {
                Image(systemName: "sun.max")
            }
            .buttonStyle(IconButtonStyle(active: store.query.kind == .verseOfTheDay))
            .help("Verse of the Day")

            Button { store.shuffleVerse() } label: {
                Image(systemName: "shuffle")
            }
            .buttonStyle(IconButtonStyle(active: store.query.kind == .random))
            .help("Random verse")

            Button { showSettings.toggle() } label: {
                Image(systemName: "textformat.size")
            }
            .buttonStyle(IconButtonStyle(active: showSettings))
            .help("Reading settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 26)
        .padding(.bottom, 10)
        .overlay(alignment: .top) {
            // Keeps the hidden title bar draggable without stealing clicks.
            Color.clear
                .frame(height: 34)
                .contentShape(Rectangle())
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Search

extension Notification.Name {
    static let netStudyFocusSearch = Notification.Name("netStudy.focusSearch")
}

struct ReferenceSearchField: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme

    @State private var text = ""
    @State private var suggestions: [String] = []
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Theme.secondaryText(scheme))

            TextField("Go to John 3:16", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11.5))
                .focused($focused)
                .onSubmit(go)
                .onChange(of: text) { _, newValue in
                    withAnimation(.easeOut(duration: 0.15)) {
                        suggestions = ReferenceSuggestions.matches(for: newValue)
                    }
                }

            if !text.isEmpty {
                Button {
                    text = ""
                    suggestions = []
                    focused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.secondaryText(scheme).opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 9)
        .frame(width: 218, height: 28)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Theme.surface(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(focused ? Theme.gold.opacity(0.55) : Theme.stroke(scheme), lineWidth: 1)
                )
        )
        .overlay(alignment: .topLeading) {
            if focused && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions, id: \.self) { name in
                        SuggestionRow(name: name) {
                            text = name + " "
                            suggestions = []
                            focused = true
                        }
                    }
                }
                .frame(width: 218)
                .padding(.vertical, 4)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.stroke(scheme), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
                .offset(y: 32)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                .zIndex(20)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .netStudyFocusSearch)) { _ in
            focused = true
        }
        .onChange(of: focused) { _, isFocused in
            if !isFocused {
                withAnimation(.easeOut(duration: 0.12)) { suggestions = [] }
            }
        }
    }

    private func go() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        suggestions = []
        focused = false
        Task { await store.load(.userInput(trimmed)) }
    }
}

struct SuggestionRow: View {
    let name: String
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(name)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.text(scheme))
                Spacer()
                if let book = Bible.book(named: name) {
                    Text("\(book.chapters) ch")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.secondaryText(scheme))
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(hovered ? Color.primary.opacity(0.07) : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in hovered = h }
    }
}

// MARK: - Verse row

struct VerseRow: View {
    let verse: Verse
    let fontSize: Double
    let serif: Bool
    let highlight: Color?
    let selected: Bool
    let bookmarked: Bool
    let hasNote: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var hovered = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Button(action: action) {
                Text(verse.verse)
                    .font(.system(size: max(fontSize * 0.56, 10), weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(selected || hovered ? Theme.gold : Theme.secondaryText(scheme).opacity(0.75))
                    .frame(width: max(fontSize * 1.2, 24), alignment: .trailing)
                    .padding(.top, 1)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Select verse")
            .accessibilityLabel("Select verse \(verse.verse)")

            Text(verse.cleanText)
                .font(serif ? .system(size: fontSize, weight: .regular, design: .serif)
                            : .system(size: fontSize, weight: .regular))
                .lineSpacing(fontSize * 0.46)
                .foregroundStyle(Theme.text(scheme))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 4) {
                if bookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 8.5))
                        .foregroundStyle(Theme.gold.opacity(0.85))
                }
                if hasNote {
                    Image(systemName: "note.text")
                        .font(.system(size: 8.5))
                        .foregroundStyle(Theme.secondaryText(scheme))
                }
            }
            .padding(.top, 4)
            .opacity(bookmarked || hasNote ? 1 : 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(backgroundFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(selected ? Theme.gold.opacity(0.55) : .clear, lineWidth: 1)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) { hovered = hovering }
        }
        .simultaneousGesture(TapGesture().onEnded { action() })
        .overlay(alignment: .trailing) {
            if hovered && !selected {
                Button(action: action) {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText(scheme).opacity(0.65))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
                .help("Verse actions")
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: selected)
        .animation(.easeOut(duration: 0.14), value: hovered)
    }

    private var backgroundFill: Color {
        if let highlight {
            return highlight.opacity(scheme == .dark ? 0.15 : 0.28)
        }
        if selected {
            return Theme.gold.opacity(scheme == .dark ? 0.10 : 0.12)
        }
        return hovered ? Color.primary.opacity(0.045) : .clear
    }
}

// MARK: - Action bar

struct VerseActionBar: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme

    let verse: Verse
    let onNote: () -> Void

    @State private var copied = false
    @State private var hoveringClose = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(verse.reference)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.text(scheme))
                Text("Click a color to highlight")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
            .frame(width: 132, alignment: .leading)

            Divider().frame(height: 22)

            HStack(spacing: 7) {
                ForEach(Palette.highlights.indices, id: \.self) { index in
                    HighlightDot(color: Palette.highlights[index],
                                 active: store.highlights[verse.id] == index) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if store.highlights[verse.id] == index {
                                store.setHighlight(verse, index: nil)
                            } else {
                                store.setHighlight(verse, index: index)
                            }
                        }
                    }
                }
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { store.setHighlight(verse, index: nil) }
                } label: {
                    Image(systemName: "eraser")
                        .font(.system(size: 10))
                }
                .buttonStyle(IconButtonStyle(size: 24))
                .disabled(!store.isHighlighted(verse))
                .opacity(store.isHighlighted(verse) ? 1 : 0.4)
                .help("Clear highlight")
            }

            Divider().frame(height: 22)

            HStack(spacing: 2) {
                Button(action: onNote) {
                    Label(store.note(for: verse.reference) == nil ? "Note" : "Edit note", systemImage: "square.and.pencil")
                        .font(.system(size: 11))
                }
                .buttonStyle(SoftButtonStyle())

                Button {
                    store.toggleBookmark(verse)
                } label: {
                    Image(systemName: store.isBookmarked(verse) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 11))
                }
                .buttonStyle(IconButtonStyle(active: store.isBookmarked(verse), size: 26))
                .help("Bookmark verse")

                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString("\"\(verse.cleanText)\" (\(verse.reference), NET)", forType: .string)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(IconButtonStyle(active: copied, size: 26))
                .help("Copy verse")
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    store.selectedVerseID = nil
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
            .buttonStyle(IconButtonStyle(size: 24))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.thickMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(Theme.stroke(scheme), lineWidth: 1)
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.5 : 0.15), radius: 18, y: 8)
        .frame(maxWidth: 680)
    }
}

struct HighlightDot: View {
    let color: Color
    let active: Bool
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 15, height: 15)
                .overlay(
                    Circle().stroke(Color.white.opacity(active ? 0.9 : 0.35), lineWidth: active ? 2 : 1)
                )
                .overlay(
                    Circle().stroke(color.opacity(0.5), lineWidth: 2)
                        .scaleEffect(active ? 1.45 : 1)
                        .opacity(active ? 1 : 0)
                )
                .scaleEffect(hovered ? 1.16 : 1)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) { hovered = h } }
    }
}

// MARK: - Note editor

struct NoteEditorSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let verse: Verse
    @State private var bodyText = ""
    @FocusState private var editorFocused: Bool

    private var existingNote: VerseNote? { store.note(for: verse.reference) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text(verse.reference.uppercased())
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(Theme.gold)
                Text(verse.cleanText)
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle().fill(Theme.stroke(scheme)).frame(height: 1)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $bodyText)
                    .font(.system(size: 13, design: .serif))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .focused($editorFocused)
                    .background(Color.primary.opacity(0.03))

                if bodyText.isEmpty {
                    Text("Write your note…")
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Theme.secondaryText(scheme).opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }

            Rectangle().fill(Theme.stroke(scheme)).frame(height: 1)

            HStack {
                if existingNote != nil {
                    Button("Delete") {
                        store.saveNote(for: verse, body: "")
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red.opacity(0.85))
                    .font(.system(size: 11.5))
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(SoftButtonStyle())
                    .keyboardShortcut(.cancelAction)
                Button("Save Note") {
                    store.saveNote(for: verse, body: bodyText)
                    dismiss()
                }
                .buttonStyle(SoftButtonStyle(prominent: true))
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
        }
        .frame(width: 470, height: 330)
        .background(Theme.background(scheme))
        .onAppear {
            bodyText = existingNote?.body ?? ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { editorFocused = true }
        }
    }
}

// MARK: - Reading settings

struct ReadingSettings: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.text(scheme))

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("Text size").font(.system(size: 11)).foregroundStyle(Theme.secondaryText(scheme))
                    Spacer()
                    Text("\(Int(store.fontSize)) pt")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Theme.secondaryText(scheme))
                        .monospacedDigit()
                }
                HStack(spacing: 8) {
                    Text("A").font(.system(size: 10))
                    Slider(value: $store.fontSize, in: 14...28, step: 1)
                        .controlSize(.mini)
                    Text("A").font(.system(size: 16))
                }
                .foregroundStyle(Theme.secondaryText(scheme))
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("Column width").font(.system(size: 11)).foregroundStyle(Theme.secondaryText(scheme))
                    Spacer()
                    Text("\(Int(store.columnWidth))")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Theme.secondaryText(scheme))
                        .monospacedDigit()
                }
                Slider(value: $store.columnWidth, in: 520...900, step: 10)
                    .controlSize(.mini)
            }

            Toggle(isOn: $store.serif) {
                Text("Serif type").font(.system(size: 11)).foregroundStyle(Theme.text(scheme))
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            VStack(alignment: .leading, spacing: 6) {
                Text("Appearance").font(.system(size: 11)).foregroundStyle(Theme.secondaryText(scheme))
                Picker("", selection: $store.appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .frame(width: 272)
    }
}

// MARK: - States

struct LoadingPassage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShimmerBar(width: 120, height: 10)
            ShimmerBar(width: 260, height: 30)
            Spacer().frame(height: 18)
            ForEach(0..<6, id: \.self) { i in
                ShimmerBar(width: CGFloat([620, 580, 640, 520, 600, 440][i]), height: 12)
            }
        }
        .frame(maxWidth: 700, alignment: .leading)
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ErrorPassage: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Theme.gold.opacity(0.85))
            Text("That one didn't load")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.text(scheme))
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
            Button("Try again") {
                Task { await store.load(store.query, record: false) }
            }
            .buttonStyle(SoftButtonStyle(prominent: true))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WelcomeView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme

    private let starters = ["Psalm 23", "John 1", "Romans 8", "Proverbs 3", "Isaiah 40", "Matthew 5"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NET STUDY")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.4)
                        .foregroundStyle(Theme.gold)
                    Text("Read slowly.\nTake notes.")
                        .font(.system(size: 40, weight: .regular, design: .serif))
                        .foregroundStyle(Theme.text(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !store.votd.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VERSE OF THE DAY")
                            .font(.system(size: 9.5, weight: .semibold))
                            .tracking(1.8)
                            .foregroundStyle(Theme.gold)
                        Text(store.votd.map(\.cleanText).joined(separator: " "))
                            .font(.system(size: 15, design: .serif))
                            .lineSpacing(6)
                            .foregroundStyle(Theme.text(scheme))
                            .lineLimit(5)
                        Text(store.votd.first?.bookname ?? "")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.secondaryText(scheme))
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.surface(scheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Theme.stroke(scheme), lineWidth: 1)
                            )
                    )
                }

                VStack(alignment: .leading, spacing: 9) {
                    SectionLabel(text: "Start somewhere")
                    FlowChips(items: starters) { ref in
                        if let parsed = Reference.parse(ref) {
                            store.open(book: parsed.book, chapter: parsed.chapter)
                        }
                    }
                }

                if !store.history.isEmpty {
                    VStack(alignment: .leading, spacing: 9) {
                        SectionLabel(text: "Recent")
                        FlowChips(items: store.history.prefix(6).map(\.title)) { title in
                            if let parsed = Reference.parse(title) {
                                store.open(book: parsed.book, chapter: parsed.chapter)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 36)
            .padding(.vertical, 46)
        }
        .scrollIndicators(.never)
    }
}

struct FlowChips: View {
    let items: [String]
    let action: (String) -> Void

    var body: some View {
        HStack(spacing: 7) {
            ForEach(items, id: \.self) { item in
                Button { action(item) } label: { Text(item) }
                    .buttonStyle(SoftButtonStyle())
            }
        }
    }
}
