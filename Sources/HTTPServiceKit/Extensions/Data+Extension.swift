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

public extension Data {
    init(randomBytes: Int) {
        guard randomBytes > 0 else { self.init(); return }
        self.init(count: randomBytes)
        self.withUnsafeMutableBytes { bytes in
            guard let bytes = bytes.bindMemory(to: UInt8.self).baseAddress else { return }
            arc4random_buf(bytes, randomBytes)
        }
    }
}

public extension Data {
    func writeAsync(on: DispatchQueue = .main, to: URL, options: Data.WritingOptions = []) -> Promise<Void> {
        return Promise().map(on: on){
            try self.write(to: to, options:  options)
        }
    }
}

public extension Data {
    func print() {
        let len = self.count
        self.withUnsafeBytes { bytes -> Void in
            guard let bytes = bytes.bindMemory(to: UInt8.self).baseAddress else { return }
            for i in 0..<len {
                let ch = Character.init(UnicodeScalar(bytes[i]))
                Swift.print(ch, terminator:"")
            }
        }
        Swift.print()
    }
}

public extension Data {
    private static let hexToChar: [Character] = {
        return ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    }()

    private static func charToHex(_ ch: Character) -> UInt8? {
        switch ch {
            case "0": return 0x0
            case "1": return 0x1
            case "2": return 0x2
            case "3": return 0x3
            case "4": return 0x4
            case "5": return 0x5
            case "6": return 0x6
            case "7": return 0x7
            case "8": return 0x8
            case "9": return 0x9
            case "A", "a": return 0xA
            case "B", "b": return 0xB
            case "C", "c": return 0xC
            case "D", "d": return 0xD
            case "E", "e": return 0xE
            case "F", "f": return 0xF
            default: return nil
        }
    }

    init?(hexEncoded: String) {
        let count = hexEncoded.count
        // must have even number of characters
        guard (count & 0x1) == 0 else { return nil }

        let capacity = count >> 1
        var data = Data(capacity: capacity)

        let chars = hexEncoded
        var idx = chars.startIndex
        let end = chars.endIndex
        while idx != end {
            guard let upper = Data.charToHex(chars[idx]) else { return nil }
            idx = chars.index(after: idx)
            guard let lower = Data.charToHex(chars[idx]) else { return nil }
            idx = chars.index(after: idx)
            let byte = ((upper&0xF) << 4) | (lower & 0xF)
            data.append(byte)
        }
        self = data
    }

    func hexEncodedString() -> String {
        let hex = Data.hexToChar
        var chars = [Character]()
        self.withUnsafeBytes { ptr -> Void in
            guard let ptr = ptr.bindMemory(to: UInt8.self).baseAddress else { return }
            let buffer = UnsafeBufferPointer(start: ptr, count: self.count)
            buffer.forEach { byte in
                chars.append(hex[Int((byte >> 4) & 0xF)])
                chars.append(hex[Int(byte & 0xF)])
            }
        }
        return String(chars)
    }
    
    func utf8String() -> String? {
        return String(data: self, encoding: .utf8)
    }
}
