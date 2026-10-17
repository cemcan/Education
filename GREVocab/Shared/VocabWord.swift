import Foundation

struct VocabExample: Codable, Hashable {
    enum Kind: String, Codable {
        case literature, news, speech

        var label: String {
            switch self {
            case .literature: return "Literature"
            case .news: return "News"
            case .speech: return "Speech"
            }
        }

        var systemImage: String {
            switch self {
            case .literature: return "book.closed"
            case .news: return "newspaper"
            case .speech: return "mic"
            }
        }
    }

    var text: String
    var source: String
    var author: String?
    var year: Int?
    var kind: Kind

    /// The sentence wrapped in curly quotes, unless it already opens with a quotation mark.
    var quoted: String {
        guard let first = text.first, !"\"“‘'".contains(first) else { return text }
        return "“\(text)”"
    }

    /// "Author, Source (year)" as plain text, for places that can't use styled Text.
    var plainAttribution: String {
        var parts: [String] = []
        if let author, !author.isEmpty { parts.append(author) }
        parts.append(source)
        var line = parts.joined(separator: ", ")
        if let year { line += " (\(String(year)))" }
        return line
    }
}

struct VocabWord: Codable, Identifiable, Hashable {
    var id: String
    var word: String
    var partOfSpeech: String
    var ipa: String
    var phonetic: String
    var definition: String
    var synonyms: [String]
    var antonyms: [String]
    var relatedWords: [String]
    var etymology: String?
    var examples: [VocabExample]

    init(id: String, word: String, partOfSpeech: String, ipa: String, phonetic: String,
         definition: String, synonyms: [String] = [], antonyms: [String] = [],
         relatedWords: [String] = [], etymology: String? = nil, examples: [VocabExample] = []) {
        self.id = id
        self.word = word
        self.partOfSpeech = partOfSpeech
        self.ipa = ipa
        self.phonetic = phonetic
        self.definition = definition
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.relatedWords = relatedWords
        self.etymology = etymology
        self.examples = examples
    }

    // Lenient decoding: optional lists may be omitted in the JSON.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        word = try c.decode(String.self, forKey: .word)
        partOfSpeech = try c.decodeIfPresent(String.self, forKey: .partOfSpeech) ?? ""
        ipa = try c.decodeIfPresent(String.self, forKey: .ipa) ?? ""
        phonetic = try c.decodeIfPresent(String.self, forKey: .phonetic) ?? ""
        definition = try c.decode(String.self, forKey: .definition)
        synonyms = try c.decodeIfPresent([String].self, forKey: .synonyms) ?? []
        antonyms = try c.decodeIfPresent([String].self, forKey: .antonyms) ?? []
        relatedWords = try c.decodeIfPresent([String].self, forKey: .relatedWords) ?? []
        etymology = try c.decodeIfPresent(String.self, forKey: .etymology)
        examples = try c.decodeIfPresent([VocabExample].self, forKey: .examples) ?? []
    }

    var deepLink: URL? {
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        return URL(string: "grevocab://word/\(encoded)")
    }
}

extension VocabWord {
    /// Used for SwiftUI previews, widget placeholders and as a fallback if words.json is missing.
    static let preview = VocabWord(
        id: "laconic",
        word: "laconic",
        partOfSpeech: "adjective",
        ipa: "/ləˈkɑnɪk/",
        phonetic: "luh-KON-ik",
        definition: "Using very few words; brief and to the point, sometimes to the point of seeming rude or mysterious.",
        synonyms: ["terse", "succinct", "pithy", "concise"],
        antonyms: ["verbose", "loquacious", "garrulous"],
        relatedWords: ["laconism", "brevity"],
        etymology: "From Latin Laconicus, from Greek Lakōnikos, \"of Laconia\" — the region of Sparta, whose people were famous for their curt speech.",
        examples: [
            VocabExample(text: "Sample sentence shown in previews only.", source: "Preview", author: nil, year: nil, kind: .literature)
        ]
    )
}
