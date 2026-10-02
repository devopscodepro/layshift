import Foundation

struct InputSource: Identifiable, Hashable, Sendable {
    enum Kind: Sendable {
        // a plain .keylayout such as ABC or Russian
        case keyboardLayout
        // a mode of an input method such as Hiragana or Pinyin
        case inputMode
    }

    let id: String
    let name: String
    let kind: Kind
    let languages: [String]

    // the two-letter code shown where there is no room for the name
    var shortCode: String {
        if let language = languages.first, let code = language.split(separator: "-").first, !code.isEmpty {
            return code.uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
