//
//  BaseValue+Convertible.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

// TODO: 使用 gyb 改善，https://nshipster.com/swift-gyb/

extension Int8: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension Int16: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension Int32: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension Int: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension Int64: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension UInt8: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension UInt16: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension UInt32: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension UInt: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension UInt64: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension Bool: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .integer }
    
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

extension Float: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .real }
    
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

extension Double: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .real }
    
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

extension String: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .text }
    
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

extension Data: ColumnConvertiable {
    
    static var columnType: Base.AffinityType { .blob }
    
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
    
    struct Null: ColumnConvertiable {
        
        static var columnType: Base.AffinityType { .blob }
        
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
