//
//  KeyPath+Addition.swift
//  SBDB
//
//  Created by zhangwei on 2019/11/21.
//  Copyright © 2019 ByteDance. All rights reserved.
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

/// Support Condition
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
    
    func between(_ value1: ColumnValueConvertible, and value2: ColumnValueConvertible) -> Expr.Condition {
        toColumn().between(value1, and: value2)
    }
    
    func notBetween(_ value1: ColumnValueConvertible, and value2: ColumnValueConvertible) -> Expr.Condition {
        toColumn().notBetween(value1, and: value2)
    }
    
    func isNull() -> Expr.Condition {
        toColumn().isNull()
    }
    
    func notNull() -> Expr.Condition {
        toColumn().notNull()
    }
}

extension Expr {
    
    public static func asc<Root>(_ keyPath: PartialKeyPath<Root>)
        -> Expr.OrderTerm
        where Root: TableCodingKeyConvertiable
    {
        Expr.OrderTerm(column: keyPath.stringValue, strategy: .asc)
    }
    
    public static func desc<Root>(_ keyPath: PartialKeyPath<Root>)
        -> Expr.OrderTerm
        where Root: TableCodingKeyConvertiable
    {
        Expr.OrderTerm(column: keyPath.stringValue, strategy: .desc)
    }
}
