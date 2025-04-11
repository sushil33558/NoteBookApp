//
//  NoteListHeaderView.swift
//  NotebookApp
//
//  Created by Sushil Chaudhary on 09/04/25.
//

import UIKit

class NoteListHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    static let reuseIdentifier = "NoteListHeaderView"
    
    func configure(with dateText: String) {
        self.titleLabel.text = dateText
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
}
