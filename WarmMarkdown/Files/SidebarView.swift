import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Notes list
            List(selection: Binding(
                get: { state.selectedNote },
                set: { state.selectedNote = $0 }
            )) {
                Section("Notes") {
                    ForEach(filteredNotes) { note in
                        NoteRow(note: note)
                            .tag(note)
                            .contextMenu {
                                Button("Delete") {
                                    state.fileManager.deleteNote(note)
                                    if state.selectedNote == note {
                                        state.selectedNote = nil
                                    }
                                }
                            }
                    }
                }

                if !allTags.isEmpty {
                    Section("Tags") {
                        ForEach(allTags, id: \.self) { tag in
                            Label(tag, systemImage: "number")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Bottom bar
            HStack {
                Button {
                    state.createNewNote()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.plain)
                .help("New Note")

                Spacer()

                Text("\(appState.fileManager.notes.count) notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
        }
        .frame(minWidth: 200)
    }

    private var filteredNotes: [NoteDocument] {
        if searchText.isEmpty {
            return appState.fileManager.notes
        }
        return SearchService.shared.search(query: searchText, in: appState.fileManager.notes)
    }

    private var allTags: [String] {
        let tags = appState.fileManager.notes.flatMap { $0.tags }
        return Array(Set(tags)).sorted()
    }
}

struct NoteRow: View {
    let note: NoteDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(note.title)
                .font(.system(.body, weight: .medium))
                .lineLimit(1)

            HStack {
                Text(note.lastModified, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !note.tags.isEmpty {
                    Text(note.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Text(previewText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }

    private var previewText: String {
        let lines = note.content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .filter { !$0.hasPrefix("# ") }
        return lines.prefix(2).joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
}
