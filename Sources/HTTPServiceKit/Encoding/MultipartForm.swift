/***************************************************************************
 * This source file is part of the HTTPServiceKit open source project.     *
 *                                                                         *
 * Copyright (c) 2020-present, InMotion Software and the project authors   *
 * Licensed under the MIT License                                          *
 *                                                                         *
 * See LICENSE.txt for license information                                 *
 ***************************************************************************/

import Foundation

public enum MultipartField {
    case field(value: String, name: String)
    case data(data: Data, name: String, filename: String?, mimeType: String)
    case file(path: URL, name: String)
    case mixed(MultipartMixed)
}

public struct MultipartMixed {
    typealias Content = (data: Data, file: String, mimeType: String)
    private var content: [Content]
    private let name: String

    public init(name: String) {
        self.name = name
        self.content = []
    }

    public mutating func add(data: Data, file: String, mimeType: String) {
        self.content.append((data: data, file: file, mimeType: mimeType))
    }

    public func encode() throws -> Data {
        let datum = self.content.map {
            return """
            Content-Disposition: file; file="\($0.file)"\r
            Content-Type: \($0.mimeType)\r
            \r
            """.data(using: .utf8)! + $0.data
        }

        let boundary = "httpservicekit.mixed.boundary~\( Data(randomBytes: 12).base64EncodedString() )"
        let sep = "--\(boundary)".data(using: .utf8)!
        let newline = "\r\n".data(using: .utf8)!

        return """
        Content-Disposition: form/data; name="\(self.name)"\r
        Content-Type: multipart/mixed; boundary=\(boundary)\r
        \r
        """.data(using: .utf8)! + datum.reduce(sep) { $0 + newline + $1 + newline + sep }
    }
}

public struct MultipartForm {
    private var fields: [MultipartField] = []
    private(set) var boundary: String? = nil
    var contentTypeMapping: [String:String] = [:]

    public init() {}

    private func contentType(ext: String) -> String {
        if let type = self.contentTypeMapping[ext] { return type }
        if let type = HTTPService.MimeType(rawValue: ext) { return type.rawValue }
        return "application/\(ext)"
    }

    public mutating func add(value: String, name: String) {
        fields.append(.field(value: value, name: name))
    }

    public mutating func add(data: Data, name: String, filename: String?, mimeType: String) {
        fields.append(.data(data: data, name: name, filename: filename, mimeType: mimeType))
    }

    public mutating func add(fileURL: URL, name: String) {
        fields.append(.file(path: fileURL, name: name))
    }

    public mutating func add(mixed: MultipartMixed) {
        fields.append(.mixed(mixed))
    }

    public mutating func encode() throws -> Data {
        let crlf = "\r\n"
        let datum: [Data] = try self.fields.map {
            switch $0 {
                case .field(let val, let name):
                    return """
                    Content-Disposition: form-data; name="\(name)"\r
                    \r
                    \(val)
                    """.data(using: .utf8)!
                case .data(let data, let name, let filename, let type):
                    let file = filename == nil ? "" : "; filename=\"\(filename!)\""
                    let rtn = "Content-Disposition: form-data; name=\"\(name)\"\(file)\(crlf)Content-Type: \(type)\(crlf)\(crlf)".data(using: .utf8)! + data
                    return rtn
                case .file(let url, let name):
                    return """
                    Content-Disposition: form-data; name="\(name)"; filename="\(url.lastPathComponent)"\r
                    Content-Type: \(self.contentType(ext: url.pathExtension))\r
                    \r
                    """.data(using: .utf8)! + (try Data(contentsOf: url))
                case .mixed(let multipart):
                    return try multipart.encode()
            }
        }

        var boundary: String? = nil
        repeat {
            let val = "httpservicekit.multipart.boundary~\( Data(randomBytes: 12).base64EncodedString() )"
            let data = val.data(using: .utf8)!
            let collision = datum.first(where: { !($0.range(of: data)?.isEmpty ?? true) })
            if collision == nil { boundary = val }
        } while (boundary == nil)

        self.boundary = boundary

        let sep = "--\(boundary!)".data(using: .utf8)!
        let newline = "\r\n".data(using: .utf8)!
        let rtn = datum.reduce(sep) {  $0 + newline + $1 + newline + sep }
        return rtn + "--\r\n".data(using: .utf8)!
    }
}
