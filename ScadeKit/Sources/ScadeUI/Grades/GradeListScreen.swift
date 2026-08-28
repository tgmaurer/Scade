import ScadeKit
import SwiftUI

/// The grades list (SPEC §4).
///
/// Forks the way the educations and subjects lists do: a grid of tiles on
/// macOS, a `List` on iOS. A phone has room for one column either way, and a
/// list is what its swipe-to-delete and disclosure chevron belong to.
///
/// The §2.5 questions that decide grid-versus-list answer "list" here more
/// firmly than anywhere else in the app — grades run to hundreds and the
/// value *is* the record. The grid was chosen anyway; see that section for
/// the trade accepted and what it costs.
struct GradeListScreen: View {
    @Environment(\.repositories) private var repositories
    @State private var model = GradeListModel()
    @State private var formMode: GradeFormMode?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var model = model

        rows
        .navigationTitle("Grades")
        // How many are on screen, not how many exist: it follows the search
        // and the filters, because the number is only useful as an answer to
        // "what am I looking at". Nothing is claimed before the first
        // snapshot lands — see `hasLoaded`.
        //
        // "items", not the record's own name: the title above it already
        // says what they are, and macOS puts title and subtitle together in
        // the Window menu and the app switcher, where "Grades — 13 grades"
        // says "grades" twice.
        .navigationSubtitle(
            model.hasLoaded
                ? "^[\(model.visibleRows.count) item](inflect: true)"
                : ""
        )
        .searchable(text: $model.searchText, prompt: "Search grades")
        .searchFocused($isSearchFocused)
        // What the menu bar can do here (SPEC-POLISH §1.2). Published while
        // this screen is in front and gone when it isn't.
        .focusedSceneValue(\.newRecord, ScreenAction("New Grade", perform: startCreating))
        .focusedSceneValue(\.focusSearch, ScreenAction("Search") { isSearchFocused = true })
        .focusedSceneValue(\.clearFilters, clearFiltersAction)
        .overlay {
            // Not until the first snapshot has arrived: see
            // `hasLoaded`.
            if model.hasLoaded {
                GradeListEmptyState(
                    hasAnyGrades: model.rows.isEmpty == false,
                    hasVisibleRows: model.visibleRows.isEmpty == false,
                    hasActiveFilters: model.hasActiveFilters,
                    creationBlockedReason: model.creationBlockedReason,
                    onCreate: startCreating,
                    onClearFilters: model.clearFilters
                )
            }
        }
        .toolbar {
            ToolbarItem {
                Toggle(isOn: $model.showsFailingOnly) {
                    Label(
                        "Failing Only",
                        systemImage: model.showsFailingOnly
                            ? "exclamationmark.triangle.fill"
                            : "exclamationmark.triangle"
                    )
                }
                .toggleStyle(.button)
                // Says what the next click does, not what the toggle is
                // called: the label is already on screen, and a toggle's
                // ambiguity is always which way it is about to go.
                .help(
                    model.showsFailingOnly
                        ? "Show every grade again"
                        : "Show only grades below 4"
                )
            }

            ToolbarItem {
                Button("New Grade", systemImage: "plus", action: startCreating)
                    .accessibilityIdentifier(AccessibilityID.Grade.new)
                    .disabled(model.creationBlockedReason != nil)
                    .help(model.creationBlockedReason ?? "Add a grade")
            }
        }
        .sheet(item: $formMode) { mode in
            GradeFormScreen(mode: mode)
        }
        .confirmationDialog(
            "Delete Grade?",
            isPresented: $model.isShowingDeletionConfirmation,
            presenting: model.pendingDeletion
        ) { _ in
            Button("Delete", role: .destructive) {
                model.confirmDeletion(from: repositories)
            }
        } message: { item in
            GradeDeletionMessage(item: item)
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            await model.observe(repositories)
        }
    }

    /// macOS: a grid of tiles. iOS: a `List`, with the system's separator
    /// between rows taken away — a card and a rule are two answers to the
    /// same question (§2.5).
    @ViewBuilder
    private var rows: some View {
        #if os(macOS)
        CardGrid(items: model.visibleRows) { item in
            NavigationLink(value: item.grade) {
                GradeRowView(item: item)
                    // Inside the link, so the whole tile is the click target
                    // rather than the text within it.
                    .cardTile()
            }
            // Also what takes away the accent fill macOS drew across a
            // pressed list row — it spanned the full row while the card was
            // inset, so pressing lit two strips either side of the card. A
            // plain button in a grid has no such presentation to give up.
            .buttonStyle(.plain)
            .contextMenu {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    model.pendingDeletion = item
                }
            }
        }
        #else
        List {
            ForEach(model.visibleRows) { item in
                NavigationLink(value: item.grade) {
                    GradeRowView(item: item)
                        .padding(.vertical, ScadeDesign.rowVerticalPadding)
                }
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        model.pendingDeletion = item
                    }
                }
            }
        }
        #endif
    }

    private func startCreating() {
        formMode = .create()
    }

    /// `nil` where there is nothing to clear, which is what greys the menu
    /// item out rather than offering an action that would do nothing.
    private var clearFiltersAction: ScreenAction? {
        guard model.hasActiveFilters else { return nil }
        return ScreenAction("Clear Filters", perform: model.clearFilters)
    }
}

#Preview {
    NavigationStack {
        GradeListScreen()
    }
    .environment(\.repositories, PreviewData.seededRepositories)
}
