import Foundation

enum BibleAPIError: LocalizedError {
    case badURL
    case badStatus(Int)
    case unreachable
    case empty
    case message(String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "That reference doesn't look quite right."
        case .badStatus(let code): return "The Bible service replied with \(code)."
        case .unreachable: return "Can't reach the NET Bible service right now."
        case .empty: return "No verses came back for that reference."
        case .message(let m): return m
        }
    }
}

/// Talks to https://labs.bible.org/api/
actor BibleAPI {
    static let shared = BibleAPI()

    private let session: URLSession
    private var memory: [String: [Verse]] = [:]
    private let cacheDirectory: URL

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 18
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024,
                                   diskCapacity: 80 * 1024 * 1024,
                                   diskPath: "netstudy-urlcache")
        session = URLSession(configuration: config)

        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDirectory = support.appendingPathComponent("NETStudy/passages", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func fetch(_ query: PassageQuery) async throws -> [Verse] {
        let key = query.apiPassage
        if let hit = memory[key] { return hit }

        do {
            let verses = try await request(passage: key)
            memory[key] = verses
            try? write(verses, for: key)
            return verses
        } catch {
            if let disk = read(for: key), !disk.isEmpty {
                memory[key] = disk
                return disk
            }
            throw error
        }
    }

    private func request(passage: String) async throws -> [Verse] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "labs.bible.org"
        components.path = "/api/"
        components.queryItems = [
            URLQueryItem(name: "passage", value: passage),
            URLQueryItem(name: "formatting", value: "plain"),
            URLQueryItem(name: "type", value: "json")
        ]

        guard let url = components.url else { throw BibleAPIError.badURL }

        var request = URLRequest(url: url)
        request.setValue("NETStudy/1.0 (macOS)", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw BibleAPIError.unreachable
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw BibleAPIError.badStatus(http.statusCode)
        }

        // The service occasionally answers with an HTML error page even on 200.
        if let object = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            let verses = object.compactMap { item -> Verse? in
                guard let book = item["bookname"] as? String,
                      let chapter = item["chapter"] as? String,
                      let verse = item["verse"] as? String,
                      let text = item["text"] as? String else { return nil }
                return Verse(bookname: book, chapter: chapter, verse: verse, text: text)
            }
            if verses.isEmpty { throw BibleAPIError.empty }
            return verses
        }

        if let html = String(data: data, encoding: .utf8) {
            let stripped = html
                .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !stripped.isEmpty {
                throw BibleAPIError.message(stripped.prefix(180).description)
            }
        }
        throw BibleAPIError.empty
    }

    // MARK: - Disk cache

    private func cacheFile(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(stableName(key) + ".json")
    }

    private func stableName(_ key: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        let safe = key.replacingOccurrences(of: "/", with: "-")
        return "\(safe.prefix(28).replacingOccurrences(of: " ", with: "_"))-\(String(hash, radix: 16))"
    }

    private func write(_ verses: [Verse], for key: String) throws {
        let data = try JSONEncoder().encode(verses)
        try data.write(to: cacheFile(for: key), options: .atomic)
    }

    private func read(for key: String) -> [Verse]? {
        guard let data = try? Data(contentsOf: cacheFile(for: key)) else { return nil }
        return try? JSONDecoder().decode([Verse].self, from: data)
    }

    // MARK: - Cached keyword search

    struct CachedSearch {
        var verses: [Verse] = []
        var passages = 0
        var truncated = false
    }

    private static let bookOrder: [String: Int] = Dictionary(
        uniqueKeysWithValues: Bible.books.enumerated().map { ($0.element.name.lowercased(), $0.offset) }
    )

    /// Full-text search over passages already cached on disk.
    /// Every whitespace-separated token must appear somewhere in the verse.
    func searchCached(_ term: String, limit: Int = 80) -> CachedSearch {
        let tokens = term
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return CachedSearch() }

        let files = (try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        let passageFiles = files.filter { $0.pathExtension.lowercased() == "json" }

        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        var seen = Set<String>()
        var hits: [Verse] = []

        for file in passageFiles {
            guard let data = try? Data(contentsOf: file),
                  let verses = try? JSONDecoder().decode([Verse].self, from: data) else { continue }
            for verse in verses where !seen.contains(verse.id) {
                let text = verse.cleanText
                guard tokens.allSatisfy({ text.range(of: $0, options: options) != nil }) else { continue }
                seen.insert(verse.id)
                hits.append(verse)
            }
        }

        hits.sort { a, b in
            let left = Self.bookOrder[a.bookname.lowercased()] ?? Int.max
            let right = Self.bookOrder[b.bookname.lowercased()] ?? Int.max
            if left != right { return left < right }
            if a.chapterNumber != b.chapterNumber { return a.chapterNumber < b.chapterNumber }
            return a.verseNumber < b.verseNumber
        }

        return CachedSearch(verses: Array(hits.prefix(limit)),
                            passages: passageFiles.count,
                            truncated: hits.count > limit)
    }
}
