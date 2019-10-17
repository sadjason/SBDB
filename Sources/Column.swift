//
//  Column.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/17.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

public enum Column {

    enum Constraint {
        enum DefaultValue {
            case number(Int64)
            case double(Double)
            // TODO: support expr default
        }

        case primaryKey(Order?, ConflictResolution?, Bool?)
        case notNull(ConflictResolution?)
        case unique(ConflictResolution?)
        case `default`(DefaultValue)
        case collate(CollateName)
        // TODO: check support
        // TODO: foreign key support

        var clause: String {
            let onConflictPhrase = "ON CONFLICT"

            switch self {
            case let .primaryKey(order, conflictResolution, autoIncrement):
                var str = "PRIMARY KEY"
                if let r = order {
                    str += " \(r.rawValue)"
                }
                if let c = conflictResolution {
                    str += " \(onConflictPhrase) \(c.rawValue)"
                }
                if let a = autoIncrement, a {
                    str += " AUTOINCREMENT"
                }
                return str
            case let .notNull(conflictResolution):
                var str = "NOT NULL"
                if let c = conflictResolution {
                    str += " \(onConflictPhrase) \(c.rawValue)"
                }
                return str
            case let .unique(conflictResolution):
                var ret = "UNIQUE"
                if let c = conflictResolution {
                    ret += " \(onConflictPhrase) \(c.rawValue)"
                }
                return ret
            case .default:
                return "defaultValue"
            case .collate:
                return "collate"
            }
        }
    }

    /// https://www.sqlite.org/datatype3.html
    public enum DataType: String {
        case text       = "TEXT"
        case numeric    = "NUMERIC"
        case integer    = "INTEGER"
        case real       = "REAL"
        case blob       = "BLOB"
    }

    enum ConstraintType: Int, Comparable {
        static func < (lhs: Column.ConstraintType, rhs: Column.ConstraintType) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        case primary, notNull, unique, `default`, collate
    }

    /// https://www.sqlite.org/syntax/column-def.html
    public class Definition {
        let name: String
        let type: DataType?

        fileprivate var constraints = [ConstraintType : Constraint]()

        // TODO: 对于默认值，是写在定义式里，还是在构造器中，哪个更合适？
        init(_ name: String, _ type: DataType? = nil) {
            self.name = name
            self.type = type
        }

        public func primaryKey(
            autoIncrement: Bool = false,
            onConflict: ConflictResolution? = nil,
            order: Order? = nil) -> Definition
        {
            if autoIncrement {
                guard let t = type, t == .integer else {
                    assert(false, "AUTOINCREMENT is only allowed on an INTEGER PRIMARY KEY without DESC")
                    return self
                }
                guard order == nil || order! == .asc else {
                    assert(false, "AUTOINCREMENT is only allowed on an INTEGER PRIMARY KEY without DESC")
                    return self
                }
            }
            constraints[.primary] = .primaryKey(order, onConflict, autoIncrement)
            // set `not null` for primary key
            if constraints[.notNull] == nil {
                _ = notNull()
            }
            return self
        }

        public func notNull(onConflict: ConflictResolution? = nil) -> Definition {
            constraints[.notNull] = .notNull(onConflict)
            return self
        }

        public func unique(onConflict: ConflictResolution? = nil) -> Definition {
            constraints[.unique] = .unique(onConflict)
            return self
        }


        public func `default`(value: String) -> Definition {
            // constraints[.default] = .default(value)
            return self
        }

        public func collate(name: CollateName? = nil) -> Definition {
            constraints[.collate] = .collate(name!)
            return self
        }

        var sql: String {
            var ret = name
            if let type = type {
                ret += " \(type.rawValue)"
            }

            constraints.keys.sorted().forEach { key in
                if case .unique = key, constraints.keys.contains(.primary) {
                    return
                }
                ret += " \(constraints[key]!.clause)"
            }
            return ret
        }
    }

    /// https://www.sqlite.org/syntax/indexed-column.html
    public struct Indexed {
        let columnName: String
        let collateName: CollateName
        let order: Order?
    }
}

extension Column.Definition : CustomDebugStringConvertible {
    public var debugDescription: String { sql }
}
