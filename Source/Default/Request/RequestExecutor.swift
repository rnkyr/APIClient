import Foundation

public typealias APIResultResponse = (Result<APIClient.HTTPResponse, NetworkClientError>) -> Void
public typealias RequestModifier = (URLRequest) -> URLRequest

public protocol RequestExecutor {
    
    func execute(request: APIRequest, requestModifier: RequestModifier?, completion: @escaping APIResultResponse) -> Cancelable
    func execute(multipartRequest: MultipartAPIRequest, requestModifier: RequestModifier?, completion: @escaping APIResultResponse) -> Cancelable
    func execute(downloadRequest: DownloadAPIRequest, requestModifier: RequestModifier?, destinationPath: URL?, completion: @escaping APIResultResponse) -> Cancelable
    func execute(uploadRequest: UploadAPIRequest, requestModifier: RequestModifier?, completion: @escaping APIResultResponse) -> Cancelable
}
