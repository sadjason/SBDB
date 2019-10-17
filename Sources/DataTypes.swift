//
//  DataTypes.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/20.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

// MARK: Datatypes

// https://www.sqlite.org/datatype3.html
extension Database {
    public enum StorageType {
        case null
        case integer(Int64)
        case real(Double)
        case text(String)
        case bolb(Data)
    }

    public enum AffinityType: String {
        case text       = "TEXT"
        case numeric    = "NUMERIC"
        case integer    = "INTEGER"
        case real       = "REAL"
        case blob       = "BLOB"
    }
}

protocol StorageConvertible {
    var databaseValue: Database.StorageType { get }
}

extension Int64: StorageConvertible {
    var databaseValue: Database.StorageType {
        .integer(self)
    }
}

extension Int: StorageConvertible {
    var databaseValue: Database.StorageType {
        .integer(Int64(self))
    }
}

extension Int32: StorageConvertible {
    var databaseValue: Database.StorageType {
        .integer(Int64(self))
    }
}

extension Int16: StorageConvertible {
    var databaseValue: Database.StorageType {
        .integer(Int64(self))
    }
}

extension Int8: StorageConvertible {
    var databaseValue: Database.StorageType {
        .integer(Int64(self))
    }
}

extension Bool: StorageConvertible {
    var databaseValue: Database.StorageType {
        .integer(self ? 1 : 0)
    }
}
