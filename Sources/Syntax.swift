//
//  SQLite.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

protocol Executable: ParameterExpression {
    associatedtype Result
    func exec(in database: Database) throws -> Result
}

protocol ReadExecutable: Executable {

}

protocol WriteExecutable: Executable {

}
