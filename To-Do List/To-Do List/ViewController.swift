//
//  ViewController.swift
//  To-Do List
//
//  Created by Khai Nguyen on 10/7/25.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var taskTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var subButton: UIButton!
    @IBOutlet weak var modeLabel: UILabel!
    
    
    var isEditMode = false
    var tasks: [TodoItem] = []
    
    var isAIMode = false
    var selectedTaskPath: [Int]? = nil // Sử dụng path thay cho selectedTaskIndex
    
    var expandedTasks: Set<String> = [] // Lưu key dạng "0-2-1" cho các node đang mở
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName:"TaskTableViewCell", bundle: nil), forCellReuseIdentifier: "TaskTableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        loadTasks()
        buildDisplayItems()
        modeLabel.isHidden = true
    }
    

    //Button thêm
    @IBAction func addTask(_ sender: UIButton) {
        guard let text = taskTextField.text, !text.isEmpty else { return }
        if isAIMode {
            guard let path = selectedTaskPath else {
                // Hiện alert nếu chưa chọn task/subtask
                let alert = UIAlertController(title: "Thông báo", message: "Hãy chọn một công việc để thêm subtask!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            let newSubtask = TodoItem(name: text, isDone: false)
            addSubtask(to: &tasks, path: path, newSubtask: newSubtask)
            updateAllParentDoneState(tasks: &tasks)
            taskTextField.text = ""
            saveTasks()
            buildDisplayItems()
            tableView.reloadData()
        } else {
            let newTask = TodoItem(name: text, isDone: false)
            tasks.insert(newTask, at: 0)
            taskTextField.text = ""
            saveTasks()
            buildDisplayItems()
            tableView.reloadData()
        }
       
    }
    
    //Button sắp xếp
    @IBAction func sortButtonTapped(_ sender: UIButton) {
        isEditMode.toggle()
        
        if isEditMode {
            // Vào chế độ sắp xếp
            sortButton.setTitle("", for: .normal)
            sortButton.backgroundColor = .systemGreen
            tableView.setEditing(true, animated: true)
        } else {
            // Thoát chế độ sắp xếp
            sortButton.setTitle("", for: .normal)
            sortButton.backgroundColor = .clear
            tableView.setEditing(false, animated: true)
            saveTasks() // Lưu thứ tự mới
            buildDisplayItems()
            tableView.reloadData()
        }
        updateModeLabel()
    }
    
    //Button add sub
    @IBAction func subButtonTapped(_ sender: UIButton) {
        isAIMode.toggle()
        selectedTaskPath = nil
        subButton.backgroundColor = isAIMode ? .systemBlue : .clear // Đổi màu 
        tableView.reloadData()
        updateModeLabel()
    }
    
    
    
    
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = displayItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskTableViewCell", for: indexPath) as! TaskTableViewCell
        let task = item.task
        
        if item.level > 0 {
            let symbol = "└ "
            let chevronColor = UIColor.systemBlue
            let symbolAttr = NSAttributedString(string: symbol, attributes: [.foregroundColor: chevronColor])
            let nameAttr: NSAttributedString
            if task.isDone {
                nameAttr = NSAttributedString(
                    string: task.name,
                    attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue,
                                 .foregroundColor: UIColor.lightGray])
            } else {
                nameAttr = NSAttributedString(string: task.name)
            }
            let combined = NSMutableAttributedString()
            combined.append(symbolAttr)
            combined.append(nameAttr)
            cell.taskLabel.attributedText = combined
        } else {
            let attributedText: NSAttributedString
            if task.isDone {
                attributedText = NSAttributedString(
                    string: task.name,
                    attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue,
                                 .foregroundColor: UIColor.lightGray])
            } else {
                attributedText = NSAttributedString(string: task.name)
            }
            cell.taskLabel.attributedText = attributedText
        }
        // Lùi vào theo cấp độ lồng
        cell.taskLabel.transform = CGAffineTransform(translationX: CGFloat(item.level) * 10, y: 0)

        //Button checkbox
        cell.checkboxButton.setTitle(task.isDone ? "✅" : "⬜️", for: .normal)

        cell.checkboxButtonAction = { [weak self] in
            guard let self = self else { return }
            self.toggleDone(at: item.path)
            self.saveTasks()
            self.buildDisplayItems()
            self.tableView.reloadData() // <-- reload toàn bộ tableView
        }

        //Button xoá
        cell.deleteButtonAction = { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Confirm", message: "Are you sure you want to delete this task?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self.deleteTask(at: item.path)
                self.saveTasks()
                self.buildDisplayItems()
                self.tableView.reloadData()
            })
            self.present(alert, animated: true)
        }
        
        //Button sửa
        cell.editButtonAction = { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Sửa công việc", message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = item.task.name
            }
            alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
            alert.addAction(UIAlertAction(title: "Lưu", style: .default) { _ in
                if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                    self.renameTask(at: item.path, newName: newName)
                    self.saveTasks()
                    self.buildDisplayItems()
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            })
            self.present(alert, animated: true)
        }
        
        // Nút expand/collapse
        let key = item.path.map { String($0) }.joined(separator: "-")
        if !task.subtasks.isEmpty {
            cell.expandButton.isHidden = false
            // Bỏ setTitle, chỉ để nút expand/collapse không có chữ
            cell.expandButton.setTitle("", for: .normal)
            cell.expandButtonAction = { [weak self] in
                guard let self = self else { return }
                if self.expandedTasks.contains(key) {
                    self.expandedTasks.remove(key)
                } else {
                    self.expandedTasks.insert(key)
                }
                self.buildDisplayItems()
                self.tableView.reloadData()
            }
        } else {
            cell.expandButton.isHidden = true
        }
        
        // Ẩn các nút khi ở chế độ sắp xếp
        cell.checkboxButton.isHidden = isEditMode
        cell.editButton.isHidden = isEditMode
        cell.deleteButton.isHidden = isEditMode
        
        cell.aiButtonAction = { [weak self] in
            guard let self = self else { return }
            let taskPath = item.path
            let taskName = item.task.name
            AIBreakdownService.shared.breakdownTask(taskName: taskName) { subtasks in
                guard let subtasks = subtasks else { return }
                DispatchQueue.main.async {
                    for subtaskName in subtasks {
                        let subtask = TodoItem(name: subtaskName, isDone: false)
                        self.addSubtask(to: &self.tasks, path: taskPath, newSubtask: subtask)
                    }
                    self.saveTasks()
                    self.buildDisplayItems()
                    self.tableView.reloadData()
                }
            }
        }
        
        return cell
    }
    
    
    
    
    // MARK: - Swipe Actions
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let doneAction = UIContextualAction(style: .normal, title: "Done") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let item = self.displayItems[indexPath.row]
            self.setDone(at: item.path)
            self.saveTasks()
            self.buildDisplayItems()
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        doneAction.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [doneAction])
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let item = self.displayItems[indexPath.row]
            self.deleteTask(at: item.path)
            self.saveTasks()
            self.buildDisplayItems()
            self.tableView.reloadData()
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isAIMode {
            selectedTaskPath = displayItems[indexPath.row].path
        }
    }
    
    //Chế độ Sắp xếp
    // Cho phép di chuyển cell
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return isEditMode
    }
    // Xử lý việc di chuyển cell
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedTask = tasks.remove(at: sourceIndexPath.row)
        tasks.insert(movedTask, at: destinationIndexPath.row)
    }
    // Ẩn nút xóa khi ở chế độ sắp xếp
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return isEditMode ? .none : .delete
    }
    // Ẩn nút "Delete" khi ở chế độ sắp xếp
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return !isEditMode
    }
    
    struct DisplayItem {
        var task: TodoItem
        var path: [Int] // Đường dẫn đến task/subtask này trong cây
        var level: Int  // Cấp độ lồng (để lùi vào)
    }
    var displayItems: [DisplayItem] = []

    func buildDisplayItems() {
        displayItems = []
        func addItems(tasks: [TodoItem], path: [Int], level: Int) {
            for (i, task) in tasks.enumerated() {
                let currentPath = path + [i]
                displayItems.append(DisplayItem(task: task, path: currentPath, level: level))
                let key = currentPath.map { String($0) }.joined(separator: "-")
                if expandedTasks.contains(key) {
                    addItems(tasks: task.subtasks, path: currentPath, level: level + 1)
                }
            }
        }
        addItems(tasks: self.tasks, path: [], level: 0)
    }
    
    // Đệ quy thêm subtask vào đúng node
    func addSubtask(to tasks: inout [TodoItem], path: [Int], newSubtask: TodoItem) {
        guard let first = path.first else { return }
        if path.count == 1 {
            tasks[first].subtasks.append(newSubtask)
        } else {
            addSubtask(to: &tasks[first].subtasks, path: Array(path.dropFirst()), newSubtask: newSubtask)
        }
    }
    // Đệ quy toggle done
    func toggleDone(at path: [Int]) {
        updateTask(at: &tasks, path: path) { $0.isDone.toggle() }
        updateParentDoneState(for: path)
    }
    // Đệ quy set done
    func setDone(at path: [Int]) {
        updateTask(at: &tasks, path: path) { $0.isDone = true }
        updateParentDoneState(for: path)
    }
    // Đệ quy update trạng thái hoàn thành của task cha
    func updateParentDoneState(for path: [Int]) {
        guard path.count > 1 else { return } // Nếu là task gốc thì không cần
        let parentPath = Array(path.dropLast())
        updateTask(at: &tasks, path: parentPath) { parent in
            if parent.subtasks.allSatisfy({ $0.isDone }) && !parent.subtasks.isEmpty {
                parent.isDone = true
            } else {
                parent.isDone = false
            }
        }
        // Đệ quy lên các cấp cha tiếp theo
        updateParentDoneState(for: parentPath)
    }
    // Đệ quy rename
    func renameTask(at path: [Int], newName: String) {
        updateTask(at: &tasks, path: path) { $0.name = newName }
    }
    // Đệ quy xoá task/subtask
    func deleteTask(at path: [Int]) {
        guard let first = path.first else { return }
        if path.count == 1 {
            tasks.remove(at: first)
        } else {
            deleteTaskHelper(&tasks[first].subtasks, path: Array(path.dropFirst()))
        }
    }
    func deleteTaskHelper(_ tasks: inout [TodoItem], path: [Int]) {
        guard let first = path.first else { return }
        if path.count == 1 {
            tasks.remove(at: first)
        } else {
            deleteTaskHelper(&tasks[first].subtasks, path: Array(path.dropFirst()))
        }
    }
    // Đệ quy update task
    func updateTask(at tasks: inout [TodoItem], path: [Int], update: (inout TodoItem) -> Void) {
        guard let first = path.first else { return }
        if path.count == 1 {
            update(&tasks[first])
        } else {
            updateTask(at: &tasks[first].subtasks, path: Array(path.dropFirst()), update: update)
        }
    }
    
    
    
    // MARK: - UserDefaults
    func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "tasks")
        }
    }

    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks") {
            if let loadedTasks = try? JSONDecoder().decode([TodoItem].self, from: data) {
                tasks = loadedTasks
                updateAllParentDoneState(tasks: &tasks) // Thêm dòng này
            }
        }
    }

    func updateModeLabel() {
        if isEditMode {
            modeLabel.text = "Sort Mode"
            modeLabel.isHidden = false
        } else if isAIMode {
            modeLabel.text = "Add Subtask Mode"
            modeLabel.isHidden = false
        } else {
            modeLabel.isHidden = true
        }
    }
}

// Đệ quy cập nhật trạng thái hoàn thành cho toàn bộ cây
func updateAllParentDoneState(tasks: inout [TodoItem]) {
    for i in 0..<tasks.count {
        // Cập nhật cho subtasks trước
        updateAllParentDoneState(tasks: &tasks[i].subtasks)
        // Cập nhật trạng thái cho task cha
        if !tasks[i].subtasks.isEmpty {
            if tasks[i].subtasks.allSatisfy({ $0.isDone }) {
                tasks[i].isDone = true
            } else {
                tasks[i].isDone = false
            }
        }
    }
}
