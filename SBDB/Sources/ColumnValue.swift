//
//  ColumnValue.swift
//  SBDB
//
//  Created by SadJason on 2019/11/23.
//  Copyright © 2019 SadJason. All rights reserved.
//

import Foundation

public struct ColumnValue: Equatable {

    public let storage: Storage

    public enum Storage: Equatable {
        case null
        case integer(Int64)
        case real(Double)
        case text(String)
        case blob(Data)
    }

    init(storage: Storage) {
        self.storage = storage
    }
}

extension ColumnValue {
    public static var null: ColumnValue = Self.init(storage: .null)
}

extension ColumnValue: CustomDebugStringConvertible {
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

struct ColumnNull {  }
