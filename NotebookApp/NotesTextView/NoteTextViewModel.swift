//
//  NoteTextViewModel.swift
//  NotebookApp
//
//  Created by Sushil Chaudhary on 09/04/25.
//

import Foundation
import UIKit

class NoteTextViewModel: ObservableObject {
    
    //MARK: - VARIABLE'S
    var noteID: UUID?
    @Published var response: NSAttributedString?
    
    
    //MARK: - SAVE & UPDATE NOTES USING CORE DATA
    func saveNote(_ attributedText: NSAttributedString) {
        if let id = noteID {
            CoreDataHelper.shared.updateNote(id: id, newAttributedText: attributedText)
            print("Note updated in ViewModel.")
        } else {
            CoreDataHelper.shared.saveNote(attributedText: attributedText)
            print("New note saved in ViewModel.")
        }
    }
    
    
    
    //MARK: - FETCH NOTES USING ID
    func fetchNoteDataFromId() {
        if let id = noteID {
            self.response = CoreDataHelper.shared.loadNote(id: id)
        }
    }
    
    
    //MARK: - CHECK THE ID FROM CORE DATA IF EXIST
    func loadNote() -> NSAttributedString? {
        guard let id = noteID else { return nil }
        return CoreDataHelper.shared.loadNote(id: id)
    }
}
