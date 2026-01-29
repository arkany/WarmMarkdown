import Foundation

/// Codable model matching VSCode theme JSON schema
struct VSCodeThemeFile: Codable {
    var name: String?
    var type: String?
    var colors: [String: String]?
    var tokenColors: [TokenColor]?

    struct TokenColor: Codable {
        var name: String?
        var scope: ScopeValue?
        var settings: TokenSettings?

        struct TokenSettings: Codable {
            var foreground: String?
            var background: String?
            var fontStyle: String?
        }

        enum ScopeValue: Codable {
            case single(String)
            case multiple([String])

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let str = try? container.decode(String.self) {
                    self = .single(str)
                } else if let arr = try? container.decode([String].self) {
                    self = .multiple(arr)
                } else {
                    self = .single("")
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .single(let s): try container.encode(s)
                case .multiple(let a): try container.encode(a)
                }
            }

            var scopes: [String] {
                switch self {
                case .single(let s): return s.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                case .multiple(let a): return a
                }
            }
        }
    }

    /// Find the foreground color for a given token scope
    func colorForScope(_ targetScope: String) -> String? {
        guard let tokenColors else { return nil }
        for token in tokenColors {
            guard let scope = token.scope else { continue }
            for s in scope.scopes {
                if s == targetScope || s.hasPrefix(targetScope + ".") || targetScope.hasPrefix(s + ".") {
                    return token.settings?.foreground
                }
            }
        }
        return nil
    }

    /// Get an editor color
    func editorColor(_ key: String) -> String? {
        colors?[key]
    }
}
