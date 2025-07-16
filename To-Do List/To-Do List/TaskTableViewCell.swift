//
//  TaskTableViewCell.swift
//  To-Do List
//
//  Created by Khai Nguyen on 10/7/25.
//

import UIKit

class TaskTableViewCell: UITableViewCell {

    @IBOutlet weak var taskLabel: UILabel!
    @IBOutlet weak var checkboxButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var aiButton: UIButton!
    
    var checkboxButtonAction: (() -> Void)?
    var deleteButtonAction: (() -> Void)?
    var editButtonAction: (() -> Void)?
    var expandButtonAction: (() -> Void)?
    var aiButtonAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Cho phép label tự động xuống dòng và giãn số dòng
        taskLabel.numberOfLines = 0
        taskLabel.lineBreakMode = .byWordWrapping
    }

    @IBAction func checkboxTapped(_ sender: UIButton) {
        checkboxButtonAction?()
    }
    @IBAction func deleteTapped(_ sender: UIButton) {
        deleteButtonAction?()
    }
    @IBAction func editButtonTapped(_ sender: UIButton) {
        editButtonAction?()
    }
    @IBAction func expandButtonTapped(_ sender: UIButton) {
        expandButtonAction?()
    }
    @IBAction func aiButtonTapped(_ sender: UIButton) {
        aiButtonAction?()
    }
}
