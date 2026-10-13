// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

/// Translate presentation text, never identifiers, logs or error-matching input.
/// Shared is compiled into the app and widget; each reads its own bundle resources.
enum HuskL10n {
    static func text(_ english: String) -> String {
        let direct = Bundle.main.localizedString(forKey: english, value: english, table: "Localizable")
        if direct != english { return direct }
        // Runtime errors and older saved diagnoses keep their original English values.
        for template in templates {
            let range = NSRange(english.startIndex..., in: english)
            guard let match = template.pattern.firstMatch(in: english, range: range) else { continue }
            let arguments: [CVarArg] = (1..<match.numberOfRanges).compactMap { index in
                guard let capture = Range(match.range(at: index), in: english) else { return nil }
                return String(english[capture])
            }
            return String(format: template.translation, locale: Locale.current, arguments: arguments)
        }
        return english
    }

    private struct Template {
        let pattern: NSRegularExpression
        let translation: String
    }

    private static let templates: [Template] = {
        guard let url = Bundle.main.url(forResource: "Localizable", withExtension: "strings",
                                        subdirectory: nil, localization: "en"),
              let data = try? Data(contentsOf: url),
              let entries = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: String]
        else { return [] }
        return entries.keys.filter { $0.contains("%@") }.sorted { $0.count > $1.count }.compactMap { key in
            let translated = Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
            guard translated != key else { return nil }
            let pattern = "\\A" + key.components(separatedBy: "%@")
                .map { NSRegularExpression.escapedPattern(for: $0.replacingOccurrences(of: "%%", with: "%")) }
                .joined(separator: "(.*?)") + "\\z"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return nil }
            return Template(pattern: regex, translation: translated)
        }
    }()

    static func render(_ message: Message) -> String {
        let translated = text(message.key)
        guard !message.arguments.isEmpty else { return translated }
        return String(format: translated, locale: Locale.current, arguments: message.arguments)
    }

    struct Message: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
        let key: String
        let arguments: [CVarArg]
        init(stringLiteral value: String) { key = value; arguments = [] }
        init(stringInterpolation: StringInterpolation) {
            key = stringInterpolation.key
            arguments = stringInterpolation.arguments
        }
        struct StringInterpolation: StringInterpolationProtocol {
            var key = ""
            var arguments: [CVarArg] = []
            init(literalCapacity: Int, interpolationCount: Int) {
                key.reserveCapacity(literalCapacity)
                arguments.reserveCapacity(interpolationCount)
            }
            mutating func appendLiteral(_ literal: String) {
                key += literal.replacingOccurrences(of: "%", with: "%%")
            }
            mutating func appendInterpolation<T>(_ value: T) {
                key += "%@"
                arguments.append(String(describing: value))
            }
        }
    }
}
