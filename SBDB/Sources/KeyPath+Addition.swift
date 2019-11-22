//
//  KeyPath+Addition.swift
//  SBDB
//
//  Created by zhangwei on 2019/11/21.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

/// 基于 KeyPath 创建 where 语句
extension PartialKeyPath where Root: KeyPathToColumnNameConvertiable {
    
    static func > (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        guard let name = Root.columnName(of: keyPath) else { return .true }
        return Column(name) > value
    }

    static func >= (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        guard let name = Root.columnName(of: keyPath) else { return .true }
        return Column(name) >= value
    }

    static func < (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        guard let name = Root.columnName(of: keyPath) else { return .true }
        return Column(name) < value
    }

    static func <= (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        guard let name = Root.columnName(of: keyPath) else { return .true }
        return Column(name) <= value
    }

    static func == (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        guard let name = Root.columnName(of: keyPath) else { return .true }
        return Column(name) == value
    }

    static func != (keyPath: PartialKeyPath, value: BaseValueConvertible) -> Condition {
        guard let name = Root.columnName(of: keyPath) else { return .true }
        return Column(name) != value
    }
}

extension PartialKeyPath where Root: KeyPathToColumnNameConvertiable {
    
    public func hashString() -> String? {
        Root.columnName(of: self)
    }
    
    public func asc() -> Base.OrderTerm {
        Base.OrderTerm(columnName: hashString()!, strategy: .asc)
    }
    
    public func desc() -> Base.OrderTerm {
        Base.OrderTerm(columnName: hashString()!, strategy: .desc)
    }
}
