//
//  RestorationTokenPlugin.swift
//  APIClient
//
//  Created by Vodolazkyi Anton on 9/24/18.
//

import Foundation

public protocol TokenType {
    
    var accessToken: String { get }
    var exchangeToken: String { get }
}

public enum RestorationTokenPluginError: Error {
    
    case restorationResult(NetworkClientError)
    case exchangeTokenMissing
    case restorationResultProviderMissing
}

/// The plugin to restore the token can be used as the requestor's credential provider
public class RestorationTokenPlugin: PluginType {
    
    /// callback that provides result of request made to restore the session; captured
    public var restorationResultProvider: ((@escaping (Response<TokenType>) -> Void) -> Void)?
    
    let shouldHaltRequestsTillResolve: Bool
    weak var delegate: RestorationTokenPluginDelegate?
    
    private var inProgress = false
    private let credentialProvider: AccessCredentialsProvider
    private let authErrorResolving: AuthErrorResolving

    /// - Parameters:
    ///   - credentialProvider: an access credentials provider that provides all required data to restore token; captured
    ///   - shouldHaltRequestsTillResolve: indicates whether APIClient should halt all passing requests in case one of them failed with `unathorized` error and restart them
    ///                                    works only with `AuthorizableRequest`s
    ///   - authErrorResolving: an optional callback that allows you to determine whether a given error is `unauthorized` one
    public init(
        credentialProvider: AccessCredentialsProvider,
        shouldHaltRequestsTillResolve: Bool = true,
        authErrorResolving: AuthErrorResolving? = nil
    ) {
        self.credentialProvider = credentialProvider
        self.shouldHaltRequestsTillResolve = shouldHaltRequestsTillResolve
        self.authErrorResolving = authErrorResolving ?? { error in
            if let error = (error as? NetworkClientError)?.underlyingError as? NetworkClientError.NetworkError,
                case .unauthorized = error {
                return true
            }
            
            return false
        }
    }
    
    public func canResolve(_ error: Error, _ request: APIRequest) -> Bool {
        guard request.isAuthorizableRequest() else {
            return false
        }
        
        if authErrorResolving(error), inProgress == false {
            delegate?.reachUnauthorizedError()
            return true
        }
        return false
    }
    
    public func isResolvingInProgress(_ error: Error) -> Bool {
        return authErrorResolving(error) && inProgress == true
    }

    public func resolve(_ error: Error, onResolved: @escaping (Bool) -> Void) {
        guard authErrorResolving(error) else {
            delegate?.failedToRestore()
            onResolved(false)
            return
        }

        guard credentialProvider.exchangeToken != nil && restorationResultProvider != nil else {
            credentialProvider.invalidate(
                error: credentialProvider.exchangeToken == nil ? .exchangeTokenMissing : .restorationResultProviderMissing
            )
            delegate?.failedToRestore()
            onResolved(false)
            return
        }
 
        inProgress = true
        restorationResultProvider? { [weak self] result in
            self?.inProgress = false

            switch result {
            case .success(let value):
                self?.credentialProvider.commitCredentialsUpdate { provider in
                    provider.accessToken = value.accessToken
                    provider.exchangeToken = value.exchangeToken
                    self?.delegate?.restored()
                    onResolved(true)
                }
                
            case .failure(let error):
                self?.credentialProvider.invalidate(error: .restorationResult(error))
                self?.delegate?.failedToRestore()
                onResolved(false)
            }
        }
    }
}

protocol RestorationTokenPluginDelegate: AnyObject {
    
    func reachUnauthorizedError()
    func restored()
    func failedToRestore()
}

extension APIRequest {
    
    func isAuthorizableRequest() -> Bool {
        let request = (self as? APIRequestProxy)?.origin ?? self
        guard let authRequest = request as? AuthorizableRequest, authRequest.authorizationRequired else {
            return false
        }
        
        return true
    }
}
