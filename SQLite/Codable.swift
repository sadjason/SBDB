//
//  Codable.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/22.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

struct Pet: Codable {
    let name: String?
    let age: Int
    let category: String

//    enum CodingKeys: String, CodingKey {
//        case name, age, category
//    }
//
//    func encode(to encoder: DatabaseEncoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encodeIfPresent(name, forKey: .name)
//        try container.encode(age, forKey: .age)
//        try container.encode(category, forKey: .category)
//    }
}

struct Person: Codable {
    let name: String
    let age: Int
    var pets: Array<Pet>?

//    enum CodingKeys: String, CodingKey {
//        case name
//        case age
//        case pets
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(name, forKey: .name)
//        try container.encode(age, forKey: .age)
//        try container.encode(pets, forKey: .pets)
////        print(type(of: encoder))
//    }
}


//public func testCodable() {
//    let encoder = JSONEncoder()
//    encoder.keyEncodingStrategy = .convertToSnakeCase
//    let decoder = JSONDecoder()
//    decoder.keyDecodingStrategy = .convertFromSnakeCase
//
//    let qixi = Pet(name: "Qi Xi", age: 1, category: "Cat")
//    let jason = Person(name: "Jason", age: 27, pets: [qixi])
//
//    let data = try! encoder.encode(jason)
//    print(String(data: data, encoding: .utf8)!)
//
//    let qixiData = try! encoder.encode(qixi)
//    print(String(data: qixiData, encoding: .utf8)!)
//}

extension Pet: TableEncodable { }
extension Person : TableEncodable { }

public func testCodable() {
    let qixi = Pet(name: nil, age: 1, category: "Cat")
    // let jason = Person(name: "Jason", age: 27, pets: [qixi])
    let p = try! TableEncoder.encode(qixi)
    print(p)
}
