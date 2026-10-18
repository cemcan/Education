import Foundation

/// Loads the bundled word list once per process (app and widget each have their own copy).
final class WordRepository {
    static let shared = WordRepository()

    let words: [VocabWord]
    private let byID: [String: VocabWord]
    private let byLowercasedWord: [String: VocabWord]

    init(bundle: Bundle = .main) {
        var loaded: [VocabWord] = []
        if let url = bundle.url(forResource: "words", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                // Decode entry by entry so one malformed word is skipped instead of
                // discarding the whole list.
                let entries = try JSONDecoder().decode([LossyWord].self, from: data)
                loaded = entries.compactMap(\.word)
                if loaded.count < entries.count {
                    print("WordRepository: skipped \(entries.count - loaded.count) malformed entries")
                }
            } catch {
                print("WordRepository: failed to decode words.json – \(error)")
            }
        } else {
            print("WordRepository: words.json not found in bundle")
        }
        if loaded.isEmpty { loaded = [.preview] }

        words = loaded.sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
        byID = Dictionary(loaded.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        byLowercasedWord = Dictionary(loaded.map { ($0.word.lowercased(), $0) }, uniquingKeysWith: { first, _ in first })
    }

    func word(id: String) -> VocabWord? { byID[id] }

    /// Finds an entry by its headword, used to turn synonyms/related words into links.
    func entry(named name: String) -> VocabWord? { byLowercasedWord[name.lowercased()] }
}

/// Wraps a word so a decoding error yields nil rather than failing the array.
private struct LossyWord: Decodable {
    let word: VocabWord?

    init(from decoder: Decoder) throws {
        word = try? VocabWord(from: decoder)
    }
}
