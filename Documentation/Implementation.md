# WarmMarkdown - Implementation Plan

## Overview
Bear-style macOS markdown editor built as an Xcode project targeting macOS 14+, using `@Observable` macro, SwiftUI + AppKit (NSTextView bridge), and Apple's swift-markdown package with custom task state extensions.

## Architecture

### App Lifecycle
- **SwiftUI App** with `@Observable` `AppState` as the central state container
- `NavigationSplitView` for sidebar + editor layout
- NSTextView bridged via `NSViewRepresentable` for rich text editing

### File Structure
```
WarmMarkdown/
├── WarmMarkdown.xcodeproj
├── WarmMarkdown/
│   ├── WarmMarkdownApp.swift          - App entry, window config, menu commands
│   ├── ContentView.swift              - Split view: sidebar + editor + quick switcher
│   ├── WarmMarkdown.entitlements      - App Sandbox with file access
│   ├── Editor/
│   │   ├── MarkdownEditorView.swift   - SwiftUI view hosting the editor
│   │   ├── TextViewWrapper.swift      - NSViewRepresentable wrapping NSTextView
│   │   ├── MarkdownFormatter.swift    - Bear-style NSAttributedString formatting
│   │   └── MarkdownParser.swift       - Regex-based markdown tokenizer
│   ├── Themes/
│   │   ├── VSCodeTheme.swift          - Codable structs for VSCode JSON schema
│   │   ├── MarkdownTheme.swift        - Simplified theme model (13 color properties)
│   │   ├── ThemeMapper.swift          - VSCode token scopes → MarkdownTheme mapping
│   │   └── ThemeManager.swift         - @Observable: load, import, switch, persist themes
│   ├── Tasks/
│   │   ├── TaskState.swift            - 4-state enum: todo, done, inProgress, blocked
│   │   ├── TaskCheckboxAttachment.swift - NSTextAttachment custom checkbox rendering
│   │   └── TaskManager.swift          - Task detection, toggle, state cycling
│   ├── Files/
│   │   ├── FileManagerService.swift   - Load/save .md files, directory watching
│   │   ├── NoteDocument.swift         - Note model with tag extraction
│   │   ├── SidebarView.swift          - File list with search, tags, context menu
│   │   ├── QuickSwitcher.swift        - Cmd+P modal with fuzzy search
│   │   ├── SearchService.swift        - Fuzzy search scoring
│   │   └── WikiLinkParser.swift       - [[wiki-link]] detection and resolution
│   └── Resources/
│       └── Themes/
│           ├── warm-oatmeal.json
│           ├── dracula.json
│           ├── nord.json
│           ├── gruvbox-warm.json
│           └── one-dark.json
└── Documentation/
    └── Implementation.md
```

## Phase 1: Core Editor

### NSTextView Bridge
- `NSTextView` via `NSViewRepresentable` for rich text editing (SwiftUI's TextEditor lacks the control needed)
- `NSTextStorage` used for real-time formatting
- Raw markdown stored as `String`, `NSAttributedString` used for display
- Autosave with 500ms debounce

### File Operations
- Default directory: `~/Documents/Notes` (created if missing)
- User can change via folder picker (persisted in UserDefaults)
- Directory monitoring with `DispatchSource` for external file changes

## Phase 2: VSCode Theme System

### Theme Mapping Strategy
| VSCode Token | Editor Element |
|---|---|
| `editor.background` | Note background |
| `editor.foreground` | Body text |
| `keyword` | H1-H6 headings |
| `string` | Links |
| `comment` | Code block background |
| `editor.lineHighlightBackground` | Code block background (fallback) |
| `editor.selectionBackground` | Selection highlight |

### Theme Management
- 5 bundled themes: Warm Oatmeal, Dracula, Nord, Gruvbox Warm, One Dark
- Import custom VSCode `.json` themes via menu
- Imported themes stored in `~/Library/Application Support/WarmMarkdown/Themes/`
- Theme selection persisted in UserDefaults
- Live preview on switch (theme change triggers re-format)

## Phase 3: Task Management

### Four Task States
| State | Marker | Symbol |
|---|---|---|
| Todo | `[ ]` | Empty circle |
| In Progress | `[/]` | Dotted circle with dot |
| Done | `[x]` | Green filled checkmark |
| Blocked | `[-]` | Circle with X |

### Behavior
- swift-markdown handles standard `- [ ]` and `- [x]`
- Custom regex layer for `- [/]` (in progress) and `- [-]` (blocked)
- `NSTextAttachment` with custom drawing for each state's checkbox icon
- State cycle: todo → in-progress → done → blocked → todo
- **Cmd+Shift+T** toggles state of task on current line

## Phase 4: Sidebar & Navigation

### Sidebar
- `List` with file hierarchy
- Search bar with fuzzy matching
- Tag extraction from `#tag` patterns
- Context menu for delete

### Quick Switcher (Cmd+P)
- Modal overlay with text field + filtered results
- Keyboard navigation (up/down arrows, enter to select, escape to close)
- Fuzzy search across note titles, content, and tags

### Wiki-Links
- Regex detection of `[[note-name]]` patterns
- Rendered as clickable links with faded bracket markers
- Resolution by title match, filename match, or fuzzy match

## Phase 5: Bear-Style Formatting

### Approach
- **Headers**: Faded `#` markers (30% alpha), large bold styled font (28pt → 15pt for H1-H6)
- **Bold/Italic**: Applied font traits, dimmed `**`/`*` markers (25% alpha)
- **Code blocks**: Monospace font with background color, indented paragraph style
- **Inline code**: Monospace font with subtle background
- **Links**: Colored and underlined text, faded URL portion and bracket markers
- **Blockquotes**: Italic text with indentation and colored `>` marker
- **Lists**: Colored bullet/number markers with semibold weight
- **Strikethrough**: Strikethrough style with reduced opacity

## Keyboard Shortcuts
| Shortcut | Action |
|---|---|
| Cmd+N | New Note |
| Cmd+Shift+O | Open Folder |
| Cmd+P | Quick Switcher |
| Cmd+\ | Toggle Sidebar |
| Cmd+Shift+T | Toggle Task State |

## Keyboard Shortcuts — Additional
| Shortcut | Action |
|---|---|
| Cmd+Shift+W | Toggle word count |

## Phase 6: WYSIWYG Improvements

All five core phases are complete. The following improvements bring the editor closer to Bear's WYSIWYG feel.

### 6a. Inline Image Rendering (WYSIWYG)
- **Parser**: Add `![alt](url)` regex in `MarkdownParser` (the `image` token case exists but no regex is defined yet)
- **Formatter**: Style `![` and `](url)` markers as faded (25% alpha), display a `photo` SF Symbol attachment before the alt text
- **Local images**: For `file://` URLs, load `NSImage` and insert an `NSTextAttachment` on the **next line** as a read-only decoration paragraph, keeping raw markdown intact
- **Remote images**: Show a `photo.badge.arrow.down` placeholder attachment (async load)
- **Architecture note**: True inline insertion requires either a custom `NSTextStorage` subclass or TextKit 2 migration. Phase 6a uses the "decoration paragraph" approach (image appended below the markdown line) to avoid corrupting the stored string

### 6b. Task Checkbox Attachments
- `TaskCheckboxAttachment.swift` is complete but **never wired into the formatter**
- Formatter should replace the `[ ]`/`[x]`/`[/]`/`[-]` bracket region with an `NSTextAttachment` using the custom-drawn checkbox
- Replacement must happen right-to-left (to preserve offsets) and the raw markdown string must be reconstructed before save by stripping `NSAttachmentCharacter` (U+FFFC) back to bracket notation
- **Simpler alternative** (implemented in Phase 6b): keep the raw text but overlay a custom `NSTextField`-free drawing by subclassing `NSTextView` and overriding `draw(_:)` to paint checkbox icons at task-marker rects

### 6c. Word Count in Toolbar
- Add word/character count to the toolbar or status bar below the editor
- Update count on each text change (debounced 300ms)
- Show: `N words · M chars`

### 6d. Tag-Click Note Filtering
- Clicking a tag in the sidebar's "Tags" section filters the notes list to only notes containing that tag
- Active tag shown with an accent badge; clicking again deselects
- Combine with free-text search (AND logic)

### 6e. Note Statistics in Sidebar
- `NoteRow` gains a task-progress indicator when note contains tasks: e.g. `✓ 3/5` using colored dots matching the four task-state colors
- On hover/expansion, show word count

### 6f. Export
- **Cmd+Shift+E** opens export sheet: Markdown (copy as-is), HTML (via simple template), PDF (via `NSPrintOperation`)
- HTML export wraps content in a minimal stylesheet matching the current theme colors

### 6g. Drag & Drop Images
- Accept image drag onto editor pane
- Copy image to `<notes-dir>/assets/<note-slug>/` and insert `![filename](assets/...)` markdown
- Entitlements already allow user-selected file access

### 6h. Scroll Position Memory
- Persist the vertical scroll offset per note (keyed by note ID in UserDefaults)
- Restore when switching notes

## Dependencies
- **swift-markdown** (Apple) v0.4.0+ - Markdown parsing via SPM
- macOS 14.0+ deployment target
- App Sandbox with user-selected file read/write access
