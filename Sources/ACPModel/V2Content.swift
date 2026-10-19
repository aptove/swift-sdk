import Foundation

// MARK: - V2IconTheme

/// **UNSTABLE** - Theme an icon is designed for.
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2IconTheme: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.rawValue = try c.decode(String.self)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }

    public static let light = V2IconTheme(rawValue: "light")
    public static let dark = V2IconTheme(rawValue: "dark")
}

// MARK: - V2Icon

/// **UNSTABLE** - A sized icon that the client can display in a user interface.
public struct V2Icon: Codable, Sendable, Hashable {
    public let src: String
    public let mimeType: String?
    public let sizes: [String]?
    public let theme: V2IconTheme?

    public init(src: String, mimeType: String? = nil, sizes: [String]? = nil, theme: V2IconTheme? = nil) {
        self.src = src
        self.mimeType = mimeType
        self.sizes = sizes
        self.theme = theme
    }
}

// MARK: - V2Annotations

/// **UNSTABLE** - Optional annotations for the client.
public struct V2Annotations: Codable, Sendable, Hashable {
    public let audience: [V2Role]?
    public let priority: Double?
    public let lastModified: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        audience: [V2Role]? = nil,
        priority: Double? = nil,
        lastModified: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.audience = audience
        self.priority = priority
        self.lastModified = lastModified
        self._meta = _meta
    }
}

// MARK: - V2EmbeddedResourceResource

/// **UNSTABLE** - Resource content that can be embedded in a message.
///
/// Discriminated by shape: payload with `text` → text-based, `blob` → binary.
public enum V2EmbeddedResourceResource: Codable, Sendable, Hashable {
    case text(TextResourceContents)
    case blob(BlobResourceContents)

    public struct TextResourceContents: Codable, Sendable, Hashable {
        public let text: String
        public let uri: String
        public let mimeType: String?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(text: String, uri: String, mimeType: String? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.text = text
            self.uri = uri
            self.mimeType = mimeType
            self._meta = _meta
        }
    }

    public struct BlobResourceContents: Codable, Sendable, Hashable {
        public let blob: String
        public let uri: String
        public let mimeType: String?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(blob: String, uri: String, mimeType: String? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.blob = blob
            self.uri = uri
            self.mimeType = mimeType
            self._meta = _meta
        }
    }

    private struct ShapeKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ShapeKey.self)
        if container.allKeys.contains(where: { $0.stringValue == "text" }) {
            self = .text(try TextResourceContents(from: decoder))
        } else if container.allKeys.contains(where: { $0.stringValue == "blob" }) {
            self = .blob(try BlobResourceContents(from: decoder))
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: ShapeKey(stringValue: "text/blob"),
                in: container,
                debugDescription: "EmbeddedResourceResource requires 'text' or 'blob' field"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let r): try r.encode(to: encoder)
        case .blob(let r): try r.encode(to: encoder)
        }
    }
}

// MARK: - V2ContentBlock

/// **UNSTABLE** - Content blocks for the v2 protocol.
///
/// Open tagged union discriminated by `type`. Unknown types preserve the raw JSON.
public enum V2ContentBlock: Codable, Sendable, Hashable {
    case text(Text)
    case image(Image)
    case audio(Audio)
    case resourceLink(ResourceLink)
    case resource(Resource)
    case unknown(type: String, rawJson: [String: JsonValue])

    // MARK: Nested types

    public struct Text: Codable, Sendable, Hashable {
        public let text: String
        public let annotations: V2Annotations?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(text: String, annotations: V2Annotations? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.text = text
            self.annotations = annotations
            self._meta = _meta
        }
    }

    public struct Image: Codable, Sendable, Hashable {
        public let data: String
        public let mimeType: String
        public let uri: String?
        public let annotations: V2Annotations?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(data: String, mimeType: String, uri: String? = nil, annotations: V2Annotations? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.data = data
            self.mimeType = mimeType
            self.uri = uri
            self.annotations = annotations
            self._meta = _meta
        }
    }

    public struct Audio: Codable, Sendable, Hashable {
        public let data: String
        public let mimeType: String
        public let annotations: V2Annotations?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(data: String, mimeType: String, annotations: V2Annotations? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.data = data
            self.mimeType = mimeType
            self.annotations = annotations
            self._meta = _meta
        }
    }

    public struct ResourceLink: Codable, Sendable, Hashable {
        public let name: String
        public let uri: String
        public let description: String?
        public let mimeType: String?
        public let size: Int64?
        public let title: String?
        public let icons: [V2Icon]?
        public let annotations: V2Annotations?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(
            name: String,
            uri: String,
            description: String? = nil,
            mimeType: String? = nil,
            size: Int64? = nil,
            title: String? = nil,
            icons: [V2Icon]? = nil,
            annotations: V2Annotations? = nil,
            _meta: MetaField? = nil // swiftlint:disable:this identifier_name
        ) {
            self.name = name
            self.uri = uri
            self.description = description
            self.mimeType = mimeType
            self.size = size
            self.title = title
            self.icons = icons
            self.annotations = annotations
            self._meta = _meta
        }
    }

    public struct Resource: Codable, Sendable, Hashable {
        public let resource: V2EmbeddedResourceResource
        public let annotations: V2Annotations?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(resource: V2EmbeddedResourceResource, annotations: V2Annotations? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.resource = resource
            self.annotations = annotations
            self._meta = _meta
        }
    }

    // MARK: Codable

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decode(String.self, forKey: .type)
        switch typeStr {
        case "text":
            self = .text(try Text(from: decoder))
        case "image":
            self = .image(try Image(from: decoder))
        case "audio":
            self = .audio(try Audio(from: decoder))
        case "resource_link":
            self = .resourceLink(try ResourceLink(from: decoder))
        case "resource":
            self = .resource(try Resource(from: decoder))
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(type: typeStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var typeContainer = encoder.container(keyedBy: TypeKey.self)
        switch self {
        case .text(let v):
            try typeContainer.encode("text", forKey: .type)
            try v.encode(to: encoder)
        case .image(let v):
            try typeContainer.encode("image", forKey: .type)
            try v.encode(to: encoder)
        case .audio(let v):
            try typeContainer.encode("audio", forKey: .type)
            try v.encode(to: encoder)
        case .resourceLink(let v):
            try typeContainer.encode("resource_link", forKey: .type)
            try v.encode(to: encoder)
        case .resource(let v):
            try typeContainer.encode("resource", forKey: .type)
            try v.encode(to: encoder)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}
