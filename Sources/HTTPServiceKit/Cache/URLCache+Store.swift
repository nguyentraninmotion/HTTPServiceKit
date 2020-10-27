/***************************************************************************
 * This source file is part of the HTTPServiceKit open source project.     *
 *                                                                         *
 * Copyright (c) 2020-present, InMotion Software and the project authors   *
 * Licensed under the MIT License                                          *
 *                                                                         *
 * See LICENSE.txt for license information                                 *
 ***************************************************************************/

import Foundation

public extension URLCache {

    private static var dateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss 'GMT'"
        return formatter
    }()

    func cachedResponse(for request: URLRequest, maxAge age: CacheAgeInterval) -> CachedURLResponse? {
        var cachedResponse = self.cachedResponse(for: request)
        guard cachedResponse != nil else { return cachedResponse }

        if age < CacheAge.immortal.interval,
            let httpResponse = cachedResponse?.response as? HTTPURLResponse,
            let dateHeader = httpResponse.allHeaderFields["Date"] as? String,
            let cachedDate = URLCache.dateFormatter.date(from: dateHeader) {

            let ellapsedInterval = Date().timeIntervalSince1970 - cachedDate.timeIntervalSince1970
            if ellapsedInterval > Double(age) {
                cachedResponse = nil
            }
        }
        return cachedResponse
    }

}
