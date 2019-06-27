//
//  Queue.swift
//  FF_API_IOS
//
//  Created by Josh Ruoff on 6/24/19.
//  Copyright © 2019 Freefly. All rights reserved.
//

import Foundation
struct Queue<T> {
    var items = [T]()
    
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    var count: Int {
        return items.count
    }
    
    mutating func enqueue(_ element: T) {
        items.append(element)
    }
    
    mutating func dequeue() -> T? {
        return items.isEmpty ? nil : items.removeFirst()
    }
    
    func peek() -> T? {
        return items.isEmpty ? nil : items[0]
    }
    
    mutating func clear() {
        items = []
    }
}
