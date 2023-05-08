//
//  AuthorizationPlugin.swift
//  APIClient
//
//  Created by Roman Kyrylenko on 10/16/18.
//

import Foundation

public typealias AuthErrorResolving = (Error) -> Bool

/// This plugin provides support for requests' authorization through http headers. Works with `AuthorizableRequest`s only.
public final class AuthorizationPlugin: PluginType {
    
    /// The timespan used to cancel any executing request in case it previously failed authorization
    public static var requestsCancellingTimespan: TimeInterval = 1.0
    
    private let provider: AuthorizationCredentialsProvider
    private let authErrorResolving: AuthErrorResolving
    
    let shouldCancelRequestIfFailed: Bool
    
    weak var delegate: AuthorizationPluginDelegate?
    
    /// - Parameters:
    ///   - provider: An auth data provider used in order to authorize your requests
    ///   - shouldCancelRequestIfFailed: indicates whether APIClient should cancel request if authorization failed previously and it cannot restore it
    ///   - authErrorResolving: an optional callback that allows you to determine whether a given error is `unauthorized` one
    public init(
        provider: AuthorizationCredentialsProvider,
        shouldCancelRequestIfFailed: Bool = true,
        authErrorResolving: AuthErrorResolving? = nil
    ) {
        self.provider = provider
        self.shouldCancelRequestIfFailed = shouldCancelRequestIfFailed
        self.authErrorResolving = authErrorResolving ?? { error in
            if let error = (error as? NetworkClientError)?.underlyingError as? NetworkClientError.NetworkError,
                case .unauthorized = error {
                return true
            }
            
            return false
        }
    }
    
    public func canResolve(_ error: Error, _ request: APIRequest) -> Bool {
        if authErrorResolving(error) {
            delegate?.reachAuthorizationError()
            
            return false
        }
        
        return false
    }
    
    public func prepare(_ request: APIRequest, result: @escaping (APIRequest) -> Void) {
        guard let authorizableRequest = request as? AuthorizableRequest, authorizableRequest.authorizationRequired else {
            result(request)
            return
        }
        
        var headers = request.headers ?? [:]
        
        let prefix: String
        if let authPrefix = provider.authorizationType.valuePrefix, case .custom = provider.authorizationType {
            prefix = authPrefix
        } else if let authPrefix = provider.authorizationType.valuePrefix, !authPrefix.isEmpty {
            prefix = authPrefix + " "
        } else {
            prefix = ""
        }
        headers[provider.authorizationType.key] = prefix + provider.authorizationToken
        
        let proxy = request.proxy()
        proxy.headers = headers
        
        result(proxy)
    }
}

protocol AuthorizationPluginDelegate: AnyObject {
    
    func reachAuthorizationError()
}
