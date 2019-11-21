//
//  TableColumnDecoder.swift
//  SBDB
//
//  Created by zhangwei on 2019/11/20.
//  Copyright © 2019 zhangwei. All rights reserved.
//

import Foundation

// 提取 Table 的 column 信息
// 参考 https://github.com/PerfectlySoft/Perfect-CRUD/blob/master/Sources/PerfectCRUD/Coding/CodingNames.swift#L265

struct _TableColumnStructure {
    var name: String
    var type: Base.AffinityType
    var nonnull: Bool
}

typealias _TableColumnContainer = Dictionary<String, _TableColumnStructure>

final class TableColumnDecoder {

    func decode<T: Decodable>(_ type: T.Type) throws -> _TableColumnContainer {
        let decoder = _TableColumnDecoder()
        _ = try T.init(from: decoder)
        return decoder.container
    }

    static var `default` = TableColumnDecoder()
}

private class _TableColumnDecoder: Decoder {

    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]
    var container: _TableColumnContainer = [:]

    public func container<Key>(keyedBy type: Key.Type)
        throws -> KeyedDecodingContainer<Key> where Key : CodingKey
    {
        KeyedDecodingContainer(KeyedContainer<Key>(decoder: self, codingPath: codingPath))
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("No supporting")
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError("No supporting")
    }

    struct KeyedContainer<Key>: KeyedDecodingContainerProtocol where Key: CodingKey  {
        var codingPath: [CodingKey]

        var allKeys: [Key] = []

        let decoder: _TableColumnDecoder

        init(decoder: _TableColumnDecoder, codingPath: [CodingKey]) {
            self.decoder = decoder
            self.codingPath = codingPath
        }

        fileprivate func _converted(_ key: Key) -> Key { key }

        func contains(_ key: Key) -> Bool { true }

        func nestedContainer<NestedKey>(
            keyedBy type: NestedKey.Type,
            forKey key: Key
        ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey
        {
            fatalError("No supporting")
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            fatalError("No supporting")
        }

        func superDecoder() throws -> Decoder {
            fatalError("No supporting")
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            fatalError("No supporting")
        }
        
        private func _appendKey(_ key: Key, _ type: Base.AffinityType, _ nonnull: Bool) {
            decoder.container[key.stringValue] = _TableColumnStructure(name: key.stringValue,
                                                                       type: type,
                                                                       nonnull: nonnull)
        }
    }
}

// MARK: `decode(_, forKey)` Implementation

extension _TableColumnDecoder.KeyedContainer {
    
    func _advance1<T: ColumnConvertiable>(_ key: Key, _ type: T.Type) -> T {
        _appendKey(key, type.columnType, true)
        return try! type.init(withNull: Base.null)
    }

    // TODO: 什么情况下会调用 `decodeNil(forKey:)`
    func decodeNil(forKey key: Key) throws -> Bool {
        _appendKey(key, .blob, true)
        return true
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { _advance1(key, type) }

    func decode(_ type: String.Type, forKey key: Key) throws -> String { _advance1(key, type) }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { _advance1(key, type) }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float { _advance1(key, type) }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int { _advance1(key, type) }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { _advance1(key, type) }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { _advance1(key, type) }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { _advance1(key, type) }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { _advance1(key, type) }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { _advance1(key, type) }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { _advance1(key, type) }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { _advance1(key, type) }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { _advance1(key, type) }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { _advance1(key, type) }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        guard let validType = type.self as? ColumnConvertiable.Type else {
            throw SQLiteError.ColumnConvertError.cannotConvertFromNull
        }
        _appendKey(key, validType.columnType, true)
        return try validType.init(withNull: Base.null) as! T
    }
}

// MARK: `decodeIfPresent(_, forKey)` Implementation

extension _TableColumnDecoder.KeyedContainer {
    
    func _advance2<T: ColumnConvertiable>(_ key: Key, _ type: T.Type) -> T? {
        _appendKey(key, type.columnType, false)
        return nil
    }
     
    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? { _advance2(key, type) }

    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? { _advance2(key, type) }

    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? { _advance2(key, type) }

    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? { _advance2(key, type) }

    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? { _advance2(key, type) }

    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? { _advance2(key, type) }

    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? { _advance2(key, type) }

    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? { _advance2(key, type) }

    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? { _advance2(key, type) }

    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? { _advance2(key, type) }

    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? { _advance2(key, type) }

    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? { _advance2(key, type) }

    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? { _advance2(key, type) }

    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? { _advance2(key, type) }

    func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
        guard let validType = type.self as? ColumnConvertiable.Type else {
            throw SQLiteError.ColumnConvertError.cannotConvertFromNull
        }
        _appendKey(key, validType.columnType, false)
        return nil
    }
}
