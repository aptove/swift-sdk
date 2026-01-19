import Foundation

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Protocol for requests that support cursor-based pagination.
///
/// Paginated requests include an optional cursor that identifies the position
/// in the result set to continue from.
public protocol AcpPaginatedRequest: AcpRequest {
    /// The cursor for pagination.
    ///
    /// - `nil` for the first page
    /// - A value from a previous response's `nextCursor` for subsequent pages
    var cursor: Cursor? { get }
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Protocol for responses from paginated requests.
///
/// Paginated responses include a batch of items and optionally a cursor
/// for retrieving the next batch.
public protocol AcpPaginatedResponse: AcpResponse {
    /// The type of items in the response
    associatedtype Item

    /// The cursor for the next page of results.
    ///
    /// - `nil` indicates no more results are available
    /// - A value should be passed to the next request's `cursor` parameter
    var nextCursor: Cursor? { get }

    /// Returns the batch of items from this response.
    ///
    /// - Returns: Array of items in this page
    func getItemsBatch() -> [Item]
}
