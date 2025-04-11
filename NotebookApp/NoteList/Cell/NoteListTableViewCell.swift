//
//  NoteListTableViewCell.swift
//  NotebookApp
//
//  Created by Sushil Chaudhary on 09/04/25.
//

import UIKit

class NoteListTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    //MARK: - GLOBAL VARIABLE'S
    static let reuseIdentifier = "NoteListTableViewCell"
    
    var model: NoteModel? {
        didSet {
            guard let model = model else { return }
            let dateString = formatDate(model.createdAt)
            descriptionLabel.text = dateString + "  " + model.description
            titleLabel.text = model.title
        }
    }

    //MARK: - CELL CYCLE'S
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
