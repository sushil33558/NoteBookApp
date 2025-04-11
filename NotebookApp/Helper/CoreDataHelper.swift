//
//  CoreDataHelper.swift
//  NotebookApp
//
//  Created by Sushil Chaudhary on 09/04/25.
//


import UIKit
import CoreData

class CoreDataHelper {
    
    static let shared = CoreDataHelper()
    private let context: NSManagedObjectContext
    
    
    
    private init() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to get AppDelegate")
        }
        context = appDelegate.persistentContainer.viewContext
    }
    
    
    
    
    func saveNote(attributedText: NSAttributedString) {
        let note = Note(context: context)
        note.id = UUID()
        note.createdAt = Date()
        
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: attributedText, requiringSecureCoding: false) {
            note.content = data
        }
        
        saveContext()
    }
    
    
    
    func updateNote(id: UUID, newAttributedText: NSAttributedString) {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let note = results.first {
                if let data = try? NSKeyedArchiver.archivedData(withRootObject: newAttributedText, requiringSecureCoding: false) {
                    note.content = data
                    note.createdAt = Date() // Optional
                    saveContext()
                }
            }
        } catch {
            print("Error updating note: \(error)")
        }
    }
    
    
    
    
    func fetchAllNotes() -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching notes: \(error)")
            return []
        }
    }
    
    
    
    
    func deleteNote(id: UUID) {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let noteToDelete = results.first {
                context.delete(noteToDelete)
                saveContext()
                print("Note deleted with ID: \(id)")
            } else {
                print("Note not found with ID: \(id)")
            }
        } catch {
            print("Error deleting note: \(error)")
        }
    }

    
    
    func loadNote(id: UUID) -> NSAttributedString? {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let note = results.first,
               let data = note.content,
               let attributed = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSAttributedString {
                return attributed
            }
        } catch {
            print("Error loading note: \(error)")
        }
        return nil
    }
    
    
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("Context saved.")
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}
