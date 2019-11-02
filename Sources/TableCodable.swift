//
//  TableCodable.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/24.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

// TODO: 使用 GYB 解决 `encode(_, forKey)` 和 `decode(_, forKey)` 重复代码的问题

// MARK: - TableCodable Protocols

public protocol CustomTableNameConvertible {
    static var tableName: String { get }
}

extension CustomTableNameConvertible {
    static var tableName: String { String(describing: Self.self) }
}

public protocol TableEncodable: Encodable, CustomTableNameConvertible { }

public protocol TableDecodable: Decodable, CustomTableNameConvertible { }

public typealias TableCodable = TableEncodable & TableDecodable

// MARK: - Table Encoder

final public class TableEncoder {

    public func encode<T: TableEncodable>(_ value: T) throws -> Base.RowStorage {
        let encoder = _TableEncoder()
        try value.encode(to: encoder)
        return encoder.storage
    }

    static var `default` = TableEncoder()
}

private class _TableEncoder: Encoder {

    // MARK: Encoder Protocol

    public var codingPath: [CodingKey] = []
    var storage = Base.RowStorage()

    public var userInfo: [CodingUserInfoKey : Any] = [:]

    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let keyedContainer = KeyedContainer<Key>(encoder: self, codingPath: codingPath)
        return KeyedEncodingContainer(keyedContainer)
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("No supporting")
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("No supporting")
    }

    struct KeyedContainer<Key>: KeyedEncodingContainerProtocol where Key : CodingKey {
        let encoder: _TableEncoder
        var codingPath: [CodingKey]

        func _convert(_ key: Key) -> Key { key }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError("No supporting")
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError("No supporting")
        }

        mutating func superEncoder() -> Encoder {
            fatalError("No supporting")
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            fatalError("No supporting")
        }

    }
}

// MARK: `encode(_, forKey)` Implementation

extension _TableEncoder.KeyedContainer {

    private func _encode<T: BaseValueConvertible>(_ value: T, forKey key: Key) {
        encoder.storage[_convert(key).stringValue] = value.baseValue
    }

    mutating func encodeNil(forKey key: Key) throws {
        _encode(Base.null, forKey: key)
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        _encode(value, forKey: key)
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        guard let validValue = value as? BaseValueConvertible else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "invalid value"))
        }
        _encode(validValue.baseValue, forKey: key)
    }
}

// MARK: `encodeIfPresent(_, forKey)` Implementation

extension _TableEncoder.KeyedContainer {

    private func _encodeIfPresent(_ value: BaseValueConvertible?, forKey key: Key) {
        encoder.storage[_convert(key).stringValue] = value?.baseValue ?? Base.null
    }

    mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
        _encodeIfPresent(value, forKey: key)
    }

    mutating func encodeIfPresent<T>(_ value: T?, forKey key: Key) throws where T : Encodable {
        guard T.self is BaseValueConvertible.Type else {
            throw EncodingError.invalidValue(value ?? "nil", EncodingError.Context(codingPath: codingPath, debugDescription: "invalid value"))
        }
        _encodeIfPresent(value as? BaseValueConvertible, forKey: key)
    }
}

// MARK: - Table Decoder

public final class TableDecoder {

    func decode<T>(_ type: T.Type, from storage: Base.RowStorage) throws -> T where T: TableDecodable {
        let decoder = _TableDecoder(storage: storage)
        return try T.init(from: decoder)
    }

    static var `default` = TableDecoder()
}

private class _TableDecoder: Decoder {

    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]

    let storage: Base.RowStorage

    init(storage: Base.RowStorage) {
        self.storage = storage
    }

    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
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

        var allKeys: [Key]

        let decoder: _TableDecoder

        init(decoder: _TableDecoder, codingPath: [CodingKey]) {
            self.decoder = decoder
            self.codingPath = codingPath
            var keys = [Key]()
            for colName in decoder.storage.keys {
                if let k = Key.init(stringValue: colName) {
                    keys.append(k)
                }
            }
            allKeys = keys
        }

        fileprivate func _converted(_ key: Key) -> Key { key }

        private let keyNotFoundCode = 1
        private let typeMismatchCode = 2

        func _context(forError code: Int) -> DecodingError.Context {
            switch code {
            case keyNotFoundCode:
                return DecodingError.Context(codingPath: codingPath, debugDescription: "key not found")
            case typeMismatchCode:
                return DecodingError.Context(codingPath: codingPath, debugDescription: "type mismatch")
            default:
                return DecodingError.Context(codingPath: codingPath, debugDescription: "unknown error")
            }
        }

        func contains(_ key: Key) -> Bool {
            self.decoder.storage.keys.contains(_converted(key).stringValue)
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
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
    }
}

// MARK: `decode(_, forKey)` Implementation

extension _TableDecoder.KeyedContainer {

    private func _baseValue(forKey key: Key) throws -> BaseValue {
        guard let value = decoder.storage[_converted(key).stringValue]?.baseValue else {
            throw DecodingError.keyNotFound(key, _context(forError: keyNotFoundCode))
        }
        return value
    }

    private func _decode<T: BaseValueConvertible>(_ type: T.Type, forKey key: Key) throws -> T {
        let baseValue = try _baseValue(forKey: key)
        guard let t = type.init(from: baseValue) else {
            throw DecodingError.typeMismatch(T.self, _context(forError: typeMismatchCode))
        }
        return t
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        let _ = try _decode(Base.Null.self, forKey: key)
        return true
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        try _decode(type, forKey: key)
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        try _decode(type, forKey: key)
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        try _decode(type, forKey: key)
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        try _decode(type, forKey: key)
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        try _decode(type, forKey: key)
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        try _decode(type, forKey: key)
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        try _decode(type, forKey: key)
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        try _decode(type, forKey: key)
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        try _decode(type, forKey: key)
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        try _decode(type, forKey: key)
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        try _decode(type, forKey: key)
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        try _decode(type, forKey: key)
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        try _decode(type, forKey: key)
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        try _decode(type, forKey: key)
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        guard let validType = type.self as? BaseValueConvertible.Type else {
            throw DecodingError.typeMismatch(type.self, _context(forError: typeMismatchCode))
        }

        let baseValue = try _baseValue(forKey: key)
        guard let ret = validType.init(from: baseValue) else {
            throw DecodingError.typeMismatch(type.self, _context(forError: typeMismatchCode))
        }
        return ret as! T
    }
}

// MARK: `decodeIfPresent(_, forKey)` Implementation

extension _TableDecoder.KeyedContainer {

    private func _decodeIfPresent<T: BaseValueConvertible>(_ type: T.Type, forKey key: Key) throws -> T? {
        let baseValue = try _baseValue(forKey: key)
        if let t = type.init(from: baseValue) {
            return t
        }
        if case .null = baseValue.storage {
            return nil
        }
        // TODO: 可能需要加配置，即配置类型匹配失败的处理逻辑：返回 nil 或者抛出错误
        throw DecodingError.typeMismatch(T.self, _context(forError: typeMismatchCode))
    }

    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
        try _decodeIfPresent(type, forKey: key)
    }

    func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
        guard let validType = type.self as? BaseValueConvertible.Type else {
            throw DecodingError.typeMismatch(type.self, _context(forError: typeMismatchCode))
        }

        let baseValue = try _baseValue(forKey: key)
        if let ret = validType.init(from: baseValue) {
            return (ret as! T)
        }
        if case .null = baseValue.storage {
            return nil
        }
        throw DecodingError.typeMismatch(type.self, _context(forError: typeMismatchCode))
    }
}
