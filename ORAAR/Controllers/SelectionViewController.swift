//
//  SelectionViewController.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 24/02/2020.
//  Copyright © 2020 Anušjak, Milan. All rights reserved.
//

import UIKit

protocol SelectionViewControllerDelegate: NSObject {
    func didSelectItem(with imageName: String)
}

class SelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    weak var delegate: SelectionViewControllerDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    
    var imageNames: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "selectionCell", for: indexPath) as! SelectionCell
        cell.objectName = imageNames[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedImageName = imageNames[indexPath.row]
        delegate?.didSelectItem(with: selectedImageName)
        self.dismiss(animated: true, completion: nil)
    }
}
