import SwiftUI

struct QuickSwitcher: View {
    @Environment(AppState.self) private var appState
    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.title3)

                TextField("Open note...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isFocused)
                    .onSubmit {
                        selectCurrent()
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)

            Divider()

            // Results
            if filteredNotes.isEmpty && !query.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.questionmark")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No matching notes")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else {
                ScrollViewReader { proxy in
                    List(selection: Binding(
                        get: { selectedIndex < filteredNotes.count ? filteredNotes[selectedIndex].id : nil },
                        set: { _ in }
                    )) {
                        ForEach(Array(filteredNotes.enumerated()), id: \.element.id) { index, note in
                            QuickSwitcherRow(note: note, isSelected: index == selectedIndex)
                                .id(note.id)
                                .onTapGesture {
                                    selectNote(note)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 300)
                    .onChange(of: selectedIndex) { _, newValue in
                        if newValue < filteredNotes.count {
                            proxy.scrollTo(filteredNotes[newValue].id)
                        }
                    }
                }
            }
        }
        .onAppear {
            isFocused = true
            selectedIndex = 0
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < filteredNotes.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.escape) {
            appState.showQuickSwitcher = false
            return .handled
        }
        .onChange(of: query) { _, _ in
            selectedIndex = 0
        }
    }

    private var filteredNotes: [NoteDocument] {
        if query.isEmpty {
            return Array(appState.fileManager.notes.prefix(20))
        }
        return SearchService.shared.search(query: query, in: appState.fileManager.notes)
    }

    private func selectCurrent() {
        guard selectedIndex < filteredNotes.count else { return }
        selectNote(filteredNotes[selectedIndex])
    }

    private func selectNote(_ note: NoteDocument) {
        appState.selectedNote = note
        appState.showQuickSwitcher = false
    }
}

struct QuickSwitcherRow: View {
    let note: NoteDocument
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)

                if !note.tags.isEmpty {
                    Text(note.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(note.lastModified, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
