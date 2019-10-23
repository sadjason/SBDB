//
//  DatabaseQueue.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/21.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

// 支持并发读，串行写，读写之前互不干扰
//public class DatabaseQueue {
//    let db: Database?
//    public let queue: DispatchQueue
//
//    private let queueLabel = "com.bytedance.sqlite.db"
//
//    public init(path: String) {
//        db = try? Database(path: path)
//        queue = DispatchQueue(label: queueLabel, qos: .utility, attributes: .initiallyInactive)
//    }
//
//    func write() {
//
//    }
//
//    func read() {
//
//    }
//}

protocol ReadTransaction {
    // func fetch
    func query(model: Int)
}

protocol WriteTransaction: ReadTransaction {
    func create(table tableName: String)
//    func
//    func alter(table tableName: String)

    func update(table tableName: String)
}

extension Database {
    func read() {}
    func write() {}
    func asyncRead() {}
    func asyncWrite() {}
}

func test() {
    // JSONEncoder
    // let encoder = JSONEncoder()
    // 将 encoder 对象转为 Data
}
