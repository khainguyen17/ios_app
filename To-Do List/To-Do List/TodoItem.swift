//
//  TodoItem.swift
//  To-Do List
//
//  Created by Khai Nguyen on 10/7/25.
//

import Foundation

struct TodoItem: Codable {
    var name: String
    var isDone: Bool
    // Thêm các properties mới:
    var subtasks: [TodoItem] = []

}
