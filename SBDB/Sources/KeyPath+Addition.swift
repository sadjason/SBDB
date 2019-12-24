//
//  KeyPath+Addition.swift
//  SBDB
//
//  Created by SadJason on 2019/11/21.
//  Copyright © 2019 SadJason. All rights reserved.
//

import Foundation

extension PartialKeyPath where Root: TableCodingKeyConvertiable {
    
    public var stringValue: String {
        Root.codingKey(forKeyPath: self).stringValue
    }
    
    public func toColumn() -> Expr.Column {
        Expr.Column(stringValue)
    }
}

// MARK: Condition

extension PartialKeyPath where Root: TableCodingKeyConvertiable {
    
    public static func > (keyPath: PartialKeyPath, value: ColumnValueConvertible) -> Expr.Condition {
        keyPath.toColumn() > value
    }

    public static func >= (keyPath: PartialKeyPath, value: ColumnValueConvertible) -> Expr.Condition {
        keyPath.toColumn() >= value
    }

    public static func < (keyPath: PartialKeyPath, value: ColumnValueConvertible) -> Expr.Condition {
        keyPath.toColumn() < value
    }

    public static func <= (keyPath: PartialKeyPath, value: ColumnValueConvertible) -> Expr.Condition {
        keyPath.toColumn() <= value
    }

    public static func == (keyPath: PartialKeyPath, value: ColumnValueConvertible) -> Expr.Condition {
        keyPath.toColumn() == value
    }

    public static func != (keyPath: PartialKeyPath, value: ColumnValueConvertible) -> Expr.Condition {
        keyPath.toColumn() != value
    }
    
    public func `in`(_ values: [ColumnValueConvertible]) -> Expr.Condition {
        toColumn().in(values)
    }
    
    public func notIn(_ values: [ColumnValueConvertible]) -> Expr.Condition {
        toColumn().notIn(values)
    }
    
    public func between(
        _ value1: ColumnValueConvertible,
        and value2: ColumnValueConvertible
    ) -> Expr.Condition {
        toColumn().between(value1, and: value2)
    }
    
    public func notBetween(
        _ value1: ColumnValueConvertible,
        and value2: ColumnValueConvertible
    ) -> Expr.Condition
    {
        toColumn().notBetween(value1, and: value2)
    }
    
    public func isNull() -> Expr.Condition {
        toColumn().isNull()
    }
    
    public func notNull() -> Expr.Condition {
        toColumn().notNull()
    }
}

// MARK: Select Term

extension PartialKeyPath: SelectTermConvertiable where Root: TableCodingKeyConvertiable {
    public func asSelect() -> Expr.Column { Expr.Column(stringValue) }
}

// MARK: Order Term

extension PartialKeyPath: OrderTermConvertiable where Root: TableCodingKeyConvertiable {
    public func asOrder() -> Expr.OrderTerm { Expr.Column(stringValue).asOrder() }
}
