import Foundation

/// Manages cancellation tokens and signals them when cancellation is requested.
///
/// All `CancellationTokenSource` methods are thread safe.
public final class CancellationTokenSource: Cancelable {
    
    /// Returns `true` if cancellation has been requested for this token.
    var isCancelling: Bool {
        _lock.lock(); defer { _lock.unlock() }
        return _observers == nil
    }
    
    /// Creates a new token associated with the source.
    public var token: CancellationToken { return CancellationToken(source: self) }
    
    private var _observers: Bag<() -> Void>? = Bag<() -> Void>()
    
    /// Initializes the `CancellationTokenSource` instance.
    public init() {}
    
    fileprivate func register(_ closure: @escaping () -> Void) {
        if !_register(closure) {
            closure()
        }
    }
    
    private func _register(_ closure: @escaping () -> Void) -> Bool {
        _lock.lock(); defer { _lock.unlock() }
        _observers?.insert(closure)
        return _observers != nil
    }
    
    /// Communicates a request for cancellation to the managed token.
    public func cancel() {
        if let observers = _cancel() {
            observers.forEach { $0() }
        }
    }
    
    private func _cancel() -> Bag<() -> Void>? {
        _lock.lock(); defer { _lock.unlock() }
        let observers = _observers
        _observers = nil // transition to `isCancelling` state
        return observers
    }
}

// We use the same lock across different tokens because the design of CTS
// prevents potential issues. For example, closures registered with a token
// are never executed inside a lock.
private let _lock = NSLock()

/// Enables cooperative cancellation of operations.
///
/// You create a cancellation token by instantiating a `CancellationTokenSource`
/// object and calling its `token` property. You then pass the token to any
/// number of threads, tasks, or operations that should receive notice of
/// cancellation. When the  owning object calls `cancel()`, the `isCancelling`
/// property on every copy of the cancellation token is set to `true`.
/// The registered objects can respond in whatever manner is appropriate.
///
/// All `CancellationToken` methods are thread safe.
public struct CancellationToken {
    
    fileprivate let source: CancellationTokenSource
    
    /// Returns `true` if cancellation has been requested for this token.
    public var isCancelling: Bool { return source.isCancelling }
    
    /// Registers the closure that will be called when the token is canceled.
    /// If this token is already cancelled, the closure will be run immediately
    /// and synchronously.
    /// - warning: Make sure that you don't capture token inside a closure to
    /// avoid retain cycles.
    public func register(closure: @escaping () -> Void) { source.register(closure) }
}

/// Lightweight data structure for storing small number of elements.
private struct Bag<T> {
    
    private var head: Node?
    
    private final class Node {
        let value: T
        var next: Node?
        init(_ value: T, next: Node? = nil ) {
            self.value = value; self.next = next
        }
    }
    
    mutating func insert(_ value: T) {
        guard let node = head else { self.head = Node(value); return }
        self.head = Node(value, next: node)
    }
    
    func forEach(_ closure: (T) -> Void) {
        var node = self.head
        while node != nil {
            closure(node!.value)
            node = node?.next
        }
    }
}
