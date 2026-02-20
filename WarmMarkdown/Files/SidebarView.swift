import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var appeared = false

    private var theme: MarkdownTheme { appState.themeManager.currentTheme }

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(theme.sidebarItemActive))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(theme.sidebarTextSecondary))
                        )
                    Text("WarmMarkdown")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(theme.sidebarTextPrimary))
                        .tracking(-0.2)
                }

                Spacer()

                Button {
                    // Settings placeholder
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(theme.sidebarTextMuted))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(theme.sidebarTextMuted))
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(theme.sidebarTextMuted))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(theme.searchBackground))
            )
            .padding(.horizontal, 14)
            .padding(.bottom, state.activeTag != nil ? 6 : 12)
            .opacity(appeared ? 1 : 0)
            .offset(x: appeared ? 0 : -20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

            // Active tag filter chip
            if let activeTag = state.activeTag {
                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .font(.caption2)
                    Text(activeTag)
                        .font(.caption)
                    Button {
                        state.activeTag = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                .foregroundStyle(Color(theme.accentColor))
            }

            // Navigation
            VStack(spacing: 2) {
                SidebarNavItem(
                    icon: "doc.text",
                    label: "All Notes",
                    count: filteredNotes.count,
                    isActive: true,
                    accentColor: Color(theme.accentColor),
                    theme: theme
                ) {
                    searchText = ""
                    state.activeTag = nil
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)

                SidebarNavItem(
                    icon: "star",
                    label: "Favorites",
                    isActive: false,
                    accentColor: Color(theme.accentColor),
                    theme: theme
                )
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)

                SidebarNavItem(
                    icon: "trash",
                    label: "Trash",
                    isActive: false,
                    accentColor: Color(theme.accentColor),
                    theme: theme
                )
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)
            }
            .padding(.horizontal, 8)

            // Tags section
            if !allTags.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TAGS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(theme.sidebarTextMuted))
                        .tracking(1)
                        .padding(.horizontal, 12)
                        .padding(.top, 20)
                        .padding(.bottom, 6)

                    ForEach(allTags, id: \.self) { tag in
                        HStack(spacing: 6) {
                            Text("#")
                                .foregroundStyle(state.activeTag == tag ? Color(theme.accentColor) : Color(theme.tagHashColor))
                            Text(tag)
                                .fontWeight(state.activeTag == tag ? .semibold : .regular)
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(state.activeTag == tag ? Color(theme.accentColor) : Color(theme.tagTextColor))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            state.activeTag = (state.activeTag == tag) ? nil : tag
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: appeared)
            }

            Spacer()

            // Notes list when searching or filtering by tag
            if !searchText.isEmpty || state.activeTag != nil {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredNotes) { note in
                            NoteRow(note: note, isSelected: state.selectedNote == note, theme: theme)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    state.selectedNote = note
                                }
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
                    .padding(.horizontal, 8)
                }
            }

            // Bottom user area
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(theme.accentColor), Color(theme.accentColor).opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 30, height: 30)
                    Text(userInitials)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(NSFullUserName().components(separatedBy: " ").first ?? "User")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(theme.sidebarTextPrimary))
                    Group {
                        if state.activeTag != nil {
                            Text("\(filteredNotes.count)/\(appState.fileManager.notes.count) notes")
                        } else {
                            Text("\(appState.fileManager.notes.count) notes")
                        }
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(Color(theme.sidebarTextMuted))
                }

                Spacer()

                Button {
                    state.createNewNote()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(theme.sidebarTextMuted))
                }
                .buttonStyle(.plain)
                .help("New Note")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .overlay(alignment: .top) {
                Divider().background(Color(theme.sidebarBorder))
            }
            .opacity(appeared ? 1 : 0)
            .offset(x: appeared ? 0 : -20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: appeared)
        }
        .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)
        .background(Color(theme.sidebarBackground))
        .onAppear { appeared = true }
    }

    private var userInitials: String {
        let name = NSFullUserName()
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var filteredNotes: [NoteDocument] {
        var notes = appState.fileManager.notes

        // Apply tag filter first
        if let tag = appState.activeTag {
            notes = notes.filter { $0.tags.contains(tag) }
        }

        // Then apply text search
        if searchText.isEmpty {
            return notes
        }
        return SearchService.shared.search(query: searchText, in: notes)
    }

    private var allTags: [String] {
        let tags = appState.fileManager.notes.flatMap { $0.tags }
        return Array(Set(tags)).sorted()
    }
}

// MARK: - Sidebar Nav Item

struct SidebarNavItem: View {
    let icon: String
    let label: String
    var count: Int? = nil
    let isActive: Bool
    let accentColor: Color
    let theme: MarkdownTheme
    var action: (() -> Void)? = nil
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isActive ? accentColor : Color(theme.sidebarTextSecondary))
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isActive ? Color(theme.sidebarTextPrimary) : Color(theme.sidebarTextSecondary))

            Spacer()

            if let count = count {
                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(theme.sidebarTextMuted))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color(theme.sidebarItemActive) : (isHovered ? Color(theme.sidebarItemHover) : Color.clear))
                .shadow(color: isActive ? .black.opacity(0.04) : .clear, radius: 1, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isActive ? Color.black.opacity(0.05) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { action?() }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Note Row

struct NoteRow: View {
    let note: NoteDocument
    let isSelected: Bool
    let theme: MarkdownTheme

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(note.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(theme.sidebarTextPrimary))
                    .lineLimit(1)

                Text(note.lastModified, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(theme.sidebarTextMuted))
            }

            if taskTotal > 0 {
                Spacer(minLength: 4)
                TaskProgressBadge(done: taskDone, total: taskTotal)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color(theme.sidebarItemActive) : Color.clear)
        )
    }

    private var taskCounts: [TaskState: Int] {
        TaskManager.shared.taskCounts(in: note.content)
    }

    private var taskTotal: Int {
        taskCounts.values.reduce(0, +)
    }

    private var taskDone: Int {
        taskCounts[.done, default: 0]
    }
}

// MARK: - Task Progress Badge

struct TaskProgressBadge: View {
    let done: Int
    let total: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: done == total ? "checkmark.circle.fill" : "circle.dotted.circle")
                .font(.caption2)
                .foregroundStyle(done == total ? Color.green : Color.orange)
            Text("\(done)/\(total)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
