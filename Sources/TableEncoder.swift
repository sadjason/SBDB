//
//  TableEncoder.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

final public class TableEncoder: Encoder {

    // MARK: Encoder Protocol

    public var codingPath: [CodingKey] = []
    var storage = Storage()

    public var userInfo: [CodingUserInfoKey : Any] = [:]

    typealias Storage = Dictionary<String, BaseValueConvertible>

    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let keyedContainer = KeyedContainer<Key>(encoder: self, codingPath: codingPath)
        return KeyedEncodingContainer(keyedContainer)
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Do not support")
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("Do not support")
    }

    // MARK: Encoding Database Values

    static func encode<T: TableEncodable>(_ value: T) throws -> Storage {
        let encoder = TableEncoder()
        try value.encode(to: encoder)
        return encoder.storage
    }
}

extension TableEncoder {
    fileprivate struct KeyedContainer<Key>: KeyedEncodingContainerProtocol where Key : CodingKey {
        let encoder: TableEncoder
        var codingPath: [CodingKey]

        func _convert(_ key: Key) -> Key { key }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError("Do not support")
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError("Do not support")
        }

        mutating func superEncoder() -> Encoder {
            fatalError("Do not support")
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            fatalError("Do not support")
        }

    }
}

extension TableEncoder.KeyedContainer {

    mutating func encodeNil(forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .null)
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(value ? 1 : 0))
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .text(value))
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .real(value))
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .real(Double(value)))
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(Int64(value)))
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(Int64(value)))
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(Int64(value)))
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(Int64(value)))
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(Int64(value)))
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(Int64(value)))
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(Int64(value)))
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(Int64(value)))
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(Int64(value)))
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue.init(storage: .integer(Int64(value)))
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        fatalError("waiting for supporting")
    }
}

extension TableEncoder.KeyedContainer {

    mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value! ? 1 : 0)))
    }

    mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .text(value!))
    }

    mutating func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .real(value!))
    }

    mutating func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .real(Double(value!)))
    }

    mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value!)))
    }

    mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value!)))
    }

    mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value!)))
    }

    mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value!)))
    }

    mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value!)))
    }

    mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value!)))
    }

    mutating func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value!)))
    }

    mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value!)))
    }

    mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value!)))
    }

    mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .integer(Int64(value!)))
    }

    mutating func encodeIfPresent(_ value: Data?, forKey key: Key) throws {
        encoder.storage[_convert(key).stringValue] = BaseValue(storage: value == nil ? .null : .blob(value!))
    }

    mutating func encodeIfPresent<T>(_ value: T?, forKey key: Key) throws where T : Encodable {
        fatalError("waiting for supporting")
    }
}
