/***************************************************************************
 * This source file is part of the HTTPServiceKit open source project.     *
 *                                                                         *
 * Copyright (c) 2020-present, InMotion Software and the project authors   *
 * Licensed under the MIT License                                          *
 *                                                                         *
 * See LICENSE.txt for license information                                 *
 ***************************************************************************/

import Foundation

public typealias CacheAgeInterval = Int

public enum CacheAge {
    case now
    case oneMinute
    case oneHour
    case oneDay
    case immortal

    public var interval: CacheAgeInterval {
        switch self {
            case .now       : return 0
            case .oneMinute : return 60
            case .oneHour   : return 60 * 60
            case .oneDay    : return 60 * 60 * 24
            case .immortal  : return Int.max
        }
    }
}

public enum CachePolicy {
    case useAge
    case useAgeReturnCacheDataIfError
    case returnCacheDataElseLoad
    case reloadReturnCacheDataIfError
    case reloadReturnCacheDataWithAgeCheckIfError
}

open class CacheCriteria {
    public var policy: CachePolicy
    public var age: CacheAgeInterval
    
    public init(policy: CachePolicy, age: CacheAgeInterval) {
        self.policy = policy
        self.age = age
    }
}
