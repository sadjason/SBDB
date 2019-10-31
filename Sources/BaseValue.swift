//
//  BaseValue.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

typealias SQLiteRawValue = OpaquePointer

extension Base {

    public struct Value {

        public let storage: Storage

        public enum Storage {
            case null
            case integer(Int64)
            case real(Double)
            case text(String)
            case blob(Data)
        }

        init(storage: Storage) {
            self.storage = storage
        }

        init(sqliteRawValue: SQLiteRawValue) {
            switch sqlite3_value_type(sqliteRawValue) {
            case SQLITE_INTEGER:
                storage = .integer(sqlite3_value_int64(sqliteRawValue))
            case SQLITE_FLOAT:
                storage = .real(sqlite3_value_double(sqliteRawValue))
            case SQLITE_TEXT:
                storage = .text(String(cString: sqlite3_value_text(sqliteRawValue)))
            case SQLITE_BLOB:
                if let bytes = sqlite3_value_blob(sqliteRawValue) {
                    let count = Int(sqlite3_value_bytes(sqliteRawValue))
                    storage = .blob(Data(bytes: bytes, count: count))
                } else {
                    storage = .blob(Data())
                }
            default:
                fatalError()
            }
        }
    }
}

public typealias BaseValue = Base.Value

extension BaseValue: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self.storage {
        case .integer(let val): return String(val)
        case .real(let val): return String(val)
        case .null: return "null"
        case .text(let val): return val
        case .blob: return "blob"
        }
    }
}

public protocol BaseValueConvertible {
    var baseValue: BaseValue { get }
    init?(from dbValue: BaseValue)
}

extension BaseValue: BaseValueConvertible {
    
    public init?(from dbValue: BaseValue) {
        self = dbValue
    }

    public var baseValue: BaseValue { self }
}
