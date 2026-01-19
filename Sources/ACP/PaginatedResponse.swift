import ACPModel
import Foundation

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// An AsyncSequence that lazily fetches paginated responses.
///
/// Converts cursor-based pagination into a convenient AsyncSequence that
/// automatically fetches subsequent pages as items are consumed.
///
/// ## Usage
///
/// ```swift
/// let items = PaginatedAsyncSequence { cursor in
///     let response = try await client.listSessions(cursor: cursor)
///     return (response.sessions, response.nextCursor)
/// }
///
/// for try await session in items {
///     print(session.sessionId)
/// }
/// ```
public struct PaginatedAsyncSequence<Item: Sendable>: AsyncSequence, Sendable {
    public typealias Element = Item

    private let batchFetcher: @Sendable (Cursor?) async throws -> (items: [Item], nextCursor: Cursor?)

    /// Creates a paginated async sequence.
    ///
    /// - Parameter batchFetcher: A closure that fetches a batch of items.
    ///   Takes an optional cursor (nil for first page) and returns
    ///   the items and next cursor (nil if no more pages).
    public init(
        batchFetcher: @escaping @Sendable (Cursor?) async throws -> (items: [Item], nextCursor: Cursor?)
    ) {
        self.batchFetcher = batchFetcher
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(batchFetcher: batchFetcher)
    }

    /// The iterator that fetches pages on demand.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private let batchFetcher: @Sendable (Cursor?) async throws -> (items: [Item], nextCursor: Cursor?)
        private var currentBatch: [Item] = []
        private var currentIndex: Int = 0
        private var nextCursor: Cursor?
        private var isFirstFetch: Bool = true
        private var isExhausted: Bool = false

        init(batchFetcher: @escaping @Sendable (Cursor?) async throws -> (items: [Item], nextCursor: Cursor?)) {
            self.batchFetcher = batchFetcher
        }

        public mutating func next() async throws -> Item? {
            // Return next item from current batch if available
            if currentIndex < currentBatch.count {
                let item = currentBatch[currentIndex]
                currentIndex += 1
                return item
            }

            // Check if we've exhausted all pages
            if isExhausted {
                return nil
            }

            // Need to fetch more - only if first fetch or we have a cursor
            guard isFirstFetch || nextCursor != nil else {
                isExhausted = true
                return nil
            }

            // Fetch next batch
            let cursor = isFirstFetch ? nil : nextCursor
            isFirstFetch = false

            let result = try await batchFetcher(cursor)
            currentBatch = result.items
            currentIndex = 0
            nextCursor = result.nextCursor

            // Mark exhausted if no more pages after this
            if nextCursor == nil && currentBatch.isEmpty {
                isExhausted = true
            }

            // Return first item of new batch if available
            if currentIndex < currentBatch.count {
                let item = currentBatch[currentIndex]
                currentIndex += 1
                return item
            }

            // Empty batch with no more pages
            isExhausted = true
            return nil
        }
    }
}

// MARK: - Protocol Extension

extension Protocol {
    /// **UNSTABLE**
    ///
    /// This capability is not part of the spec yet, and may be removed or changed at any point.
    ///
    /// Sends a paginated request and returns an AsyncSequence of items.
    ///
    /// Automatically handles pagination by fetching subsequent pages as
    /// items are consumed from the sequence.
    ///
    /// - Parameters:
    ///   - method: The method name to call
    ///   - requestFactory: Closure that creates a request for each page
    ///   - responseHandler: Closure that extracts items and next cursor from response
    /// - Returns: AsyncSequence of items across all pages
    public func sendPaginatedRequest<Request: Encodable, Response: Decodable, Item: Sendable>(
        method: String,
        requestFactory: @escaping @Sendable (Cursor?) -> Request,
        responseHandler: @escaping @Sendable (Response) -> (items: [Item], nextCursor: Cursor?)
    ) -> PaginatedAsyncSequence<Item> {
        PaginatedAsyncSequence { [self] cursor in
            let request = requestFactory(cursor)
            let jsonRpcResponse = try await self.sendRequest(method: method, params: request)

            // Decode the result to the expected response type
            let data = try JSONEncoder().encode(jsonRpcResponse.result)
            let response = try JSONDecoder().decode(Response.self, from: data)

            return responseHandler(response)
        }
    }
}
