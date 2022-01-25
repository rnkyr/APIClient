import Foundation
import Alamofire

open class AlamofireRequestExecutor: RequestExecutor {
    
    private let baseURL: URL
    private let session: Session
    
    public init(baseURL: URL, session: Session = Session.default) {
        self.baseURL = baseURL
        self.session = session
    }
    
    open func execute(request: APIRequest, requestModifier: RequestModifier?, completion: @escaping APIResultResponse) -> Cancelable {
        let cancellationSource = CancellationTokenSource()
        let requestPath = path(for: request)
        
        let afRequest = session.request(
            requestPath,
            method: request.afMethod,
            parameters: request.parameters,
            encoding: request.afEncoding,
            headers: request.afHeaders,
            requestModifier: { urlRequest in urlRequest = requestModifier?(urlRequest, request) ?? urlRequest }
        )
        cancellationSource.token.register {
            afRequest.cancel()
        }
        
        afRequest.response { (response: DataResponse<Data?, AFError>) in
            AlamofireRequestExecutor.handleResult(
                result: response.result,
                response: response.response,
                data: response.data,
                completion: completion
            )
        }
        
        return cancellationSource
    }
    
    open func execute(multipartRequest: MultipartAPIRequest, requestModifier: RequestModifier?, completion: @escaping APIResultResponse) -> Cancelable {
        let cancellationSource = CancellationTokenSource()
        let requestPath = path(for: multipartRequest)
        
        let request = session.upload(
            multipartFormData: multipartRequest.multipartFormData,
            to: requestPath,
            method: multipartRequest.afMethod,
            headers: multipartRequest.afHeaders,
            requestModifier: { urlRequest in urlRequest = requestModifier?(urlRequest, multipartRequest) ?? urlRequest }
        )
        cancellationSource.token.register {
            request.cancel()
        }
        if let progressHandler = multipartRequest.progressHandler {
            request.uploadProgress { (progress: Progress) in
                progressHandler(progress)
            }
        }
        
        request.responseJSON { (response: DataResponse<Any, AFError>) in
            AlamofireRequestExecutor.handleResult(
                result: response.result,
                response: response.response,
                data: response.data,
                completion: completion
            )
        }
        
        return cancellationSource
    }
    
    open func execute(uploadRequest: UploadAPIRequest, requestModifier: RequestModifier?, completion: @escaping APIResultResponse) -> Cancelable {
        let cancellationSource = CancellationTokenSource()
        let requestPath = path(for: uploadRequest)

        let request = session.upload(
            uploadRequest.fileURL,
            to: requestPath,
            method: uploadRequest.afMethod,
            headers: uploadRequest.afHeaders,
            requestModifier: { urlRequest in urlRequest = requestModifier?(urlRequest, uploadRequest) ?? urlRequest }
        )
        cancellationSource.token.register {
            request.cancel()
        }
        if let progressHandler = uploadRequest.progressHandler {
            request.uploadProgress { (progress: Progress) in
                progressHandler(progress)
            }
        }

        request.responseData { (response: DataResponse<Data, AFError>) in
            AlamofireRequestExecutor.handleResult(
                result: response.result,
                response: response.response,
                data: response.result.value,
                completion: completion
            )
        }

        return cancellationSource
    }
    
    open func execute(downloadRequest: DownloadAPIRequest, requestModifier: RequestModifier?, destinationPath: URL?, completion: @escaping APIResultResponse) -> Cancelable {
        let cancellationSource = CancellationTokenSource()
        let requestPath = path(for: downloadRequest)
        
        let request = session.download(
            requestPath,
            method: downloadRequest.afMethod,
            parameters: downloadRequest.parameters,
            encoding: downloadRequest.afEncoding,
            headers: downloadRequest.afHeaders,
            requestModifier: { urlRequest in urlRequest = requestModifier?(urlRequest, downloadRequest) ?? urlRequest },
            to: destination(for: destinationPath)
        )
        cancellationSource.token.register {
            request.cancel()
        }
        if let progressHandler = downloadRequest.progressHandler {
            request.downloadProgress { (progress: Progress) in
                progressHandler(progress)
            }
        }
        
        request.responseData { (response: DownloadResponse<Data, AFError>) in
            AlamofireRequestExecutor.handleResult(
                result: response.result,
                response: response.response,
                data: response.result.value,
                completion: completion
            )
        }
        
        return cancellationSource
    }
    
    private static func handleResult<T>(
        result: Result<T, AFError>,
        response: HTTPURLResponse?,
        data: Data?,
        completion: @escaping APIResultResponse
    ) {
        switch result {
        case .success:
            if let httpResponse = response {
                completion(Result.success((httpResponse, data ?? Data())))
            } else {
                completion(Result.failure(AlamofireRequestExecutor.defineError(
                    responseError: nil,
                    responseStatusCode: response?.statusCode
                )))
            }
            
        case .failure(let error):
            switch error {
            case .responseSerializationFailed(let reason):
                switch reason {
                case .inputDataNilOrZeroLength:
                    if let httpResponse = response {
                        completion(Result.success((httpResponse, data ?? Data())))
                    } else {
                        completion(Result.failure(AlamofireRequestExecutor.defineError(
                            responseError: error,
                            responseStatusCode: response?.statusCode
                        )))
                    }
                    return
                default: break
                }
            default: break
            }
            completion(Result.failure(
                AlamofireRequestExecutor.defineError(
                    responseError: error,
                    responseStatusCode: response?.statusCode
                )
            ))
        }
    }
    
    open func path(for request: APIRequest) -> String {
        return baseURL
            .appendingPathComponent(request.path)
            .absoluteString
            .removingPercentEncoding!
    }
    
    private func destination(for url: URL?) -> DownloadRequest.Destination? {
        guard let url = url else {
            return nil
        }
        
        let destination: DownloadRequest.Destination = { _, _ -> (URL, DownloadRequest.Options) in
            return (url, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        return destination
    }
    
    private static func defineError(responseError: AFError?, responseStatusCode: Int?) -> NetworkClientError {
        guard let error = responseError else {
            if let code = responseStatusCode, let definedError = NetworkClientError.define(code) {
                return definedError
            }
            
            return NetworkClientError.undefined(responseError)
        }
        
        if let definedError = NetworkClientError.define(error) {
           return definedError
        }
        
        return NetworkClientError.map(error)
    }
}

extension NetworkClientError {
    
    static func map(_ error: AFError) -> NetworkClientError {
        if let code = error.responseCode, let definedError = NetworkClientError.define(code) {
            return definedError
        }
        
        if let underlyingError = error.underlyingError, let definedError = NetworkClientError.define(underlyingError) {
            return definedError
        }
        
        switch error {
        case .explicitlyCancelled: return NetworkClientError.network(.canceled)
        case .responseSerializationFailed: return NetworkClientError.serialization(.parsing(error))
        case .responseValidationFailed(let reason):
            switch reason {
            case .unacceptableStatusCode(let code):
                if let definedError = NetworkClientError.define(code) {
                    return definedError
                }
            default: break
            }
            
        default: break
        }
        
        return NetworkClientError.executor(error)
    }
}

extension Alamofire.MultipartFormData: MultipartFormDataType {}
