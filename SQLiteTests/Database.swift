//
//  Database.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/26.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import UIKit
@testable import SQLite

public func openDatabase() throws -> Database {
    let userDir = NSSearchPathForDirectoriesInDomains(
        .documentDirectory,
        .userDomainMask,
        true
    ).first!
    let path = "\(userDir)/tests.sqlite3"
    return try Database(path: path)
}
