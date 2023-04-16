//
//  APIRequestProxy.swift
//  APIClient
//
//  Created by Roman Kyrylenko on 3/6/17.
//
//

import Foundation

extension APIRequest {
    
    func proxy() -> APIRequestProxy {
        return APIRequestProxy.proxy(for: self)
    }
}

open class APIRequestProxy: APIRequest {
    
    public let origin: APIRequest
    public var path: String
    public var method: APIRequestMethod
    public var encoding: APIRequestEncoding
    public var parameters: [String: Any]?
    public var headers: [String: String]?
    
    public static func proxy(for request: APIRequest) -> APIRequestProxy {
        switch request {
        case let proxy as APIRequestProxy: return proxy
        case is MultipartAPIRequest: return MultipartAPIRequestProxy(request: request)
        case is DownloadAPIRequest: return DownloadAPIRequestProxy(request: request)
        case is UploadAPIRequest: return UploadAPIRequestProxy(request: request)
        default: return APIRequestProxy(request: request)
        }
    }
    
    public init(request: APIRequest) {
        if let proxy = request as? APIRequestProxy {
            origin = proxy.origin
        } else {
            origin = request
        }
        path = request.path
        method = request.method
        encoding = request.encoding
        parameters = request.parameters
        headers = request.headers
    }
}

open class MultipartAPIRequestProxy: APIRequestProxy, MultipartAPIRequest {
    
    public var progressHandler: ProgressHandler?
    public var multipartFormData: ((MultipartFormDataType) -> Void)
    
    public override init(request: APIRequest) {
        multipartFormData = (request as? MultipartAPIRequest)?.multipartFormData ?? { _ in }
        progressHandler = (request as? MultipartAPIRequest)?.progressHandler
        
        super.init(request: request)
    }
}

open class UploadAPIRequestProxy: APIRequestProxy, UploadAPIRequest {
    
    public var fileURL: URL
    public var progressHandler: ProgressHandler?
    
    public override init(request: APIRequest) {
        progressHandler = (request as? UploadAPIRequest)?.progressHandler
        fileURL = (request as? UploadAPIRequest)?.fileURL ?? URL(fileURLWithPath: "")
        
        super.init(request: request)
    }
}

open class DownloadAPIRequestProxy: APIRequestProxy, DownloadAPIRequest {
    
    public var progressHandler: ProgressHandler?
    public var destinationFilePath: URL?
    
    public override init(request: APIRequest) {
        destinationFilePath = (request as? DownloadAPIRequest)?.destinationFilePath
        progressHandler = (request as? DownloadAPIRequest)?.progressHandler
        
        super.init(request: request)
    }
}
