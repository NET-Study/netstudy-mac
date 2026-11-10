import Foundation
import SwiftUI
import Combine

struct PersistedState: Codable {
    var highlights: [String: Int] = [:]
    var bookmarks: [Bookmark] = []
    var notes: [VerseNote] = []
    var history: [HistoryEntry] = []
    var fontSize: Double = 19
    var serif: Bool = true
    var columnWidth: Double = 720
    var lastQuery: String = "John 1"
    var appearance: String = "system"
}

@MainActor
final class AppStore: ObservableObject {
    @Published var query: PassageQuery
    @Published var verses: [Verse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedVerseID: String?
    @Published var votd: [Verse] = []
    @Published var votdLoading = false

    // Cached keyword search
    @Published var cachedMatches: [Verse] = []
    @Published var cachedPassageCount = 0
    @Published var cachedMatchesTruncated = false
    @Published var isSearchingCache = false
    /// Set after a search result is opened so the reader can scroll to it.
    @Published var pendingScrollVerseID: String?

    @Published var highlights: [String: Int] {
        didSet { scheduleSave() }
    }
    @Published var bookmarks: [Bookmark] {
        didSet { scheduleSave() }
    }
    @Published var notes: [VerseNote] {
        didSet { scheduleSave() }
    }
    @Published var history: [HistoryEntry] {
        didSet { scheduleSave() }
    }
    @Published var fontSize: Double {
        didSet { scheduleSave() }
    }
    @Published var serif: Bool {
        didSet { scheduleSave() }
    }
    @Published var columnWidth: Double {
        didSet { scheduleSave() }
    }
    @Published var appearance: String {
        didSet { scheduleSave() }
    }

    @Published var sidebarSection: SidebarSection = .read
    @Published var selectedBook: BibleBook?
    @Published var showSidebar = true

    enum SidebarSection: String, CaseIterable {
        case read = "Read"
        case saved = "Saved"
        case notes = "Notes"
    }

    private var saveTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private let stateURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = support.appendingPathComponent("NETStudy", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        stateURL = folder.appendingPathComponent("state.json")

        let saved: PersistedState
        if let data = try? Data(contentsOf: stateURL),
           let decoded = try? JSONDecoder().decode(PersistedState.self, from: data) {
            saved = decoded
        } else {
            saved = PersistedState()
        }

        highlights = saved.highlights
        bookmarks = saved.bookmarks
        notes = saved.notes
        history = saved.history
        fontSize = saved.fontSize
        serif = saved.serif
        columnWidth = saved.columnWidth
        appearance = saved.appearance
        let restored = PassageQuery.userInput(saved.lastQuery)
        if restored.kind != .reference || restored.reference != nil {
            query = restored
        } else {
            query = .reference(Reference(book: Bible.books[42], chapter: 1))
        }
        selectedBook = query.reference?.book

        Task { await load(query, record: false) }
        Task { await loadVerseOfTheDay() }
    }

    // MARK: - Loading

    func load(_ newQuery: PassageQuery, record: Bool = true) async {
        if case .reference = newQuery.kind, newQuery.reference == nil, newQuery.raw != "votd" && newQuery.raw != "random" {
            errorMessage = "I couldn't read that reference. Try something like \"John 3:16\" or \"Psalm 23\"."
            return
        }

        loadTask?.cancel()
        let task = Task { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
                self.selectedVerseID = nil
            }
            do {
                let result = try await BibleAPI.shared.fetch(newQuery)
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.22)) {
                        self.verses = result
                        self.query = newQuery
                        self.isLoading = false
                    }
                    if let ref = newQuery.reference {
                        self.selectedBook = ref.book
                    }
                    if record { self.recordHistory(newQuery) }
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.2)) {
                        self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
        loadTask = task
        await task.value
    }

    func loadVerseOfTheDay() async {
        votdLoading = true
        defer { votdLoading = false }
        if let result = try? await BibleAPI.shared.fetch(.verseOfTheDay) {
            withAnimation(.easeOut(duration: 0.3)) { votd = result }
        }
    }

    func goNextChapter() {
        guard let ref = query.reference, let next = ref.nextChapter else { return }
        Task { await load(.reference(next)) }
    }

    func goPreviousChapter() {
        guard let ref = query.reference, let prev = ref.previousChapter else { return }
        Task { await load(.reference(prev)) }
    }

    func open(book: BibleBook, chapter: Int = 1) {
        sidebarSection = .read
        Task { await load(.reference(Reference(book: book, chapter: min(max(chapter, 1), book.chapters)))) }
    }

    func openSaved(queryString: String) {
        guard let ref = Reference.parse(queryString) else { return }
        Task { await load(.reference(ref)) }
    }

    func openVerse(_ verse: Verse) {
        let ref = Reference.parse("\(verse.bookname) \(verse.chapter):\(verse.verse)")
        if let ref { Task { await load(.reference(ref)) } }
    }

    // MARK: - Cached keyword search

    private var searchTask: Task<Void, Never>?

    /// Searches the on-disk passage cache. Debounced so typing stays smooth.
    func searchCached(_ text: String) {
        searchTask?.cancel()
        let term = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard term.count >= 2 else {
            cachedMatches = []
            cachedPassageCount = 0
            cachedMatchesTruncated = false
            isSearchingCache = false
            return
        }

        isSearchingCache = true
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            let result = await BibleAPI.shared.searchCached(term)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                self.cachedMatches = result.verses
                self.cachedPassageCount = result.passages
                self.cachedMatchesTruncated = result.truncated
                self.isSearchingCache = false
            }
        }
    }

    func clearCachedSearch() {
        searchTask?.cancel()
        cachedMatches = []
        cachedPassageCount = 0
        cachedMatchesTruncated = false
        isSearchingCache = false
    }

    /// Opens the chapter holding a search hit, selects the verse, and asks the
    /// reader to scroll to it.
    func openSearchMatch(_ verse: Verse) async {
        guard let book = Bible.book(named: verse.bookname) else { return }
        let chapter = min(max(verse.chapterNumber, 1), book.chapters)
        let ref = Reference(book: book, chapter: chapter)
        await load(.reference(ref))
        selectedVerseID = verse.id
        pendingScrollVerseID = verse.id
    }

    func shuffleVerse() {
        Task { await load(.random) }
    }

    // MARK: - History

    private func recordHistory(_ q: PassageQuery) {
        guard !q.apiPassage.isEmpty else { return }
        history.removeAll { $0.apiQuery.caseInsensitiveCompare(q.apiPassage) == .orderedSame }
        history.insert(HistoryEntry(title: q.title, apiQuery: q.apiPassage), at: 0)
        if history.count > 40 { history = Array(history.prefix(40)) }
    }

    func clearHistory() {
        withAnimation { history = [] }
    }

    // MARK: - Highlights

    func highlightColor(for verse: Verse) -> Color? {
        guard let index = highlights[verse.id], Palette.highlights.indices.contains(index) else { return nil }
        return Palette.highlights[index]
    }

    func setHighlight(_ verse: Verse, index: Int?) {
        if let index {
            highlights[verse.id] = index
        } else {
            highlights.removeValue(forKey: verse.id)
        }
    }

    func isHighlighted(_ verse: Verse) -> Bool { highlights[verse.id] != nil }

    // MARK: - Bookmarks

    func isBookmarked(_ verse: Verse) -> Bool {
        bookmarks.contains { $0.reference == verse.reference }
    }

    func toggleBookmark(_ verse: Verse) {
        if let index = bookmarks.firstIndex(where: { $0.reference == verse.reference }) {
            _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                bookmarks.remove(at: index)
            }
        } else {
            let snippet = verse.cleanText
            let bookmark = Bookmark(reference: verse.reference,
                                    apiQuery: "\(verse.bookname) \(verse.chapter):\(verse.verse)",
                                    snippet: String(snippet.prefix(160)))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                bookmarks.insert(bookmark, at: 0)
            }
        }
    }

    func removeBookmark(_ bookmark: Bookmark) {
        withAnimation { bookmarks.removeAll { $0.id == bookmark.id } }
    }

    // MARK: - Notes

    func note(for reference: String) -> VerseNote? {
        notes.first { $0.reference == reference }
    }

    func saveNote(for verse: Verse, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = notes.firstIndex(where: { $0.reference == verse.reference }) {
            if trimmed.isEmpty {
                _ = withAnimation { notes.remove(at: index) }
            } else {
                notes[index].body = trimmed
                notes[index].updatedAt = Date()
            }
        } else if !trimmed.isEmpty {
            let note = VerseNote(reference: verse.reference,
                                 verseText: String(verse.cleanText.prefix(200)),
                                 body: trimmed)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                notes.insert(note, at: 0)
            }
        }
    }

    func removeNote(_ note: VerseNote) {
        withAnimation { notes.removeAll { $0.id == note.id } }
    }

    // MARK: - Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        var state = PersistedState()
        state.highlights = highlights
        state.bookmarks = bookmarks
        state.notes = notes
        state.history = history
        state.fontSize = fontSize
        state.serif = serif
        state.columnWidth = columnWidth
        state.lastQuery = query.reference?.apiQuery ?? query.raw
        state.appearance = appearance
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: stateURL, options: .atomic)
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var contextLabel: String {
        switch query.kind {
        case .verseOfTheDay: return "NET Bible · Verse of the Day"
        case .random: return "NET Bible · Random"
        case .reference, .custom: return "New English Translation"
        }
    }
}

// MARK: - Search helpers

enum ReferenceSuggestions {
    static func matches(for input: String, limit: Int = 6) -> [String] {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 1 else { return [] }
        let lower = text.lowercased()

        // If it already looks like a full reference, offer nothing.
        if Reference.parse(text) != nil, text.contains(where: { $0.isNumber }) { return [] }

        let starts = Bible.books.filter { book in
            book.allAliases.contains { $0.lowercased().hasPrefix(lower) }
        }
        let contains = Bible.books.filter { book in
            !starts.contains(book) && book.name.lowercased().contains(lower)
        }
        return (starts + contains).prefix(limit).map(\.name)
    }
}
