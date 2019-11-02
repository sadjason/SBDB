//
//  BaseValue+Convertible.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

// TODO: 使用 gyb 改善，https://nshipster.com/swift-gyb/

extension Int8: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(Int64(self)))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = Int8(val)
        default:
            return nil
        }
    }
}

extension Int16: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(Int64(self)))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = Int16(val)
        default:
            return nil
        }
    }
}

extension Int32: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(Int64(self)))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = Int32(val)
        default:
            return nil
        }
    }
}

extension Int: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(Int64(self)))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = Int(val)
        default:
            return nil
        }
    }
}

extension Int64: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(self))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = val
        default:
            return nil
        }
    }
}

extension UInt8: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(Int64(self)))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = UInt8(val)
        default:
            return nil
        }
    }
}

extension UInt16: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(Int64(self)))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = UInt16(val)
        default:
            return nil
        }
    }
}

extension UInt32: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(Int64(self)))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = UInt32(val)
        default:
            return nil
        }
    }
}

extension UInt: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(Int64(self)))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = UInt(val)
        default:
            return nil
        }
    }
}

extension UInt64: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(Int64(self)))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = UInt64(val)
        default:
            return nil
        }
    }
}

extension Bool: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .integer(self ? 1 : 0))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .integer(let val):
            self = val > 0
        default:
            return nil
        }
    }
}

extension Float: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .real(Double(self)))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .real(let val):
            self = Float(val)
        default:
            return nil
        }
    }
}

extension Double: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .real(self))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .real(let val):
            self = val
        default:
            return nil
        }
    }
}

extension String: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .text(self))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .text(let val):
            self = val
        default:
            return nil
        }
    }
}

extension Data: BaseValueConvertible {

    public var baseValue: BaseValue {
        BaseValue(storage: .blob(self))
    }

    public init?(from dbValue: BaseValue) {
        switch dbValue.storage {
        case .blob(let val):
            self = val
        default:
            return nil
        }
    }
}

extension Base {
    
    struct Null: BaseValueConvertible {
        var baseValue: BaseValue {
            BaseValue(storage: .null)
        }
        init?(from dbValue: BaseValue) {
            switch dbValue.storage {
            case .null: return
            default: return nil
            }
        }

        fileprivate static let null = Null.init(from: BaseValue(storage: .null))!
    }

    static var null: Null {
        Null.null
    }
}
