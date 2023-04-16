//
//  KeyPathParser.swift
//  APIClient
//
//  Created by Vodolazkyi Anton on 9/19/18.
//

import Foundation

internal typealias JSON = [String: Any]

public enum ParserError: Error {
    
    case keyNotFound
    case objectIsNull
}

open class KeyPathParser {
    
    private let keyPath: String?
    
    public init(keyPath: String? = nil) {
        self.keyPath = keyPath
    }
    
    func valueForKeyPath(in object: Any) throws -> Any {
        guard !(object is NSNull) else {
            throw ParserError.objectIsNull
        }
        if let keyPath = keyPath, let dictionary = object as? JSON {
            if let value = dictionary[keyPath] {
                return value
            }
            throw ParserError.keyNotFound
        } else {
            return object
        }
    }
}
