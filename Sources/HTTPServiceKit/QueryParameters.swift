/***************************************************************************
 * This source file is part of the HTTPServiceKit open source project.     *
 *                                                                         *
 * Copyright (c) 2020-present, InMotion Software and the project authors   *
 * Licensed under the MIT License                                          *
 *                                                                         *
 * See LICENSE.txt for license information                                 *
 ***************************************************************************/

import Foundation

///
/// Infix operator to return a tuple of 2 items
///
/// `let t = "a" --> "b"`
///
infix operator -->
public func --> <A, B> (left: A, right: B) -> (A, B) { return (left, right) }

public func queryParams(_ pairs: (String, String)...) -> QueryParameters {
    pairs.reduce(QueryParameters(), { qp, pair in
        qp.addQueryParameter(name: pair.0, value: pair.1)
        return qp
    })
}

public func queryParamsMultiValue(_ pairs: (String, [String])...) -> QueryParameters {
    pairs.reduce(QueryParameters(), { qp, pair in
        qp.addQueryParameters(name: pair.0, values: pair.1)
        return qp
    })
}

public class QueryParameters {

    private var fields: [String: [String]] = [:]

    public var urlQueryItems: [URLQueryItem] {
        if self.fields.isEmpty { return [] }
        return fields.reduce([URLQueryItem](), { items, field in
            var newItems = [URLQueryItem](items)
            newItems.append(contentsOf: field.value.map { URLQueryItem(name: field.key, value: $0) })
            return newItems
        })
    }

    public var isEmpty: Bool { return self.fields.isEmpty }

    public init() { }

    public func addQueryParameter(name: String, value: String) {
        var fieldValues = (self.fields[name] ?? [])
        fieldValues.append(value)
        self.fields[name] = fieldValues
    }

    public func addQueryParameters(name: String, values: [String]) {
        var fieldValues = (self.fields[name] ?? [])
        fieldValues.append(contentsOf: values)
        self.fields[name] = fieldValues
    }
    
}
