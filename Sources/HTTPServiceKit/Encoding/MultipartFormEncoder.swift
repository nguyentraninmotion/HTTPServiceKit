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

struct MultipartFormUnkeyedEncodingContainer: UnkeyedEncodingContainer, SingleValueEncodingContainer {

    private let parent: MultipartFormEncoder
    fileprivate(set) public var codingPath: [CodingKey] = []
    private(set) public var count: Int = 0

    init(parent: MultipartFormEncoder) {
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

    mutating func add(_ value: String) {
        self.parent.add(key: self.makeKey(), value: value)
        self.count += 1
    }

    mutating func add(_ value: Data, filename: String, mimeType: String) {
        self.parent.add(key: self.makeKey(), value: value, filename: filename, mimeType: mimeType)
        self.count += 1
    }

    mutating func encode(_ value: Int) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: Int8) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: Int16) throws { self.add(String(describing: value)) }
    mutating func encode(_ value: Int32) throws {self.add(String(describing: value))}
    mutating func encode(_ value: Int64) throws {self.add(String(describing: value))}
    mutating func encode(_ value: UInt) throws {self.add(String(describing: value))}
    mutating func encode(_ value: UInt8) throws {self.add(String(describing: value))}
    mutating func encode(_ value: UInt16) throws {self.add(String(describing: value))}
    mutating func encode(_ value: UInt32) throws {self.add(String(describing: value))}
    mutating func encode(_ value: UInt64) throws {self.add(String(describing: value))}
    mutating func encode(_ value: Float) throws {self.add(String(describing: value))}
    mutating func encode(_ value: Double) throws {self.add(String(describing: value))}
    mutating func encode(_ value: String) throws {self.add(String(describing: value))}
    mutating func encode(_ value: Bool) throws {self.add(value ? "true" : "false")}
    mutating func encodeNil() throws {self.add("")}
    mutating func encode(_ value: Data) throws { self.add(value, filename: "", mimeType: HTTPService.MimeType.bin.rawValue) }
    mutating func encode(_ value: Date) throws { try self.encode(self.parent.dateFormat.string(from: value)) }

    mutating func encode(_ value: URL) throws {
        try self.parent.add(key: self.makeKey(), value: value)
    }

    mutating func encode<T>(_ value: T) throws where T : Encodable {
        switch (value) {
            case is Date: try self.encode(value as! Date)
            case is Data: try self.encode(value as! Data)
            case is URL: try self.encode(value as! URL)
            default:
                try value.encode(to: self.parent)
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedEncodingContainer(MultipartFormKeyedEncodingContainer<NestedKey>(parent: self.parent))
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return MultipartFormUnkeyedEncodingContainer(parent: self.parent)
    }

    mutating func superEncoder() -> Encoder { return self.parent }
}

struct MultipartFormKeyedEncodingContainer<K:CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K

    fileprivate(set) public var codingPath: [CodingKey]
    private let parent: MultipartFormEncoder

    init(parent: MultipartFormEncoder) {
        self.parent = parent
        self.codingPath = parent.codingPath
    }

    private mutating func add(key: K, value: Data, filename: String, mimeType: String) {
        var str = key.stringValue
        if self.codingPath.count > 0 { str = "." + str }
        self.parent.add(key: str, value: value, filename: filename, mimeType: mimeType)
    }

    private mutating func add(key: K, value: String?) {
        self.parent.add(key: key.stringValue, value: value ?? "")
    }
    private mutating func add(key: K, value: String) {self.add(key: key, value: Optional.some(value))}
    mutating func encodeNil(forKey key: K) throws {self.add(key: key, value: "")}
    mutating func encode(_ value: Bool, forKey key: K) throws {self.add(key: key, value: value ? "true" : "false")}
    mutating func encode(_ value: Int, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: Int8, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: Int16, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: Int32, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: Int64, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: UInt, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: UInt8, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: UInt16, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: UInt32, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: UInt64, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: Float, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: Double, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: String, forKey key: K) throws {self.add(key: key, value: String(describing: value))}
    mutating func encode(_ value: Data, forKey key: K) throws { self.add(key: key, value: value, filename: "", mimeType: HTTPService.MimeType.bin.rawValue) }
    mutating func encode(_ value: Date, forKey key: K) throws { try self.encode(self.parent.dateFormat.string(from: value), forKey: key) }

    mutating func encode(_ value: URL, forKey key: K) throws {
        let data = try Data.init(contentsOf: value)
        self.add(key: key, value: data, filename: value.lastPathComponent, mimeType: value.pathExtension)
    }

    mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        switch (value) {
            case is Date: try self.encode(value as! Date, forKey: key)
            case is Data: try self.encode(value as! Data, forKey: key)
            case is URL: try self.encode(value as! URL, forKey: key)
            default:
                self.parent.codingPath.append(key)
                try value.encode(to: self.parent)
                self.parent.codingPath.removeLast()
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedEncodingContainer(MultipartFormKeyedEncodingContainer<NestedKey>(parent: self.parent))
    }

    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return MultipartFormUnkeyedEncodingContainer(parent: self.parent)
    }

    mutating func superEncoder() -> Encoder {
        return self.parent
    }

    mutating func superEncoder(forKey key: K) -> Encoder {
        return self.parent
    }
}

public class MultipartFormEncoder {
    enum ArrayEncodingStrategy {
        case repeatKey
        case bracketsWithIndex
        case brackets
    }

    var contentTypes: [String:String] = [:]

    fileprivate(set) public var codingPath: [CodingKey] = []
    fileprivate var form: MultipartForm
    private(set) public var userInfo: [CodingUserInfoKey : Any] = [:]

    var dateFormat: DateFormatter
    var arrayEncodingStrategy: ArrayEncodingStrategy = .repeatKey
    public var boundry: String? { return self.form.boundary }

    public init() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        df.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormat = df
        self.form = MultipartForm()
    }

    public func encode(_ encodable: Encodable) throws -> Data {
        if let photoData = encodable as? MultipartFormDataEncodable {
            for item in photoData.data()! {
                self.form.add(data: item.data, name: item.withName, filename: item.fileName, mimeType: item.mimeType!)
            }
        } else {
            try encodable.encode(to: self)
        }
        return try self.form.encode()
    }
}

extension MultipartFormEncoder: Encoder{
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(MultipartFormKeyedEncodingContainer(parent: self))
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return MultipartFormUnkeyedEncodingContainer(parent: self)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        return MultipartFormUnkeyedEncodingContainer(parent: self)
    }

    fileprivate func add(key: String, value: Data?, filename: String? = nil, mimeType: String? = nil) {
        var str = self.codingPath.reduce("") { $0 + $1.stringValue + "." }
        if str.count > 0 { str.removeLast() }

        var contentType: String? = mimeType
        if let type = mimeType {
            let str = self.contentTypes[type] ?? type
            contentType = str
        }
        self.form.add(data: value ?? Data(), name: str + key, filename: filename, mimeType: contentType ?? HTTPService.MimeType.bin.rawValue)
    }

    private func prefix(_ key: String) -> String {
        var str = self.codingPath.reduce("") { $0 + $1.stringValue + "." }
        if str.count > 0 { str.removeLast() }
        return str + key
    }

    fileprivate func add(key: String, value: URL) throws {
        self.form.add(fileURL: value, name: prefix(key))
    }

    fileprivate func add(key: String, value: String) {
        self.form.add(value: value, name: prefix(key))
    }
}
