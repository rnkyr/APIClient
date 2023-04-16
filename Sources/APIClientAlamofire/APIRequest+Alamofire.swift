import Foundation
import Alamofire
import APIClient

public extension APIRequest {

    var afMethod: HTTPMethod {
        return HTTPMethod(rawValue: method.rawValue.uppercased())
    }
    
    var afHeaders: HTTPHeaders? {
        guard let headers = headers else {
            return nil
        }
        
        return HTTPHeaders(headers)
    }

    var afEncoding: ParameterEncoding {
        switch encoding {
        case .json: return Alamofire.JSONEncoding.default
        case .jsonPercentEncoding: return JSONPercentEncoding.default
        case .url: return Alamofire.URLEncoding.queryString
        }
    }
}
