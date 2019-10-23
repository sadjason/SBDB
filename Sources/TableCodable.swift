//
//  TableCodable.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

public protocol TableEncodable: Encodable {
    static var tableName: String { get }
    func encode(to: TableEncoder) throws
}

extension TableEncodable {
    static var tableName: String { String(describing: Self.self) }
    
    func encode(to encoder: TableEncoder) throws {
        try encode(to: encoder as Encoder)
    }
}
