import Foundation

/// Sending and receiving on a WebSocket, safe when the system calls back
/// more than once.
///
/// The `async` `send` and `receive` Swift makes from the completion handler
/// versions resume an unchecked continuation each time the handler runs. A
/// socket whose connection fails or is torn down while a call waits can call
/// it twice, and the second resume corrupts whatever task the memory belongs
/// to by then, which crashes the app later in Swift's task code. These take
/// the first answer only.
extension URLSessionWebSocketTask {
    func receiveOnce() async throws -> Message {
        let once = Once()
        return try await withCheckedThrowingContinuation { continuation in
            receive { result in
                guard once.claim() else { return }
                continuation.resume(with: result)
            }
        }
    }

    func sendOnce(_ message: Message) async throws {
        let once = Once()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            send(message) { error in
                guard once.claim() else { return }
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
    }
}

/// True the first time only, from any thread.
final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false

    func claim() -> Bool {
        lock.withLock {
            defer { done = true }
            return !done
        }
    }
}
