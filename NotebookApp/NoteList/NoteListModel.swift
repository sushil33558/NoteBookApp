//
//  NoteListModel.swift
//  NotebookApp
//
//  Created by Sushil Chaudhary on 09/04/25.
//

import Foundation
import UIKit

struct NoteModel: Identifiable {
    let id: UUID
    let createdAt: Date
    let attributedText: NSAttributedString
    let title: String
    let description: String
}
