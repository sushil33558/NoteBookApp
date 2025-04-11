//
//  ViewController.swift
//  NotebookApp
//
//  Created by Sushil Chaudhary on 09/04/25.
//

import UIKit
import Combine

class NoteListViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBarHeightConstraint: NSLayoutConstraint!
    
    //MARK: - GLOBAL VARIABLE'S
    
    private var timer: Timer?
    private var titleLabel: UILabel?
    private var viewModel = NoteListViewModel()
    var garbageBag = Set<AnyCancellable>()
    
    //MARK: - VIEW LIFE CYCLE'S
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observer()
        configNavigationView()
        configUI()
        addDoneButtonToSearchBarKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.getAllNoteModels()
    }
    
    
    //MARK: - PRIVATE METHODS
    
    private func observer() {
        self.viewModel.$filteredResponse
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.tableView.reloadData()
            }
            .store(in: &garbageBag)
        }

    
    
    private func configNavigationView() {
        navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.title = "Notes"
        navigationController?.isToolbarHidden = false
        
        let addImage = UIImage(systemName: "square.and.pencil")
        let addButton = UIBarButtonItem(image: addImage, style: .plain, target: self, action: #selector(addTapped))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let trailingSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        trailingSpace.width = 20
        
        toolbarItems = [space, addButton, trailingSpace]
        
        let label = UILabel()
        label.text = "Notes"
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.alpha = 0
        self.navigationItem.titleView = label
        self.titleLabel = label
        self.titleLabel?.isHidden = true
    }

    
    private func configUI() {
        let headerNib = UINib(nibName: NoteListHeaderView.reuseIdentifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: NoteListHeaderView.reuseIdentifier)
        let cellNib = UINib(nibName: NoteListTableViewCell.reuseIdentifier, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: NoteListTableViewCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }
    
    
    //MARK: - @OBJC FUNCTION'S
    
    @objc func addTapped(_ sender: UIButton) {
        navigateToNoteListPage(id: nil, type: .newNote)
    }
    
}



    //MARK: - SEARCH BAR DELEGATE
extension NoteListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            self.viewModel.filterNotes(query: searchText)
        }
    }
    
    private func addDoneButtonToSearchBarKeyboard() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        
        toolbar.items = [flexSpace, doneButton]

        // Access the UITextField inside the UISearchBar
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.inputAccessoryView = toolbar
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

}



    //MARK: - TABLE VIEW DELEGATE
extension NoteListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UIScreen.main.bounds.height * 0.06
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if offsetY > 0 {
            UIView.animate(withDuration: 0.3) {
                self.searchBarHeightConstraint.constant = 0
                self.searchBar.alpha = 0
                self.titleLabel?.alpha = 1
                self.titleLabel?.isHidden = false
                self.navigationController?.navigationBar.prefersLargeTitles = false
                self.view.layoutIfNeeded()
                print("Height:", self.searchBarHeightConstraint.constant)

            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.searchBarHeightConstraint.constant = 56
                self.searchBar.alpha = 1
                self.titleLabel?.alpha = 0
                self.titleLabel?.isHidden = true
                self.navigationController?.navigationBar.prefersLargeTitles = true
                self.view.layoutIfNeeded()
                print("Height:", self.searchBarHeightConstraint.constant)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            let sectionTitle = Array(self.viewModel.filteredResponse.keys.sorted(by: >))[indexPath.section]
            if let id = self.viewModel.filteredResponse[sectionTitle]?[indexPath.row].id {
                self.viewModel.deleteNotes(id: id)
            }
            completionHandler(true)
        }
        deleteAction.image = UIImage(named: "Delete")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionTitle = Array(viewModel.filteredResponse.keys.sorted(by: >))[indexPath.section]
        if let id = viewModel.filteredResponse[sectionTitle]?[indexPath.row].id {
            navigateToNoteListPage(id:id, type: .viewAndEdit)
        }
    }
}



    //MARK: - TABLE VIEW DATA SOURCE
extension NoteListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.filteredResponse.keys.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: NoteListHeaderView.reuseIdentifier) as! NoteListHeaderView
        let sectionTitle = Array(viewModel.filteredResponse.keys.sorted(by: >))[section]
        header.configure(with: sectionTitle)
        return header
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = Array(viewModel.filteredResponse.keys.sorted(by: >))[section]
        return viewModel.filteredResponse[sectionTitle]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NoteListTableViewCell.reuseIdentifier) as! NoteListTableViewCell
        let sectionTitle = Array(viewModel.filteredResponse.keys.sorted(by: >))[indexPath.section]
        if let model = viewModel.filteredResponse[sectionTitle]?[indexPath.row] {
            cell.model = model
        }
        return cell
    }
    
}



    //MARK: - NAVIGATION LINKED PAGE
extension NoteListViewController {
    private func navigateToNoteListPage(id: UUID?, type: NoteTextType) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "NoteTextViewController") as! NoteTextViewController
        vc.id = id
        vc.type = type
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
