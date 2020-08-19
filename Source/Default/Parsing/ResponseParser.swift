import Foundation

public protocol ResponseParser {
    
    associatedtype Representation
    
    func parse(_ object: AnyObject) -> Result<Representation, NetworkClientError.SerializationError>
    func parse(_ object: AnyObject, _ response: HTTPURLResponse) -> Result<Representation, NetworkClientError.SerializationError>
}

public extension ResponseParser {
    
    func parse(_ object: AnyObject, _ response: HTTPURLResponse) -> Result<Representation, NetworkClientError.SerializationError> {
        return parse(object)
    }
}

public struct EmptyParser: ResponseParser {
    
    public init() {}
    
    public func parse(_ object: AnyObject) -> Result<Bool, NetworkClientError.SerializationError> {
        return Result.success(true)
    }
}

public struct JSONParser: ResponseParser {

    public init() {}
    
    public func parse(_ object: AnyObject) -> Result<[String: AnyObject], NetworkClientError.SerializationError> {
        return Result.success(object as! [String: AnyObject])
    }
}
