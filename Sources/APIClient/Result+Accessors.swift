extension Result {
    
    public var value: Success? {
        switch self {
        case .success(let result): return result
        case .failure: return nil
        }
    }
    
    public var error: Failure? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}
