//
//  PluginType.swift
//  APIClient
//
//  Created by Roman Kyrylenko on 2/23/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation

/// Describes functions of the plugin for APIClient
public protocol PluginType {

    @available(*, deprecated, message: "Use prepare(_:result:) instead")
    func prepare(_ request: APIRequest)
    /// Called to modify a request before sending
    func prepare(_ request: APIRequest, result: @escaping (APIRequest) -> Void)
    
    /// Called immediately before a request is sent over the network.
    func willSend(_ request: APIRequest)
    
    /// Called for each prepared URLRequest so that callee can modify it
    func modify(_ request: URLRequest, apiRequest: APIRequest) -> URLRequest
    
    /// Called immediately after data received.
    func didReceive(response: APIClient.HTTPResponse?, request: APIRequest)
    
    func canResolve(_ error: Error, _ request: APIRequest) -> Bool
    
    func isResolvingInProgress(_ error: Error) -> Bool
    
    /// Called to resolve error in case it happened.
    func resolve(_ error: Error, onResolved: @escaping (Bool) -> Void)
    
    /// Called to provide error in case response isn't successful.
    func processError(_ response: APIClient.HTTPResponse) -> Error?
    
    /// Called to modify a result in case of success right before completion.
    func process<T>(_ result: T) -> T
    
    /// Called to provide custom error type in case response isn't successful.
    func decorate(_ error: Error) -> Error
}

public extension PluginType {
    
    func prepare(_ request: APIRequest) {
    }
    
    func prepare(_ request: APIRequest, result: @escaping (APIRequest) -> Void) {
        result(request)
    }
    
    func willSend(_ request: APIRequest) {
    }
    
    func modify(_ request: URLRequest, apiRequest: APIRequest) -> URLRequest {
        return request
    }
    
    func didReceive(response: APIClient.HTTPResponse?, request: APIRequest) {
    }
    
    func canResolve(_ error: Error, _ request: APIRequest) -> Bool {
        return false
    }
    
    func isResolvingInProgress(_ error: Error) -> Bool {
        return false
    }
    
    func resolve(_ error: Error, onResolved: @escaping (Bool) -> Void) {
        onResolved(false)
    }
    
    func processError(_ response: APIClient.HTTPResponse) -> Error? {
        return nil
    }
    
    func process<T>(_ result: T) -> T {
        return result
    }
    
    func decorate(_ error: Error) -> Error {
        return error
    }
}
