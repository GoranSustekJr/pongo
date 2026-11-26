import Foundation

/// Runs [work] on each of [items], at most [width] at a time, and returns
/// once all are done.
///
/// Plain tasks that take the next item from a shared queue, instead of a
/// task group: on iOS 26 a group's tasks finishing while a playlist's
/// downloads were saved crashed the app inside Swift's task group code,
/// with none of the app's code on the stack.
public func concurrently<Item: Sendable>(
    _ items: [Item], width: Int, _ work: @escaping @Sendable (Item) async -> Void
) async {
    guard !items.isEmpty else { return }
    let queue = WorkQueue(items)
    let workers = (0..<min(max(width, 1), items.count)).map { _ in
        Task {
            while let item = await queue.take() { await work(item) }
        }
    }
    // Cancelling the caller stops the workers after the items they're on
    await withTaskCancellationHandler {
        for worker in workers { await worker.value }
    } onCancel: {
        Task { await queue.clear() }
    }
}

/// The items not handed out yet.
private actor WorkQueue<Item: Sendable> {
    private let items: [Item]
    private var next = 0

    init(_ items: [Item]) { self.items = items }

    func take() -> Item? {
        guard next < items.count else { return nil }
        defer { next += 1 }
        return items[next]
    }

    func clear() { next = items.count }
}
