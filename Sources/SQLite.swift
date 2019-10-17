//
//  SQLite.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/17.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

public enum Order: String {
    case asc
    case desc
}

/// https://www.sqlite.org/syntax/conflict-clause.html
public enum ConflictResolution: String {
    case rollback
    case abort
    case fail
    case ignore
    case replace
}

/// https://www.sqlite.org/datatype3.html#collation
public enum CollateName: String {
    case binary
    case nocase
    case rtrim
}
