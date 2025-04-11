//
//  NoteListViewModel.swift
//  NotebookApp
//
//  Created by Sushil Chaudhary on 09/04/25.
//

import Foundation

class NoteListViewModel: ObservableObject {
    
    private var allNotes: [NoteModel] = []
    @Published var response: [String: [NoteModel]] = [:]
    @Published var filteredResponse: [String: [NoteModel]] = [:]

    func getAllNoteModels() {
        let notes = CoreDataHelper.shared.fetchAllNotes()
        let mappedNotes = notes.compactMap { note -> NoteModel? in
            guard let id = note.id,
                  let createdAt = note.createdAt,
                  let content = note.content,
                  let attributed = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: content)
            else { return nil }

            let fullText = attributed.string
            let lines = fullText.components(separatedBy: .newlines)
            let title = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let description = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

            return NoteModel(id: id, createdAt: createdAt, attributedText: attributed, title: title, description: description)
        }

        allNotes = mappedNotes
        groupNotesByDate(notes: mappedNotes)
    }

    private func groupNotesByDate(notes: [NoteModel]) {
        let formatter = DateFormatter(); formatter.dateStyle = .medium
        let grouped = Dictionary(grouping: notes) { formatter.string(from: $0.createdAt) }
        let sorted = grouped.sorted { $0.key > $1.key }.reduce(into: [String: [NoteModel]]()) { $0[$1.key] = $1.value }
        response = sorted; filteredResponse = sorted
    }

    func filterNotes(query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { groupNotesByDate(notes: allNotes); return }
        let lower = q.lowercased()
        let filtered = allNotes.filter { $0.title.lowercased().contains(lower) || $0.description.lowercased().contains(lower) }
        groupNotesByDate(notes: filtered)
    }

    func deleteNotes(id: UUID) {
        CoreDataHelper.shared.deleteNote(id: id)
        allNotes.removeAll { $0.id == id }
        groupNotesByDate(notes: allNotes)
    }
}
