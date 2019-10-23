//
//  Transaction.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/20.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

/// https://www.sqlite.org/lang_transaction.html
struct Transaction {
    enum Mode: String, Expression {
        case defered
        case immediate
        case exclusive
    }

    func begin(with mode: Mode = .exclusive) throws {

    }

    func commit() throws {

    }

    func rollback() throws {
        
    }
}
