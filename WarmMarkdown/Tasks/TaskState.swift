import Foundation

/// Four-state task model: todo, done, inProgress, blocked
enum TaskState: String, CaseIterable {
    case todo
    case done
    case inProgress
    case blocked

    /// The character inside the brackets
    var marker: String {
        switch self {
        case .todo: return " "
        case .done: return "x"
        case .inProgress: return "/"
        case .blocked: return "-"
        }
    }

    /// The full bracket representation
    var bracketRepresentation: String {
        "[\(marker)]"
    }

    /// Cycle to next state: todo → inProgress → done → blocked → todo
    var next: TaskState {
        switch self {
        case .todo: return .inProgress
        case .inProgress: return .done
        case .done: return .blocked
        case .blocked: return .todo
        }
    }

    /// Display label
    var label: String {
        switch self {
        case .todo: return "To Do"
        case .done: return "Done"
        case .inProgress: return "In Progress"
        case .blocked: return "Blocked"
        }
    }

    /// SF Symbol name for the checkbox
    var symbolName: String {
        switch self {
        case .todo: return "circle"
        case .done: return "checkmark.circle.fill"
        case .inProgress: return "circle.dotted.circle"
        case .blocked: return "xmark.circle"
        }
    }

    /// Initialize from the character inside brackets
    init?(marker: String) {
        switch marker {
        case " ": self = .todo
        case "x", "X": self = .done
        case "/": self = .inProgress
        case "-": self = .blocked
        default: return nil
        }
    }
}
