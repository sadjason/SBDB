//
//  Connection.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/18.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

public enum SQLiteError: Error {

    public typealias Code = Int32
    public typealias Description = String

    case misuse(Description)
    
    public enum ExecuteError: Error {
        case prepareStmtFailed(Description, Code)
        case bindParamFailed(Description, Code)
        case stepFailed(Description, Code)
    }
    
    public enum TransactionError: Error {
        case begin(Description, Code)
        case commit(Description, Code)
        case rollback(Description, Code)
    }

    public enum ResultError: Error {
        case unknownType(Int32)
        case unexpectedRow(RowStorage?)
        case unexpectedValue(ColumnValueConvertible?)
    }

    public enum SetUpError: Error {
        case setWalModeFailed
        case openFailed
    }
    
    // sqlite3 原生 API 错误，不对外暴露
    enum LibraryError: Error {
        case prepareStatementFailed
        case stepStementFailed
        case bindParameterFailed
    }
    
    enum ColumnConvertError: Error {
        case cannotConvertFromNull
    }
}

func lastErrorMessage(of dabasePointer: OpaquePointer) -> String {
    // `sqlite3_errmsg(nil)` return "out of memory", so do not worry about `db`
    String(cString: sqlite3_errmsg(dabasePointer))
}
