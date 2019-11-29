//
//  ColumnConvertible.swift
//  SBDB
//
//  Created by SadJason on 2019/11/23.
//  Copyright © 2019 SadJason. All rights reserved.
//

import Foundation

// MARK: ColumnValueConvertible

public protocol ColumnValueConvertible {
    var columnValue: ColumnValue { get }
    init?(from value: ColumnValue)
}

// MARK: ColumnConvertiable

protocol ColumnConvertiable: ColumnValueConvertible {
    static var columnType: Expr.AffinityType { get }
    
    init(forColumnDecoding withKey: CodingKey) throws
}

extension ColumnConvertiable {
    
    static var columnType: Expr.AffinityType { .blob }
    
    init(forColumnDecoding withKey: CodingKey) throws {
        switch Self.columnType {
        case .integer:
            guard let ret = Self.init(from: ColumnValue(storage: .integer(0))) else {
                throw SQLiteError.ColumnConvertError.cannotConvertFromNull
            }
            self = ret
        case .real:
            guard let ret = Self.init(from: ColumnValue(storage: .real(0.0))) else {
                throw SQLiteError.ColumnConvertError.cannotConvertFromNull
            }
            self = ret
        case .numeric:
            if let ret = Self.init(from: ColumnValue(storage: .real(0.0))) {
                self = ret
                return
            }
            if let ret = Self.init(from: ColumnValue(storage: .integer(0))) {
                self = ret
                return
            }
            throw SQLiteError.ColumnConvertError.cannotConvertFromNull
        case .text:
            guard let ret = Self.init(from: ColumnValue(storage: .text(""))) else {
                throw SQLiteError.ColumnConvertError.cannotConvertFromNull
            }
            self = ret
        case .blob:
            guard let ret = Self.init(from: ColumnValue(storage: .blob(Data()))) else {
                throw SQLiteError.ColumnConvertError.cannotConvertFromNull
            }
            self = ret
        }
    }
}

// MARK: ColumnValue

extension ColumnValue: ColumnValueConvertible {
    
    public init?(from value: ColumnValue) {
        self = value
    }

    public var columnValue: ColumnValue { self }
}

extension ColumnNull: ColumnValueConvertible {
    
    init?(from value: ColumnValue) {
        switch value.storage {
        case .null: return
        default: return nil
        }
    }
    var columnValue: ColumnValue { ColumnValue.null }
}
