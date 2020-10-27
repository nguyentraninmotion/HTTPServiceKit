/***************************************************************************
 * This source file is part of the HTTPServiceKit open source project.     *
 *                                                                         *
 * Copyright (c) 2020-present, InMotion Software and the project authors   *
 * Licensed under the MIT License                                          *
 *                                                                         *
 * See LICENSE.txt for license information                                 *
 ***************************************************************************/

import Foundation

public extension String {
    func urlEncoded() -> String? {
        let unreserved = "-._~"
        var allowed = NSCharacterSet.alphanumerics
        allowed.insert(charactersIn: unreserved)
        return self.addingPercentEncoding(withAllowedCharacters: allowed)
    }
}
