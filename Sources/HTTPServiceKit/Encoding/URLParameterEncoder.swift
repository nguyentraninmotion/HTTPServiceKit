/***************************************************************************
 * This source file is part of the HTTPServiceKit open source project.     *
 *                                                                         *
 * Copyright (c) 2020-present, InMotion Software and the project authors   *
 * Licensed under the MIT License                                          *
 *                                                                         *
 * See LICENSE.txt for license information                                 *
 ***************************************************************************/

import Foundation
import PromiseKit

struct URLParameterUnkeyedEncodingContainer: UnkeyedEncodingContainer, SingleValueEncodingContainer {

    private let parent: URLParameterEncoder
    fileprivate(set) public var codingPath: [CodingKey] = []
    private(set) public var count: Int = 0

    init(parent: URLParameterEncoder) {
        self.parent = parent
        self.codingPath = parent.codingPath
    }

    private func makeKey() -> String {
        switch(self.parent.arrayEncodingStrategy) {
            case .brackets: return "[]"
            case .bracketsWithIndex: return "[\(self.count)]"
            case .repeatKey: return ""
        }
    }

    mutating func add(_ value: String?) {
        self.parent.add(key: self.makeKey(), value: value)
        self.count += 1
    }

    mutating func encode(_ value: Int) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: Int8) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: Int16) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: Int32) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: Int64) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: UInt) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: UInt8) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: UInt16) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: UInt32) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: UInt64) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: Float) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: Double) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: String) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: Bool) throws { self.add(value ? "true" : "false") }
    mutating func encodeNil() throws { self.add(nil) }
    mutating func encode(_ value: Data) throws { self.add(value.base64EncodedString()) }
    mutating func encode(_ value: Date) throws { self.add(self.parent.dateFormat.string(from: value)) }

    mutating func encode<T>(_ value: T) throws where T : Encodable {
        switch (value) {
            case is Date: try self.encode(value as! Date)
            case is Data: try self.encode(value as! Data)
            default: try value.encode(to: self.parent)
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedEncodingContainer(URLParameterKeyedEncodingContainer<NestedKey>(parent: self.parent))
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return URLParameterUnkeyedEncodingContainer(parent: self.parent)
    }

    mutating func superEncoder() -> Encoder { return self.parent }
}

struct URLParameterKeyedEncodingContainer<K:CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K

    fileprivate(set) public var codingPath: [CodingKey]
    private let parent: URLParameterEncoder

    init(parent: URLParameterEncoder) {
        self.parent = parent
        self.codingPath = parent.codingPath
    }

    private mutating func add(key: K, value: String) {self.add(key: key, value: Optional.some(value))}

    private mutating func add(key: K, value: String?) {
        var str = key.stringValue
        if self.codingPath.count > 0 { str = "." + str }
        self.parent.add(key: str, value: value)
    }

    mutating func encodeNil(forKey key: K) throws {self.add(key: key, value: nil)}
    mutating func encode(_ value: Bool, forKey key: K) throws { self.add(key: key, value: value ? "true" : "false") }
    mutating func encode(_ value: Int, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: Int8, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: Int16, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: Int32, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: Int64, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: UInt, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: UInt8, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: UInt16, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: UInt32, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: UInt64, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: Float, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: Double, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: String, forKey key: K) throws { self.add(key: key, value: String(describing: value)) }
    mutating func encode(_ value: Data, forKey key: K) throws { self.add(key: key, value: value.base64EncodedString()) }
    mutating func encode(_ value: Date, forKey key: K) throws { self.add(key: key, value: self.parent.dateFormat.string(from: value)) }

    mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        switch (value) {
            case is Date: try self.encode(value as! Date, forKey: key)
            case is Data: try self.encode(value as! Data, forKey: key)
            default:
                self.parent.codingPath.append(key)
                try value.encode(to: self.parent)
                self.parent.codingPath.removeLast()
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedEncodingContainer(URLParameterKeyedEncodingContainer<NestedKey>(parent: self.parent))
    }

    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return URLParameterUnkeyedEncodingContainer(parent: self.parent)
    }

    mutating func superEncoder() -> Encoder {
        return self.parent
    }

    mutating func superEncoder(forKey key: K) -> Encoder {
        return self.parent
    }
}

public class URLParameterEncoder {
    enum ArrayEncodingStrategy {
        case repeatKey
        case bracketsWithIndex
        case brackets
    }

    fileprivate(set) public var codingPath: [CodingKey] = []
    internal var values: [URLQueryItem] = []
    private(set) public var userInfo: [CodingUserInfoKey : Any] = [:]

    var dateFormat: DateFormatter
    var arrayEncodingStrategy: ArrayEncodingStrategy = .repeatKey

    public init() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        df.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormat = df
    }

    public func encode(_ encodable: Encodable) throws -> Data {
        return try encode(encodable).data(using: .utf8)!
    }

    public func encode(_ encodable: Encodable) throws -> String {
        let params: [URLQueryItem] = try self.encode(encodable)
        var str = params.reduce("") { $0 + "\( $1.name.urlEncoded() ?? "" )=\( $1.value?.urlEncoded() ?? "" )&" }
        if str.count > 0 { str.removeLast() }
        return str
    }

    public func encode(_ encodable: Encodable) throws -> [URLQueryItem] {
        try encodable.encode(to: self)
        return self.values
    }
}

extension URLParameterEncoder: Encoder{
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(URLParameterKeyedEncodingContainer(parent: self))
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return URLParameterUnkeyedEncodingContainer(parent: self)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        return URLParameterUnkeyedEncodingContainer(parent: self)
    }

    fileprivate func add(key: String, value: String?) {
        var str = self.codingPath.reduce("") { $0 + $1.stringValue + "." }
        if str.count > 0 { str.removeLast() }
        let k = str + key
        self.values.append(URLQueryItem(name: k, value: value))
    }
}
