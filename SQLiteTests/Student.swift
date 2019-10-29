//
//  Student.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/25.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
@testable import SQLite

struct Student: TableCodable, Equatable {
    let name: String
    let age: UInt8
    let address: String?
    let grade: Int?
    let married: Bool
    let isBoy: Bool?
    let gpa: Float
    let extra: Data?
}

private func randomFirstName() -> String {
    let strs =
    ["赵", "钱", "孙", "李", "周", "吴", "郑", "王",
     "冯", "陈", "褚", "卫", "蒋", "沈", "韩", "杨",
     "朱", "秦", "尤", "许", "何", "吕", "施", "张",
     "孔", "曹", "严", "华", "金", "魏", "陶", "姜",
     "戚", "谢", "邹", "喻", "柏", "水", "窦", "章",
     "云", "苏", "潘", "葛", "奚", "范", "彭", "郎"]
    let index = Int.random(in: Range(NSRange(location: 0, length: strs.count))!)
    return strs[index]
}

private func randomChineseChar() -> String? {
    // 中文字符范围：u4e00-u9fa5
    let u = UInt32.random(in: Range(uncheckedBounds: (lower: 0x4e00, upper: 0x9fa5)))
    if let uc = UnicodeScalar(u) {
        return String(uc)
    }
    return nil
}

func generateStudent() -> Student {
    let c1 = randomFirstName()
    let c2 = randomChineseChar()
    let c3 = randomChineseChar()


    let name = (c2 != nil && c3 != nil) ? "\(c1)\(c2!)\(c3!)" : "无名"
    let age = UInt8(arc4random_uniform(100))
    let grade = Int(arc4random_uniform(6))
    let gpa: Float = Float(((arc4random_uniform(100) % 5) + 1)) / 5.0
    let yesOrNo: Bool = (arc4random_uniform(100) % 2) > 0
    let noOrYes: Bool = (arc4random_uniform(100) % 2) > 0

    let extra = ["name": name, "age": String(age)]

    return Student(
        name: name,
        age: age,
        address: yesOrNo ? "中国: \(name)" : nil,
        grade: noOrYes ? grade : nil,
        married: yesOrNo,
        isBoy: yesOrNo ? noOrYes : nil,
        gpa: gpa,
        extra: noOrYes ? try! JSONEncoder().encode(extra) : nil
    )
}
