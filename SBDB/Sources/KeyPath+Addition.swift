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
        Root.codingKey(of: self).stringValue
    }
}

/// Support Condition
extension PartialKeyPath where Root: TableCodingKeyConvertiable {
    
    public static func > (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        Column(keyPath.stringValue) > value
    }

    public static func >= (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        Column(keyPath.stringValue) >= value
    }

    public static func < (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        Column(keyPath.stringValue) < value
    }

    public static func <= (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        Column(keyPath.stringValue) <= value
    }

    public static func == (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        Column(keyPath.stringValue) == value
    }

    public static func != (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        Column(keyPath.stringValue) != value
    }
}

/// Support Order
extension PartialKeyPath where Root: TableCodingKeyConvertiable {
    
    public func asc() -> Base.OrderTerm {
        Base.OrderTerm(column: stringValue, strategy: .asc)
    }
    
    public func desc() -> Base.OrderTerm {
        Base.OrderTerm(column: stringValue, strategy: .desc)
    }
}

/// Support Column

