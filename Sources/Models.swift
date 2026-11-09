import Foundation
import SwiftUI

// MARK: - Verse

struct Verse: Identifiable, Hashable, Codable {
    let bookname: String
    let chapter: String
    let verse: String
    let text: String

    var id: String { "\(bookname)|\(chapter)|\(verse)" }

    var reference: String { "\(bookname) \(chapter):\(verse)" }

    var cleanText: String {
        text
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var chapterNumber: Int { Int(chapter) ?? 0 }
    var verseNumber: Int { Int(verse) ?? 0 }
}

// MARK: - Books

struct BibleBook: Identifiable, Hashable {
    let name: String
    let aliases: [String]
    let chapters: Int
    let testament: Testament

    var id: String { name }

    var allAliases: [String] {
        var set: [String] = [name]
        for a in aliases where !set.contains(where: { $0.caseInsensitiveCompare(a) == .orderedSame }) {
            set.append(a)
        }
        return set
    }

    enum Testament: String {
        case old = "Old Testament"
        case new = "New Testament"
    }
}

enum Bible {
    static let books: [BibleBook] = [
        // Old Testament
        BibleBook(name: "Genesis", aliases: ["Gen", "Ge", "Gn"], chapters: 50, testament: .old),
        BibleBook(name: "Exodus", aliases: ["Exod", "Ex", "Exo"], chapters: 40, testament: .old),
        BibleBook(name: "Leviticus", aliases: ["Lev", "Le", "Lv"], chapters: 27, testament: .old),
        BibleBook(name: "Numbers", aliases: ["Num", "Nu", "Nm", "Nb"], chapters: 36, testament: .old),
        BibleBook(name: "Deuteronomy", aliases: ["Deut", "De", "Dt"], chapters: 34, testament: .old),
        BibleBook(name: "Joshua", aliases: ["Josh", "Jos", "Jsh"], chapters: 24, testament: .old),
        BibleBook(name: "Judges", aliases: ["Judg", "Jdg", "Jg"], chapters: 21, testament: .old),
        BibleBook(name: "Ruth", aliases: ["Rth", "Ru"], chapters: 4, testament: .old),
        BibleBook(name: "1 Samuel", aliases: ["1 Sam", "1 Sa", "1 Sm", "1Samuel", "I Samuel", "1st Samuel"], chapters: 31, testament: .old),
        BibleBook(name: "2 Samuel", aliases: ["2 Sam", "2 Sa", "2 Sm", "2Samuel", "II Samuel", "2nd Samuel"], chapters: 24, testament: .old),
        BibleBook(name: "1 Kings", aliases: ["1 Kgs", "1 Ki", "1 Kings", "I Kings", "1st Kings"], chapters: 22, testament: .old),
        BibleBook(name: "2 Kings", aliases: ["2 Kgs", "2 Ki", "2 Kings", "II Kings", "2nd Kings"], chapters: 25, testament: .old),
        BibleBook(name: "1 Chronicles", aliases: ["1 Chr", "1 Ch", "1 Chron", "I Chronicles", "1st Chronicles"], chapters: 29, testament: .old),
        BibleBook(name: "2 Chronicles", aliases: ["2 Chr", "2 Ch", "2 Chron", "II Chronicles", "2nd Chronicles"], chapters: 36, testament: .old),
        BibleBook(name: "Ezra", aliases: ["Ezr"], chapters: 10, testament: .old),
        BibleBook(name: "Nehemiah", aliases: ["Neh", "Ne"], chapters: 13, testament: .old),
        BibleBook(name: "Esther", aliases: ["Est", "Es"], chapters: 10, testament: .old),
        BibleBook(name: "Job", aliases: ["Jb"], chapters: 42, testament: .old),
        BibleBook(name: "Psalms", aliases: ["Ps", "Psa", "Psalm", "Pss", "Psm"], chapters: 150, testament: .old),
        BibleBook(name: "Proverbs", aliases: ["Prov", "Pr", "Pro", "Prv"], chapters: 31, testament: .old),
        BibleBook(name: "Ecclesiastes", aliases: ["Eccl", "Ecc", "Ec", "Qoh"], chapters: 12, testament: .old),
        BibleBook(name: "Song of Songs", aliases: ["Song of Songs", "Song of Solomon", "Song", "SOS", "Canticles"], chapters: 8, testament: .old),
        BibleBook(name: "Isaiah", aliases: ["Isa", "Is"], chapters: 66, testament: .old),
        BibleBook(name: "Jeremiah", aliases: ["Jer", "Je", "Jr"], chapters: 52, testament: .old),
        BibleBook(name: "Lamentations", aliases: ["Lam", "La"], chapters: 5, testament: .old),
        BibleBook(name: "Ezekiel", aliases: ["Ezek", "Eze", "Ezk"], chapters: 48, testament: .old),
        BibleBook(name: "Daniel", aliases: ["Dan", "Da", "Dn"], chapters: 12, testament: .old),
        BibleBook(name: "Hosea", aliases: ["Hos", "Ho"], chapters: 14, testament: .old),
        BibleBook(name: "Joel", aliases: ["Jol"], chapters: 3, testament: .old),
        BibleBook(name: "Amos", aliases: ["Am"], chapters: 9, testament: .old),
        BibleBook(name: "Obadiah", aliases: ["Obad", "Ob"], chapters: 1, testament: .old),
        BibleBook(name: "Jonah", aliases: ["Jon", "Jnh"], chapters: 4, testament: .old),
        BibleBook(name: "Micah", aliases: ["Mic", "Mi"], chapters: 7, testament: .old),
        BibleBook(name: "Nahum", aliases: ["Nah", "Na"], chapters: 3, testament: .old),
        BibleBook(name: "Habakkuk", aliases: ["Hab", "Hb"], chapters: 3, testament: .old),
        BibleBook(name: "Zephaniah", aliases: ["Zeph", "Zep", "Zp"], chapters: 3, testament: .old),
        BibleBook(name: "Haggai", aliases: ["Hag", "Hg"], chapters: 2, testament: .old),
        BibleBook(name: "Zechariah", aliases: ["Zech", "Zec", "Zc"], chapters: 14, testament: .old),
        BibleBook(name: "Malachi", aliases: ["Mal", "Ml"], chapters: 4, testament: .old),

        // New Testament
        BibleBook(name: "Matthew", aliases: ["Matt", "Mt", "Mat"], chapters: 28, testament: .new),
        BibleBook(name: "Mark", aliases: ["Mk", "Mrk", "Mr"], chapters: 16, testament: .new),
        BibleBook(name: "Luke", aliases: ["Lk", "Luk"], chapters: 24, testament: .new),
        BibleBook(name: "John", aliases: ["Jn", "Jhn"], chapters: 21, testament: .new),
        BibleBook(name: "Acts", aliases: ["Ac", "Act"], chapters: 28, testament: .new),
        BibleBook(name: "Romans", aliases: ["Rom", "Ro", "Rm"], chapters: 16, testament: .new),
        BibleBook(name: "1 Corinthians", aliases: ["1 Cor", "1 Co", "1Cor", "I Corinthians", "1st Corinthians"], chapters: 16, testament: .new),
        BibleBook(name: "2 Corinthians", aliases: ["2 Cor", "2 Co", "2Cor", "II Corinthians", "2nd Corinthians"], chapters: 13, testament: .new),
        BibleBook(name: "Galatians", aliases: ["Gal", "Ga"], chapters: 6, testament: .new),
        BibleBook(name: "Ephesians", aliases: ["Eph", "Ep"], chapters: 6, testament: .new),
        BibleBook(name: "Philippians", aliases: ["Phil", "Php", "Pp"], chapters: 4, testament: .new),
        BibleBook(name: "Colossians", aliases: ["Col", "Co"], chapters: 4, testament: .new),
        BibleBook(name: "1 Thessalonians", aliases: ["1 Thess", "1 Th", "1 Thes", "I Thessalonians", "1st Thessalonians"], chapters: 5, testament: .new),
        BibleBook(name: "2 Thessalonians", aliases: ["2 Thess", "2 Th", "2 Thes", "II Thessalonians", "2nd Thessalonians"], chapters: 3, testament: .new),
        BibleBook(name: "1 Timothy", aliases: ["1 Tim", "1 Ti", "1 Tm", "I Timothy", "1st Timothy"], chapters: 6, testament: .new),
        BibleBook(name: "2 Timothy", aliases: ["2 Tim", "2 Ti", "2 Tm", "II Timothy", "2nd Timothy"], chapters: 4, testament: .new),
        BibleBook(name: "Titus", aliases: ["Tit", "Ti"], chapters: 3, testament: .new),
        BibleBook(name: "Philemon", aliases: ["Philem", "Phm", "Phile"], chapters: 1, testament: .new),
        BibleBook(name: "Hebrews", aliases: ["Heb", "He"], chapters: 13, testament: .new),
        BibleBook(name: "James", aliases: ["Jas", "Ja"], chapters: 5, testament: .new),
        BibleBook(name: "1 Peter", aliases: ["1 Pet", "1 Pe", "1 P", "I Peter", "1st Peter"], chapters: 5, testament: .new),
        BibleBook(name: "2 Peter", aliases: ["2 Pet", "2 Pe", "2 P", "II Peter", "2nd Peter"], chapters: 3, testament: .new),
        BibleBook(name: "1 John", aliases: ["1 Jn", "1 Jo", "I John", "1st John"], chapters: 5, testament: .new),
        BibleBook(name: "2 John", aliases: ["2 Jn", "2 Jo", "II John", "2nd John"], chapters: 1, testament: .new),
        BibleBook(name: "3 John", aliases: ["3 Jn", "3 Jo", "III John", "3rd John"], chapters: 1, testament: .new),
        BibleBook(name: "Jude", aliases: ["Jud", "Jd"], chapters: 1, testament: .new),
        BibleBook(name: "Revelation", aliases: ["Rev", "Re", "Rv", "Apocalypse"], chapters: 22, testament: .new)
    ]

    static func book(named name: String) -> BibleBook? {
        books.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    static var oldTestament: [BibleBook] { books.filter { $0.testament == .old } }
    static var newTestament: [BibleBook] { books.filter { $0.testament == .new } }
}

// MARK: - Reference

struct Reference: Hashable {
    var book: BibleBook
    var chapter: Int
    var verseStart: Int?
    var verseEnd: Int?

    var display: String {
        if book.chapters == 1, let v = verseStart {
            var s = "\(book.name) \(v)"
            if let e = verseEnd, e != v { s += "-\(e)" }
            return s
        }
        var s = "\(book.name) \(chapter)"
        if let v = verseStart {
            s += ":\(v)"
            if let e = verseEnd, e != v { s += "-\(e)" }
        }
        return s
    }

    /// The string sent to the API.
    var apiQuery: String {
        var base = "\(book.name) \(chapter)"
        if let v = verseStart {
            base += ":\(v)"
            if let e = verseEnd, e != v { base += "-\(e)" }
        }
        return base
    }

    var nextChapter: Reference? {
        if chapter < book.chapters {
            return Reference(book: book, chapter: chapter + 1)
        }
        if let i = Bible.books.firstIndex(of: book), i + 1 < Bible.books.count {
            return Reference(book: Bible.books[i + 1], chapter: 1)
        }
        return nil
    }

    var previousChapter: Reference? {
        if chapter > 1 {
            return Reference(book: book, chapter: chapter - 1)
        }
        if let i = Bible.books.firstIndex(of: book), i > 0 {
            let prev = Bible.books[i - 1]
            return Reference(book: prev, chapter: prev.chapters)
        }
        return nil
    }

    static func parse(_ input: String) -> Reference? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        let normalized = raw
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .split(separator: " ")
            .joined(separator: " ")

        var bestBook: BibleBook?
        var bestLength = 0

        for book in Bible.books {
            for alias in book.allAliases {
                let a = alias.lowercased().replacingOccurrences(of: ".", with: "")
                guard normalized.hasPrefix(a) else { continue }
                let remainder = normalized.dropFirst(a.count)
                guard remainder.isEmpty || remainder.first == " " || remainder.first == ":" || (remainder.first?.isNumber ?? false) else { continue }
                if a.count > bestLength {
                    bestLength = a.count
                    bestBook = book
                }
            }
        }

        guard let book = bestBook else { return nil }

        var rest = String(normalized.dropFirst(bestLength)).trimmingCharacters(in: .whitespaces)
        if rest.hasPrefix(":") { rest = "1" + rest }

        // chapter
        var chapter = 1
        var verses: (Int?, Int?) = (nil, nil)

        // Single-chapter books read "Jude 3" as verse 3, not chapter 3.
        if book.chapters == 1, !rest.contains(":"), let n = Int(rest), n > 0 {
            rest = "1:\(n)"
        }

        let chapterPart = rest.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        if let first = chapterPart.first {
            let digits = first.trimmingCharacters(in: .whitespaces)
            if let n = Int(digits) {
                chapter = min(max(n, 1), book.chapters)
            } else if !digits.isEmpty {
                return nil
            }
        }

        if chapterPart.count == 2 {
            let versePart = chapterPart[1].trimmingCharacters(in: .whitespaces)
            let rangeParts = versePart.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
            if let start = Int(rangeParts[0].trimmingCharacters(in: .whitespaces)) {
                verses.0 = max(start, 1)
            }
            if rangeParts.count == 2, let end = Int(rangeParts[1].trimmingCharacters(in: .whitespaces)) {
                verses.1 = max(end, verses.0 ?? 1)
            }
        }

        return Reference(book: book, chapter: chapter, verseStart: verses.0, verseEnd: verses.1)
    }
}

/// A passage request can hold several references or a special feed (votd / random).
struct PassageQuery: Hashable {
    enum Kind: Hashable {
        case reference
        case verseOfTheDay
        case random
        case custom(String)
    }

    var raw: String
    var kind: Kind

    var reference: Reference? {
        if case .custom = kind { return nil }
        return Reference.parse(raw)
    }

    var title: String {
        switch kind {
        case .verseOfTheDay: return "Verse of the Day"
        case .random: return "Random Verse"
        case .reference, .custom: return reference?.display ?? raw
        }
    }

    var apiPassage: String {
        switch kind {
        case .verseOfTheDay: return "votd"
        case .random: return "random"
        case .reference, .custom: return raw
        }
    }

    static let verseOfTheDay = PassageQuery(raw: "votd", kind: .verseOfTheDay)
    static let random = PassageQuery(raw: "random", kind: .random)

    static func reference(_ ref: Reference) -> PassageQuery {
        PassageQuery(raw: ref.apiQuery, kind: .reference)
    }

    static func userInput(_ text: String) -> PassageQuery {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        if lower == "votd" { return .verseOfTheDay }
        if lower == "random" { return .random }

        let parts = trimmed
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if parts.count > 1 {
            let refs = parts.compactMap(Reference.parse)
            if refs.count == parts.count {
                let joined = refs.map(\.apiQuery).joined(separator: "; ")
                return PassageQuery(raw: joined, kind: .custom(joined))
            }
        }
        return PassageQuery(raw: trimmed, kind: .reference)
    }

    var isMultiPassage: Bool {
        if case .custom = kind { return true }
        return false
    }
}

// MARK: - Saved items

struct Bookmark: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var reference: String
    var apiQuery: String
    var snippet: String
    var createdAt: Date = Date()
}

struct VerseNote: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var reference: String
    var verseText: String
    var body: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct HistoryEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var apiQuery: String
    var visitedAt: Date = Date()
}

// MARK: - Palette

enum Palette {
    static let highlights: [Color] = [
        Color(red: 0.98, green: 0.84, blue: 0.36), // gold
        Color(red: 0.55, green: 0.82, blue: 0.62), // sage
        Color(red: 0.62, green: 0.76, blue: 0.96), // sky
        Color(red: 0.93, green: 0.66, blue: 0.78), // rose
        Color(red: 0.80, green: 0.72, blue: 0.95)  // violet
    ]

    static let highlightNames = ["Gold", "Sage", "Sky", "Rose", "Violet"]
}
