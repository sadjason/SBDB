//
//  Connection.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/18.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

enum SQLiteError : Error {

    public typealias Reason = String
    public typealias Code = Int32

    enum ConnectionError: Error {
        case openFailed(Reason, Code)
    }

    enum StatementError: Error {
        case prepareFailed(Reason, Code)
        case stepFailed(Reason, Code)
        case resetFailed(Reason, Code)
        case bindFailed(Reason, Code)
    }

    enum ReadError: Error {
        case typeMismatch
    }

    enum ParameterError: Error {
        case notValid
    }
}

func lastErrorMessage(of dabasePointer: OpaquePointer) -> String {
    // `sqlite3_errmsg(nil)` return "out of memory", so do not worry about `db`
    String(cString: sqlite3_errmsg(dabasePointer))
}

typealias SQLiteExecuteCode = Int32
