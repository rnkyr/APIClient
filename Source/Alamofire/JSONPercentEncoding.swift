import Foundation
import Alamofire

/// Uses `jsonPercentEncoded` to create a JSON representation of the parameters object, which is set as the body of the
/// request. The `Content-Type` HTTP header field of an encoded request is set to `application/json`.
public struct JSONPercentEncoding: ParameterEncoding {
    
    // MARK: Properties
    
    /// Returns a `JSONPercentEncoding` instance.
    public static var `default`: JSONPercentEncoding { JSONPercentEncoding() }
    
    // MARK: Encoding
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        guard let parameters = parameters else { return urlRequest }
        urlRequest.httpBody = parameters.jsonPercentEncoded()
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return urlRequest
    }
}

private extension Dictionary {
    
    func jsonPercentEncoded() -> Data? {
        let jsonString = map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            return "\"\(escapedKey)\":\"\(escapedValue)\""
        }
        .joined(separator: ",")
        
        return "{\(jsonString)}".data(using: .utf8)
    }
}
