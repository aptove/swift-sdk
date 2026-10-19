import Foundation

// MARK: - V2MaybeUndefined

/// **UNSTABLE** - A three-state field for upsert payloads: absent, JSON `null`, or a value.
///
/// v2 upsert payloads (e.g. `V2ToolCallUpdate`, the message upserts) give optional fields
/// patch semantics: an omitted field leaves the existing value unchanged, `null` explicitly
/// clears it, and a concrete value replaces it. Swift's `T?` collapses the first two states,
/// so such fields are modeled with this type instead.
public enum V2MaybeUndefined<T> {
    /// The field is not present; an existing value is left unchanged.
    case undefined
    /// The field is present with a JSON `null` value; an existing value is cleared.
    case null
    /// The field is present with a non-null value; it replaces an existing value.
    case value(T)

    /// The contained value, or `nil` if the field is `undefined` or `null`.
    public func valueOrNull() -> T? {
        guard case .value(let v) = self else { return nil }
        return v
    }

    /// Transforms the contained value; `undefined` and `null` pass through unchanged.
    public func map<R>(_ transform: (T) -> R) -> V2MaybeUndefined<R> {
        switch self {
        case .value(let v): return .value(transform(v))
        case .undefined: return .undefined
        case .null: return .null
        }
    }

    /// This state unless it is `undefined`, in which case `other`.
    ///
    /// An explicit `null` is a present state and wins over `other`. Use `update(_:)` to
    /// collapse to a plain nullable.
    public func orElse(_ other: V2MaybeUndefined<T>) -> V2MaybeUndefined<T> {
        if case .undefined = self { return other }
        return self
    }

    /// Applies patch semantics to a previous value: `undefined` keeps `previous`, `null` clears
    /// it, and `value` replaces it.
    public func update(_ previous: T?) -> T? {
        switch self {
        case .value(let v): return v
        case .undefined: return previous
        case .null: return nil
        }
    }
}

extension V2MaybeUndefined: Equatable where T: Equatable {}
extension V2MaybeUndefined: Hashable where T: Hashable {}
extension V2MaybeUndefined: Sendable where T: Sendable {}

// MARK: - Internal JSON helpers

/// Decodes a tri-state field from a raw JSON object: absent → `.undefined`, JSON null → `.null`,
/// otherwise `.value(T)`. A present-but-malformed value degrades to `.undefined`.
internal func decodeMaybeUndefined<T: Decodable>(_ raw: [String: JsonValue], key: String) -> V2MaybeUndefined<T> {
    guard let jsonValue = raw[key] else { return .undefined }
    if case .null = jsonValue { return .null }
    guard let data = try? JSONEncoder().encode(jsonValue),
          let value = try? JSONDecoder().decode(T.self, from: data) else {
        return .undefined
    }
    return .value(value)
}

/// Decodes a tri-state list field with VecSkipError semantics: malformed items are skipped.
internal func decodeMaybeUndefinedList<T: Decodable>(_ raw: [String: JsonValue], key: String) -> V2MaybeUndefined<[T]> {
    guard let jsonValue = raw[key] else { return .undefined }
    if case .null = jsonValue { return .null }
    guard case .array(let items) = jsonValue else { return .undefined }
    let decoded = items.compactMap { item -> T? in
        guard let data = try? JSONEncoder().encode(item),
              let value = try? JSONDecoder().decode(T.self, from: data) else { return nil }
        return value
    }
    return .value(decoded)
}

/// Encodes a tri-state field into a keyed encoding container.
internal func encodeMaybeUndefined<T: Encodable, K: CodingKey>(
    _ value: V2MaybeUndefined<T>,
    forKey key: K,
    into container: inout KeyedEncodingContainer<K>
) throws {
    switch value {
    case .undefined: break
    case .null: try container.encodeNil(forKey: key)
    case .value(let v): try container.encode(v, forKey: key)
    }
}
