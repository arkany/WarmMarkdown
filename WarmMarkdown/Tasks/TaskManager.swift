import Foundation

/// Manages task detection and state toggling in markdown text.
final class TaskManager {
    static let shared = TaskManager()

    private let taskPattern = #"^(\s*[-*+]\s)\[([ xX/\-])\]"#
    private lazy var taskRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: taskPattern)
    }()

    private init() {}

    /// Detect if a line contains a task and return its state
    func detectTask(in line: String) -> TaskState? {
        guard let regex = taskRegex else { return nil }
        let range = NSRange(location: 0, length: (line as NSString).length)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }

        let stateRange = match.range(at: 2)
        guard let r = Range(stateRange, in: line) else { return nil }
        let marker = String(line[r])
        return TaskState(marker: marker)
    }

    /// Toggle the task state on a line, returning the new line or nil if not a task
    func toggleTaskState(in line: String) -> String? {
        guard let currentState = detectTask(in: line) else { return nil }
        let nextState = currentState.next

        guard let regex = taskRegex else { return nil }
        let nsLine = line as NSString
        let range = NSRange(location: 0, length: nsLine.length)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }

        let stateRange = match.range(at: 2)
        let mutable = NSMutableString(string: line)
        mutable.replaceCharacters(in: stateRange, with: nextState.marker)

        return mutable as String
    }

    /// Create a new task line
    func createTaskLine(prefix: String = "- ", state: TaskState = .todo, text: String = "") -> String {
        "\(prefix)[\(state.marker)] \(text)"
    }

    /// Count tasks by state in a document
    func taskCounts(in content: String) -> [TaskState: Int] {
        var counts: [TaskState: Int] = [:]
        for state in TaskState.allCases {
            counts[state] = 0
        }

        content.enumerateLines { line, _ in
            if let state = self.detectTask(in: line) {
                counts[state, default: 0] += 1
            }
        }

        return counts
    }
}
