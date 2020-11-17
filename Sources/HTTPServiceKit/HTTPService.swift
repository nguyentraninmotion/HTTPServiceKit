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

public typealias MultipartFormDataParam = (data: Data, withName: String, fileName: String?, mimeType: String?)
public typealias MultipartFormURLParam = (fileURL: URL, withName: String, fileName: String?, mimeType: String?)
public typealias MultipartFormStreamParam = (stream: InputStream, withLength: UInt64, name: String?, fileName: String?, mimeType: String?, headers: [String:String]?)

public protocol MultipartFormDataEncodable {
    func data() -> [MultipartFormDataParam]?
    func fileURL() -> [MultipartFormURLParam]?
    func stream() -> [MultipartFormStreamParam]?
}

public protocol HTTPServiceDecoder {
    func decode<T:Decodable>(value: Data) throws -> T
}

public protocol HTTPServiceLogger {
    func log(level: HTTPService.LogLevel, message: String, metadata: [String: String]?)
}

public extension HTTPServiceLogger {
    @inlinable
    func debug(_ message: String, metadata: [String: String]? = nil) {
        self.log(level: .debug, message: message, metadata: metadata)
    }
    
    @inlinable
    func error(_ error: Error, metadata: [String: String]? = nil) {
        self.log(level: .error, message: error.localizedDescription, metadata: metadata)
    }
}

public struct HTTPServiceConsoleLogger: HTTPServiceLogger {
    public init() {}

    public func log(level: HTTPService.LogLevel, message: String, metadata: [String : String]?) {
        let metadataStr = metadata?.map { "\($0) = \($1)" }.joined(separator: " ")
        print("[\(level)] - \(message)\(metadataStr != nil ? "\n\(metadataStr!)" : "")")
    }
}

extension JSONDecoder: HTTPServiceDecoder {
    public func decode<T:Decodable>(value: Data) throws -> T {
        return try self.decode(T.self, from: value)
    }
}

public extension Swift.Error {
    var networkError: URLError? {
        guard let err = self as? URLError else { return nil }

        switch err.code {
            case .unknown: break
            case .cancelled: break
            case .badURL: break
            case .timedOut: break
            case .unsupportedURL: break
            case .cannotFindHost: break
            case .cannotConnectToHost: break
            case .networkConnectionLost: break
            case .dnsLookupFailed: break
            case .httpTooManyRedirects: break
            case .resourceUnavailable: break
            case .notConnectedToInternet: break
            case .redirectToNonExistentLocation: break
            case .badServerResponse: break
            case .userCancelledAuthentication: break
            case .userAuthenticationRequired: break
            case .zeroByteResource: break
            case .cannotDecodeRawData: break
            case .cannotDecodeContentData: break
            case .cannotParseResponse: break
            case .appTransportSecurityRequiresSecureConnection: break
            case .fileDoesNotExist: break
            case .fileIsDirectory: break
            case .noPermissionsToReadFile: break
            case .dataLengthExceedsMaximum: break
            case .secureConnectionFailed: break
            case .serverCertificateHasBadDate: break
            case .serverCertificateUntrusted: break
            case .serverCertificateHasUnknownRoot: break
            case .serverCertificateNotYetValid: break
            case .clientCertificateRejected: break
            case .clientCertificateRequired: break
            case .cannotLoadFromNetwork: break
            case .cannotCreateFile: break
            case .cannotOpenFile: break
            case .cannotCloseFile: break
            case .cannotWriteToFile: break
            case .cannotRemoveFile: break
            case .cannotMoveFile: break
            case .downloadDecodingFailedMidStream: break
            case .downloadDecodingFailedToComplete: break
            case .internationalRoamingOff: break
            case .callIsActive: break
            case .dataNotAllowed: break
            case .requestBodyStreamExhausted: break
            case .backgroundSessionRequiresSharedContainer: break
            case .backgroundSessionInUseByAnotherProcess: break
            case .backgroundSessionWasDisconnected: break
            default: break
        }

        return err
    }
}

private extension HTTPURLResponse {
    var cacheable: Bool {
        if let cacheControl = self.allHeaderFields["Cache-Control"] as? String {
            let components = cacheControl.components(separatedBy: ",")
            return components.filter { $0.lowercased() == "no-cache" || $0.lowercased() == "no-store" }.first == nil
        }
        return true
    }

    func serviceError(data: Data?) -> HTTPService.Error? {
        guard let statusCode = HTTPService.StatusCode(rawValue: self.statusCode), !statusCode.isOk else { return nil }
        return HTTPService.Error.response(statusCode: statusCode, body: data, contentType: self.mimeType)
    }
}

open class HTTPService {
    public enum Error: Swift.Error {
        case generic
        case cacheNotFound
        case unrecognizedEncoding(String)
        case response(statusCode: StatusCode, body: Data?, contentType: String?)
    }

    public struct EmptyEncodable: Encodable {
        public func encode(to encoder: Encoder) throws {
        }
    }

    public enum UploadBody<T: Encodable> {
        case json(T, mimeType: String = MimeType.json.rawValue)
        case formUrlEncoded(T)
        case multipartForm(T)
        case binary(Data)
        case empty
    }

    public enum MimeType: String {
        case aac = "audio/aac" // AAC audio file
        case abw = "application/x-abiword" // AbiWord document
    //    case arc = "application/octet-stream" // Archive document (multiple files embedded)
        case avi = "video/x-msvideo" // AVI: Audio Video Interleave
        case azw = "application/vnd.amazon.ebook" // Amazon Kindle eBook format
        case bin = "application/octet-stream" // Any kind of binary data
        case bz = "application/x-bzip" // BZip archive
        case bz2 = "application/x-bzip2" // BZip2 archive
        case csh = "application/x-csh" // C-Shell script
        case css = "text/css" // Cascading Style Sheets (CSS)
        case csv = "text/csv" // Comma-separated values (CSV)
        case doc = "application/msword" // Microsoft Word
        case eot = "application/vnd.ms-fontobject" // MS Embedded OpenType fonts
        case epub = "application/epub+zip" // Electronic publication (EPUB)
        case gif = "image/gif" // Graphics Interchange Format (GIF)
        case html = "text/html" // HyperText Markup Language (HTML)
        case ico = "image/x-icon" // Icon format
        case ics = "text/calendar" // iCalendar format
        case jar = "application/java-archive" // Java Archive (JAR)
        case jpg = "image/jpeg" // JPEG images
        case js = "application/javascript" // JavaScript (ECMAScript)
        case json = "application/json" // JSON format
        case metaSig = "text/plain"
        case midi = "audio/midi" // Musical Instrument Digital Interface (MIDI)
        case mpeg = "video/mpeg" // MPEG Video
        case mpkg = "application/vnd.apple.installer+xml" // Apple Installer Package
        case odp = "application/vnd.oasis.opendocument.presentation" // OpenDocument presentation document
        case ods = "application/vnd.oasis.opendocument.spreadsheet" // OpenDocument spreadsheet document
        case odt = "application/vnd.oasis.opendocument.text" // OpenDocument text document
        case oga = "audio/ogg" // OGG audio
        case ogv = "video/ogg" // OGG video
        case ogx = "application/ogg" // OGG
        case otf = "font/otf" // OpenType font
        case png = "image/png" // Portable Network Graphics
        case pdf = "application/pdf" // Adobe Portable Document Format (PDF)
        case ppt = "application/vnd.ms-powerpoint" // Microsoft PowerPoint
        case rar = "application/x-rar-compressed" // RAR archive
        case rtf = "application/rtf" // Rich Text Format (RTF)
        case sh = "application/x-sh" // Bourne shell script
        case svg = "image/svg+xml" // Scalable Vector Graphics (SVG)
        case swf = "application/x-shockwave-flash" // Small web format (SWF) or Adobe Flash document
        case tar = "application/x-tar" // Tape Archive (TAR)
        case tiff = "image/tiff" // Tagged Image File Format (TIFF)
        case ts = "application/typescript" // Typescript file
        case ttf = "font/ttf" // TrueType Font
        case vsd = "application/vnd.visio" // Microsoft Visio
        case wav = "audio/x-wav" // Waveform Audio Format
        case weba = "audio/webm" // WEBM audio
        case webm = "video/webm" // WEBM video
        case webp = "image/webp" // WEBP image
        case woff = "font/woff" // Web Open Font Format (WOFF)
        case woff2 = "font/woff2" // Web Open Font Format (WOFF)
        case xhtml = "application/xhtml+xml" // XHTML
        case xls = "application/vnd.ms-excel" // Microsoft Excel
        case xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case xml = "application/xml" // XML
        case xul = "application/vnd.mozilla.xul+xml" // XUL
        case zip = "application/zip" // ZIP archive
        case multipart = "multipart/form-data"
        case xWWWFormUrlencoded = "application/x-www-form-urlencoded"
    }

    public enum StatusCode: Int {
        case `continue`                     = 100
        case switchingProtocol              = 101
        case ok                             = 200
        case created                        = 201
        case accepted                       = 202
        case nonAuthoritativeInformation    = 203
        case noContent                      = 204
        case resetContent                   = 205
        case partialContent                 = 206
        case multipleChoice                 = 300
        case movePermanently                = 301
        case found                          = 302
        case seeOther                       = 303
        case notModified                    = 304
        case useProxy                       = 305
        case unused                         = 306
        case temporaryRedirect              = 307
        case permanentRedirect              = 308
        case badRequest                     = 400
        case unauthorized                   = 401
        case paymentRequired                = 402
        case forbidden                      = 403
        case notFound                       = 404
        case methodNotAllowed               = 405
        case notAcceptable                  = 406
        case proxyAuthenticationRequired    = 407
        case requestTimeout                 = 408
        case conflict                       = 409
        case gone                           = 410
        case lengthRequired                 = 411
        case preconditionFailed             = 412
        case payloadTooLarge                = 413
        case uriTooLong                     = 414
        case unsupportedMediaType           = 415
        case requestedRangeNotSatisfiable   = 416
        case expectationFailed              = 417
        case misdirectedRequest             = 421
        case unprocessableEntity            = 422 // WebDAV
        case upgradeRequired                = 426
        case preconditionRequired           = 428
        case tooManyRequests                = 429
        case requestHeaderFieldsTooLarge    = 431
        case unavailableForLegalReasons     = 451
        case internalServerError            = 500
        case notImplemented                 = 501
        case badGateway                     = 502
        case serviceUnavailable             = 503
        case gatewayTimeout                 = 504
        case httpVersionNotSupported        = 505
        case variantAlsoNegotiates          = 506
        case variantAlsoNegotiatesNotProper = 507
        case networkAuthenticationRequired  = 511
        
        public var isOk: Bool {
            switch self {
                case .ok, .created, .accepted, .nonAuthoritativeInformation
                     , .noContent, .resetContent, .partialContent:
                    return true
                default:
                    return false
            }
        }
    }

    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case put = "PUT"
        case head = "HEAD"
        case delete = "DELETE"
        case options = "OPTIONS"
        case connect = "CONNECT"
    }

    public enum LogLevel: String, Codable, CaseIterable {
        case trace
        case debug
        case info
        case notice
        case warning
        case error
        case critical
    }

    public struct Config {
        public var baseUrl: URL?
        public var headers: HTTPService.Headers = [:]
        public var requestTimeoutInterval: TimeInterval = 30
        public var responseQueue: DispatchQueue? = nil
        public var decoders: DecoderRegistry = [
            "application/json": JSONDecoder()
        ]
        public var cacheStore: URLCache? = nil
        public var logger: HTTPServiceLogger? = HTTPServiceConsoleLogger()

        public init(baseUrl: URL?) {
            self.baseUrl = baseUrl
        }
    }

    public typealias Headers = [String:String]
    public typealias DecoderRegistry = [String:HTTPServiceDecoder]
    public typealias Result = (mimeType: String, body: Data)

    private let coder = JSONEncoder()
    private let session: URLSession
    private let config: Config
    private let contentTypeMapping: [String:String] = [
        "jpg": "image/jpg",
        "png": "image/png"
    ]

    public init(config: Config) {
        self.session = URLSession(configuration: .default)
        self.config = config
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSxxx"
        coder.dateEncodingStrategy = .formatted(formatter)
    }

    private func request(_ request: URLRequest, cacheCriteria: CacheCriteria? = nil) -> Promise<Result?> {
        let cacheStore = self.config.cacheStore
        let cacheable = (cacheCriteria != nil && cacheStore != nil)

        let cachedResult: Promise<Result?> = cacheable
            ? Promise().map(on: DispatchQueue.global()) {
                let cachedResponse: CachedURLResponse? = {
                    switch cacheCriteria?.policy {
                        case .some(.useAge):
                            return cacheStore?.cachedResponse(for: request, maxAge: cacheCriteria?.age ?? 0)
                        case .some(.returnCacheDataElseLoad):
                            return cacheStore?.cachedResponse(for: request)
                        default:
                            return nil
                    }
                }()

                // Make sure the cachedReponse is not an error response
                let httpResponse = cachedResponse?.response as? HTTPURLResponse
                if let _ = httpResponse?.serviceError(data: cachedResponse?.data) {
                    return nil
                }

                // Otherwise return the response data
                return cachedResponse.flatMap { (cachedResponse?.response.mimeType ?? "", $0.data) }
            }
            : Promise.value(nil)
        
        return cachedResult.then(on: DispatchQueue.global()) { result -> Promise<Result?> in
            guard result == nil else { return Promise.value(result) }

            return Promise { seal in
                if let logger = self.config.logger {
                    var metadata = [String:String]()
                    request.allHTTPHeaderFields?.forEach {
                        metadata["<\($0.key)>"] = "\($0.value)"
                    }
                    logger.debug("==========================================================")
                    logger.debug("HEADER", metadata: metadata)
                    logger.debug("REQUEST(\(request.httpMethod ?? "UNKNOWN"))",
                                      metadata: ["<Request>":"\(request.debugDescription)"])
                    if request.httpBody != nil {
                        logger.debug("",
                                      metadata: ["<Body>":"\(request.httpBody?.utf8String() ?? "")"])
                    }
                    logger.debug("==========================================================")
                }

                let task = self.session.dataTask(with: request) { data, resp, err in
                    let httpResponse = resp as? HTTPURLResponse

                    if let logger = self.config.logger {
                        logger.debug("==========================================================")
                        logger.debug("RESPONSE: HTTP STATUS: \(httpResponse?.statusCode ?? 0)")
                        logger.debug("RESPONSE MIMETYPE: \(resp?.mimeType ?? "")")
                        logger.debug("FOR REQUEST(\(request.httpMethod ?? "UNKNOWN"))",
                                          metadata: ["<Request>":"\(request.debugDescription)"])

                        if resp?.mimeType == "application/octet-stream" {
                            logger.debug("RESPONSE DATA == <Octet-Stream binay data>")
                        } else {
                            logger.debug("RESPONSE DATA", metadata: ["<Data>":"\(data?.utf8String() ?? "null")"])
                        }
                        logger.debug("==========================================================")
                    }

                    if let neterr = err?.networkError { return seal.reject(neterr) }
                    if let error = httpResponse?.serviceError(data: data) { return seal.reject(error) }

                    if cacheable && (httpResponse?.cacheable ?? false), data != nil {
                        let cachedResponse = CachedURLResponse(response: resp!, data: data!)
                        cacheStore?.storeCachedResponse(cachedResponse, for: request)
                    }
                    return seal.fulfill(data.flatMap{ (resp?.mimeType ?? "", $0) })
                }
                task.resume()
            }
            .recover { err -> Promise<Result?> in
                guard cacheable else { throw err }
                guard let serviceError = err as? HTTPService.Error else { throw err }
                switch serviceError {
                    case .response(let statusCode, _, _):
                        switch statusCode {
                            case .unauthorized, .gone, .notFound, .forbidden: throw err
                            default: break
                        }
                    default: throw err
                }

                let cachedResponse: CachedURLResponse? = {
                    switch cacheCriteria?.policy {
                        case .some(.reloadReturnCacheDataIfError), .some(.useAgeReturnCacheDataIfError):
                            return cacheStore?.cachedResponse(for: request);
                        case .some(.reloadReturnCacheDataWithAgeCheckIfError):
                            return cacheStore?.cachedResponse(for: request, maxAge: cacheCriteria!.age)
                        default:
                            return nil
                    }
                }()

                guard let resp = cachedResponse else { throw err }
                return Promise.value((resp.response.mimeType ?? "", resp.data))
            }
            .recover { error -> Promise<Result?> in
                if let logger = self.config.logger {
                    logger.error(error)
                }
                throw error
            }
        }
    }

    private func resolveRoute(_ route: String) -> URLComponents? {
        guard let baseUrl = self.config.baseUrl else {
            return URLComponents(string: route)
        }

        guard var comp = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true) else { return nil }
        guard !route.isEmpty else { return comp }

        if (comp.path.last == "/") {
            comp.path += (route.first == "/") ? route.dropFirst().description : route
            return comp
        }

        if (route.first != "/") {
            comp.path += "/"
        }
        comp.path += route
        return comp
    }

    public func upload<T>(method: Method, route: String, query: [URLQueryItem]?, body: UploadBody<T>) -> Promise<Result?> {
        guard var comps = self.resolveRoute(route) else { return Promise(error: Error.generic) }
        comps.queryItems = query
        guard let url = comps.url else { return Promise(error: Error.generic) }
        var request = URLRequest(url: url)
        request.timeoutInterval = self.config.requestTimeoutInterval
        request.httpMethod = method.rawValue

        do {
            var headers = self.config.headers
            var contentType: String? = nil
            var bodyData: Data? = nil

            switch body {
                case .json(let t, let mimeType):
                    bodyData = try coder.encode(t)
                    contentType = mimeType
                case .formUrlEncoded(let t):
                    bodyData = try URLParameterEncoder().encode(t).data(using: .utf8)
                    contentType = MimeType.xWWWFormUrlencoded.rawValue
                case .multipartForm(let t):
                    let form = MultipartFormEncoder()
                    form.contentTypes = self.contentTypeMapping
                    bodyData = try form.encode(t)
                    contentType = "\(MimeType.multipart.rawValue); boundary=\(form.boundry!)"
                case .binary(let t):
                    contentType = MimeType.bin.rawValue
                    bodyData = t
                case .empty:
                    contentType = MimeType.metaSig.rawValue // text/plain
                    bodyData = nil
            }

            headers["Content-Type"] = contentType
            request.allHTTPHeaderFields = headers
            request.httpBody = bodyData
        } catch (let err) {
            return Promise(error: err)
        }
        return self.request(request)
    }

    public func download(method: Method, route: String, query: [URLQueryItem]?, cacheCriteria: CacheCriteria? = nil) -> Promise<Result?> {
        guard var comps = self.resolveRoute(route) else { return Promise(error: Error.generic) }
        comps.queryItems = query
        guard let url = comps.url else { return Promise(error: Error.generic) }
        var request = URLRequest(url: url)
        request.timeoutInterval = self.config.requestTimeoutInterval
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = self.config.headers
        return self.request(request, cacheCriteria: cacheCriteria)
    }
}

private extension Promise where T == HTTPService.Result? {
    func decode<RT: Decodable & ExpressibleByNilLiteral>(_ decoders: HTTPService.DecoderRegistry, on: DispatchQueue? = nil) -> Promise<RT> {
        return self.map(on: on) { (result: T) -> RT in
            guard let result = result else { return nil }
            guard let decoder = decoders[result.mimeType] else { throw HTTPService.Error.unrecognizedEncoding(result.mimeType) }
            return try decoder.decode(value: result.body)
        }
    }

    func decode<RT: Decodable>(_ decoders: HTTPService.DecoderRegistry, on: DispatchQueue? = nil) -> Promise<RT> {
        return self.map(on: on) { (result: T) -> RT in
            guard let result = result else { throw HTTPService.Error.generic }
            guard let decoder = decoders[result.mimeType] else { throw HTTPService.Error.unrecognizedEncoding(result.mimeType) }
            return try decoder.decode(value: result.body)
        }
    }
}

// MARK: - HEAD
public extension HTTPService {
    func head(route: String) -> Promise<Void> {
        return self.download(method: .head, route: route, query: nil).asVoid()
    }
}

// MARK: - DELETE
public extension HTTPService {
    func delete(route: String) -> Promise<Void> {
        return self.download(method: .delete, route: route, query: nil).asVoid()
    }
    
    func delete(route: String, query: QueryParameters) -> Promise<Void> {
        return self.download(method: .delete,
                             route: route,
                             query: query.urlQueryItems ).asVoid()
    }
    
    func delete<T: Decodable>(route: String) -> Promise<T> where T: ExpressibleByNilLiteral {
        return self.download(method: .delete, route: route, query: nil)
                   .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func delete<T: Decodable>(route: String) -> Promise<T> {
        return self.download(method: .delete, route: route, query: nil)
                   .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func delete<T: Decodable>(route: String, query: QueryParameters) -> Promise<T> where T: ExpressibleByNilLiteral {
        return self.download(method: .delete,
                             route: route,
                             query: query.urlQueryItems )
                    .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func delete<T: Decodable>(route: String, query: QueryParameters) -> Promise<T> {
        return self.download(method: .delete,
                             route: route,
                             query: query.urlQueryItems )
                    .decode(self.config.decoders, on: self.config.responseQueue)
    }

}

// MARK: - OPTIONS
public extension HTTPService {
    func options(route: String) -> Promise<[Method]> {
        guard let comps = self.resolveRoute(route) else { return Promise(error: Error.generic) }
        guard let url = comps.url else { return Promise(error: Error.generic) }
        var request = URLRequest(url: url)
        request.timeoutInterval = self.config.requestTimeoutInterval
        request.httpMethod = Method.get.rawValue
        request.allHTTPHeaderFields = self.config.headers

        return Promise { seal in
            let task = self.session.dataTask(with: request) { data, resp, err in
                if let neterr = err?.networkError { return seal.reject(neterr) }
                if let r = resp as? HTTPURLResponse, let allow = (r.allHeaderFields["Allow"] as? String) {
                    let methods = allow.split(separator: ",").compactMap { Method(rawValue: $0.description) }
                    seal.fulfill(methods)
                } else {
                    seal.fulfill([])
                }
            }
            task.resume()
        }
    }
}

// MARK: - GET
public extension HTTPService {
    func get(route: String, query: QueryParameters, cacheCriteria: CacheCriteria? = nil) -> Promise<Result?> {
        return self.download(method: .get
                            , route: route
                            , query: query.urlQueryItems
                            , cacheCriteria: cacheCriteria)
    }

    func get<T:Decodable>(route: String, query: QueryParameters, cacheCriteria: CacheCriteria? = nil) -> Promise<T> where T: ExpressibleByNilLiteral {
        return self.download(method: .get
                            , route: route
                            , query: query.urlQueryItems
                            , cacheCriteria: cacheCriteria)
                    .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func get<T:Decodable>(route: String, query: QueryParameters, cacheCriteria: CacheCriteria? = nil) -> Promise<T> {
        return self.download(method: .get
                            , route: route
                            , query: query.urlQueryItems
                            , cacheCriteria: cacheCriteria)
                    .decode(self.config.decoders, on: self.config.responseQueue)
    }
}

// MARK: - POST
public extension HTTPService {
    func post<T>(route: String, body: UploadBody<T>) -> Promise<Result?> {
        return self.upload(method: .post, route: route, query: nil, body: body)
    }

    func post<T:Decodable, B>(route: String, body: UploadBody<B>) -> Promise<T> where T: ExpressibleByNilLiteral {
        return self.upload(method: .post, route: route, query: nil, body: body)
            .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func post<T:Decodable, B>(route: String, body: UploadBody<B>) -> Promise<T> {
        return self.upload(method: .post, route: route, query: nil, body: body)
            .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func post<B>(route: String, body: UploadBody<B>) -> Promise<Void> {
        return self.upload(method: .post, route: route, query: nil, body: body).asVoid()
    }
}

public extension HTTPService {
    func post(route: String, query: QueryParameters) -> Promise<Result?> {
        return self.upload(method: .post
                            , route: route
                            , query: query.urlQueryItems
                            , body: UploadBody<EmptyEncodable>.empty)
    }
    
    func post<T:Decodable>(route: String, query: QueryParameters) -> Promise<T> where T: ExpressibleByNilLiteral {
        return self.upload(method: .post
                            , route: route
                            , query: query.urlQueryItems
                            , body: UploadBody<EmptyEncodable>.empty)
                    .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func post<T:Decodable>(route: String, query: QueryParameters) -> Promise<T> {
        return self.upload(method: .post
                            , route: route
                            , query: query.urlQueryItems
                            , body: UploadBody<EmptyEncodable>.empty)
                    .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func post(route: String, query: QueryParameters) -> Promise<Void> {
        return self.upload(method: .post
                            , route: route
                            , query: query.urlQueryItems
                            , body: UploadBody<EmptyEncodable>.empty)
                    .asVoid()
    }
}

// MARK: - PATCH
public extension HTTPService {
    func patch<B>(route: String, body: UploadBody<B>) -> Promise<Void> {
        return self.upload(method: .patch, route: route, query: nil, body: body).asVoid()
    }
}

// MARK: - PUT
public extension HTTPService {
    func put<T>(route: String, query: QueryParameters? = nil, body: UploadBody<T>) -> Promise<Result?> {
        return self.upload(method: .put, route: route, query: query?.urlQueryItems, body: body)
    }

    func put<T:Decodable, B>(route: String, query: QueryParameters? = nil, body: UploadBody<B>) -> Promise<T> where T: ExpressibleByNilLiteral {
        return self.upload(method: .put, route: route, query: query?.urlQueryItems, body: body)
            .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func put<T:Decodable, B>(route: String, query: QueryParameters? = nil, body: UploadBody<B>) -> Promise<T> {
        return self.upload(method: .put, route: route, query: query?.urlQueryItems, body: body)
            .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func put<B>(route: String, query: QueryParameters? = nil, body: UploadBody<B>) -> Promise<Void> {
        return self.upload(method: .put, route: route, query: query?.urlQueryItems, body: body).asVoid()
    }
}

public extension HTTPService {
    func get(route: String, query: Encodable? = nil, cacheCriteria: CacheCriteria? = nil) -> Promise<Result?> {
        do {
            return self.download(method: .get
                                , route: route
                                , query: try query.flatMap { try URLParameterEncoder().encode($0) }
                                , cacheCriteria: cacheCriteria)
        } catch (let e) {
            return Promise(error: e)
        }
    }

    func get<T:Decodable>(route: String, query: Encodable? = nil, cacheCriteria: CacheCriteria? = nil) -> Promise<T> where T: ExpressibleByNilLiteral {
        return self.get(route: route, query: query, cacheCriteria: cacheCriteria)
                    .decode(self.config.decoders, on: self.config.responseQueue)
    }

    func get<T:Decodable>(route: String, query: Encodable? = nil, cacheCriteria: CacheCriteria? = nil) -> Promise<T> {
        return self.get(route: route, query: query, cacheCriteria: cacheCriteria)
                    .decode(self.config.decoders, on: self.config.responseQueue)
    }
}
