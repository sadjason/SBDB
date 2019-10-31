//
//  Connection.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/18.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

// TODO: 错误信息设计还比较简陋，待完善

enum SQLiteError : Error {

    public typealias Code = Int32
    public typealias Description = String

    case misuse(Description)

    enum StatementError: Error {
        case prepareFailed(Description, Code)
        case stepFailed(Description, Code)
        case resetFailed(Description, Code)
        case bindFailed(Description, Code)
    }

    enum ResultError: Error { 
        case unknownType(Int32)
        case unexpectedRow(Base.RowStorage?)
        case unexpectedValue(BaseValueConvertible?)
    }

    enum SetUpError: Error {
        case setWalModeFailed
        case openFailed
    }
}

func lastErrorMessage(of dabasePointer: OpaquePointer) -> String {
    // `sqlite3_errmsg(nil)` return "out of memory", so do not worry about `db`
    String(cString: sqlite3_errmsg(dabasePointer))
}
