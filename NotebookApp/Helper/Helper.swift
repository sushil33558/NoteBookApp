//
//  Helper.swift
//  NotebookApp
//
//  Created by Sushil Chaudhary on 09/04/25.
//

import UIKit

extension NSRange {
    func toTextRange(textInput: UITextInput) -> UITextRange? {
        guard let start = textInput.position(from: textInput.beginningOfDocument, offset: location),
              let end = textInput.position(from: start, offset: length) else { return nil }
        return textInput.textRange(from: start, to: end)
    }
}

extension UITextRange {
    func toNSRange(in textView: UITextView) -> NSRange? {
        let location = textView.offset(from: textView.beginningOfDocument, to: self.start)
        let length = textView.offset(from: self.start, to: self.end)
        return NSRange(location: location, length: length)
    }
}


extension UITableViewCell {
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}
