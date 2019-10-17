//
//  Table.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/20.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

public enum Table {

    public enum Constraint {
        case primaryKey(Array<Column.Indexed>, ConflictResolution)
        case unique(Array<Column.Indexed>, ConflictResolution)
        // TODO: foreign key support
        // TODO: check support
    }

    public class Definition {

        let name: String
        var columns: [Column.Definition] = []

        public var ifNotExists: Bool?
        public var withoutRowId: Bool?

        public init(name: String) {
            self.name = name
        }

        public func addColumn(_ name: String, type: Column.DataType?) -> Column.Definition {
            let column = Column.Definition(name, type)
            columns.append(column)
            return column
        }


        var sql: String {
            "CREATE TABLE"
        }

    //    public addIndex(_ name: String) -?
    }
}
