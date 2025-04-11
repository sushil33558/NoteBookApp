//
//  NoteTextViewController.swift
//  NotebookApp
//
//  Created by Sushil Chaudhary on 09/04/25.
//

import UIKit
import Combine

enum NoteTextType {
    case viewAndEdit
    case newNote
}

final class NoteTextViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!

    private var addButton: UIButton!
    private var cancellables = Set<AnyCancellable>()

    var viewModel = NoteTextViewModel()
    var type: NoteTextType = .newNote
    var id: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        loadNoteIfNeeded()
    }
}

// MARK: - UI Setup

extension NoteTextViewController {
    private func setupUI() {
        configNavigationBar()
        setupKeyboardToolbar()
        setupAddButton()
        setupTapGesture()
        textView.delegate = self
        textView.becomeFirstResponder()
    }

    private func configNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .plain,
            target: self,
            action: #selector(doneTapped)
        )
    }

    private func bindViewModel() {
        viewModel.$response
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.textView.attributedText = text
            }
            .store(in: &cancellables)
    }

    private func loadNoteIfNeeded() {
        guard type == .viewAndEdit, let id = id else { return }
        viewModel.noteID = id
        viewModel.fetchNoteDataFromId()
    }
}

// MARK: - Add Button

extension NoteTextViewController {
    func setupAddButton() {
        addButton = UIButton(type: .custom)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = .systemBlue
        addButton.backgroundColor = .white
        addButton.layer.cornerRadius = 25
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOpacity = 0.2
        addButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addButton.layer.shadowRadius = 4
        addButton.isHidden = true
        addButton.addTarget(self, action: #selector(addToolbar), for: .touchUpInside)

        view.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16),
            addButton.widthAnchor.constraint(equalToConstant: 50),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}

// MARK: - Keyboard Toolbar

extension NoteTextViewController {
    func setupKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let checkboxButton = UIBarButtonItem(
            image: UIImage(systemName: "checklist.unchecked"),
            style: .plain,
            target: self,
            action: #selector(applyCheckboxToCurrentLine)
        )

        let formatButton = UIBarButtonItem(
            image: UIImage(systemName: "textformat.size"),
            style: .plain,
            target: self,
            action: #selector(showFormatMenu)
        )

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(removeToolbar)
        )

        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [checkboxButton, flex, formatButton, flex, closeButton]
        textView.inputAccessoryView = toolbar
    }

    @objc func removeToolbar() {
        textView.inputAccessoryView = nil
        textView.reloadInputViews()
        addButton.isHidden = false
    }

    @objc func addToolbar() {
        setupKeyboardToolbar()
        textView.reloadInputViews()
        addButton.isHidden = true
    }
}

// MARK: - Checkbox Functionality

extension NoteTextViewController {
    func checkboxAttachment(symbol: String) -> NSAttributedString {
        guard let image = UIImage(systemName: symbol)?
            .withTintColor(.label, renderingMode: .alwaysOriginal) else {
            return NSAttributedString(string: "")
        }

        let attachment = NSTextAttachment()
        attachment.image = image

        let font = textView.font ?? UIFont.systemFont(ofSize: 16)
        attachment.bounds = CGRect(x: 0, y: (font.capHeight - font.lineHeight) / 2, width: 20, height: 20)

        return NSAttributedString(attachment: attachment)
    }

    @objc func applyCheckboxToCurrentLine() {
        let range = textView.selectedRange
        let fullText = textView.attributedText.mutableCopy() as! NSMutableAttributedString

        let nsText = fullText.string as NSString
        let lineRange = nsText.lineRange(for: range)
        let lineText = nsText.substring(with: lineRange)

        if lineText.contains("circle") || lineText.contains("checkmark.circle.fill") {
            return
        }

        let checkbox = checkboxAttachment(symbol: "circle")
        let lineContent = NSMutableAttributedString()
        lineContent.append(checkbox)
        lineContent.append(NSAttributedString(string: " " + lineText.trimmingCharacters(in: .newlines)))

        fullText.replaceCharacters(in: lineRange, with: lineContent)
        textView.attributedText = fullText
//        textView.selectedRange = NSRange(location: lineRange.location + 2, length: 0)
        
        let endLocation = textView.selectedRange.location + textView.selectedRange.length
        textView.selectedRange = NSRange(location: endLocation, length: 0)
    }

    func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        textView.addGestureRecognizer(tap)
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: textView)
        guard let pos = textView.closestPosition(to: location),
              let range = textView.tokenizer.rangeEnclosingPosition(pos, with: .paragraph, inDirection: .layout(.left)),
              let _ = textView.text(in: range) else { return }

        let startOffset = textView.offset(from: textView.beginningOfDocument, to: range.start)
        let endOffset = textView.offset(from: textView.beginningOfDocument, to: range.end)
        let lineRange = NSRange(location: startOffset, length: endOffset - startOffset)

        let attrText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        var foundAttachmentRange: NSRange?

        attrText.enumerateAttribute(.attachment, in: lineRange, options: []) { value, range, stop in
            if value is NSTextAttachment {
                foundAttachmentRange = range
                stop.pointee = true
            }
        }

        if let attachRange = foundAttachmentRange {
            let currentAttachment = attrText.attributedSubstring(from: attachRange)
            let symbol = currentAttachment.string.contains("checkmark") ? "circle" : "checkmark.circle.fill"
            let newCheckbox = checkboxAttachment(symbol: symbol)

            attrText.replaceCharacters(in: attachRange, with: newCheckbox)
            textView.attributedText = attrText
            textView.selectedRange = NSRange(location: attachRange.location + 2, length: 0)

            textView.typingAttributes = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
        }
    }

}

// MARK: - Done & Title Formatting

extension NoteTextViewController {
    @objc func doneTapped() {
        applyTitleFormatting()
        guard let text = textView.attributedText, text.length > 0 else { return }
        viewModel.saveNote(text)
        navigationController?.popViewController(animated: true)
    }

    func applyTitleFormatting() {
        guard let attributedText = textView.attributedText else { return }

        let mutable = NSMutableAttributedString(attributedString: attributedText)
        let fullText = attributedText.string as NSString
        let titleEnd = fullText.range(of: "\n").location
        let titleRange = titleEnd != NSNotFound ?
            NSRange(location: 0, length: titleEnd) :
            NSRange(location: 0, length: fullText.length)

        let titleText = fullText.substring(with: titleRange).trimmingCharacters(in: .whitespacesAndNewlines)
        mutable.setAttributes([:], range: titleRange)

        if !titleText.isEmpty {
            mutable.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 24), range: titleRange)
        } else {
            mutable.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: titleRange)
        }

        let cursor = textView.selectedRange
        textView.attributedText = mutable
        textView.selectedRange = cursor
    }
}

    // MARK: - TextView Delegate

extension NoteTextViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        applyTitleFormatting()
        guard let text = textView.text else { return }
            let cursorPosition = textView.selectedRange.location
            let nsText = text as NSString

            if cursorPosition >= 2 {
                let prevChar = nsText.substring(with: NSRange(location: cursorPosition - 2, length: 2))
                if prevChar == "\n\n" || prevChar.hasSuffix("\n") {
                    // Set typingAttributes back to normal
                    textView.typingAttributes = [
                        .font: UIFont.systemFont(ofSize: 16),
                        .foregroundColor: UIColor.label
                    ]
                }
            }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let nsText = textView.attributedText.string as NSString
            let currentLineRange = nsText.lineRange(for: range)
            let currentLine = nsText.substring(with: currentLineRange)

            if currentLine.contains("checkmark.circle.fill") || currentLine.contains("circle") {
                let newLine = NSMutableAttributedString(string: "\n")
                newLine.append(checkboxAttachment(symbol: "circle"))
                newLine.append(NSAttributedString(string: " "))

                let fullText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
                fullText.insert(newLine, at: range.location)

                textView.attributedText = fullText
                textView.selectedRange = NSRange(location: range.location + newLine.length, length: 0)
                return false
            }
        }

        return true
    }
}

    // MARK: - Format Menu

extension NoteTextViewController {
    @objc func showFormatMenu() {
        textView.becomeFirstResponder()

        UIMenuController.shared.menuItems = [
            UIMenuItem(title: "Bold", action: #selector(makeBold)),
            UIMenuItem(title: "Italic", action: #selector(makeItalic)),
            UIMenuItem(title: "Underline", action: #selector(makeUnderline))
        ]

        if let range = textView.selectedTextRange {
            let rect = textView.firstRect(for: range)
            UIMenuController.shared.showMenu(from: textView, rect: rect)
        }
    }

    @objc func makeBold() {
        applyFontTrait(.traitBold)
        let endLocation = textView.selectedRange.location + textView.selectedRange.length
        textView.selectedRange = NSRange(location: endLocation, length: 0)
        UIMenuController.shared.hideMenu(from: textView)
    }

    @objc func makeItalic() {
        applyFontTrait(.traitItalic)
        let endLocation = textView.selectedRange.location + textView.selectedRange.length
        textView.selectedRange = NSRange(location: endLocation, length: 0)
        UIMenuController.shared.hideMenu(from: textView)
    }

    @objc func makeUnderline() {
        let range = textView.selectedRange
        let attributed = NSMutableAttributedString(attributedString: textView.attributedText)
        attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        textView.attributedText = attributed
        textView.selectedRange = range
        let endLocation = textView.selectedRange.location + textView.selectedRange.length
        textView.selectedRange = NSRange(location: endLocation, length: 0)
        UIMenuController.shared.hideMenu(from: textView)
    }

    func applyFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        let range = textView.selectedRange
        let attributed = NSMutableAttributedString(attributedString: textView.attributedText)
        let currentFont = (textView.typingAttributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 16)

        if let newDescriptor = currentFont.fontDescriptor.withSymbolicTraits(trait) {
            let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
            attributed.addAttribute(.font, value: newFont, range: range)
        }

        textView.attributedText = attributed
        textView.selectedRange = range
    }
}
