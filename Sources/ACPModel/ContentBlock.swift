import Foundation

/// Content blocks represent displayable information in the Agent Client Protocol.
///
/// They provide a structured way to handle various types of user-facing content—whether
/// it's text from language models, images for analysis, or embedded resources for context.
///
/// See protocol docs: [Content](https://agentclientprotocol.com/protocol/content)
public enum ContentBlock: Codable, Sendable, Hashable {
    /// Plain text content (all agents MUST support this)
    case text(TextContent)

    /// Images for visual context or analysis (requires image prompt capability)
    case image(ImageContent)

    /// Audio data for transcription or analysis (requires audio prompt capability)
    case audio(AudioContent)

    /// References to resources that the agent can access (all agents MUST support this)
    case resourceLink(ResourceLinkContent)

    /// Complete resource contents embedded directly (requires embeddedContext capability)
    case resource(ResourceContent)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type = "type"
    }

    private enum ContentType: String, Codable {
        case text = "text"
        case image = "image"
        case audio = "audio"
        case resourceLink = "resource_link"
        case resource = "resource"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)

        switch type {
        case .text:
            self = .text(try TextContent(from: decoder))
        case .image:
            self = .image(try ImageContent(from: decoder))
        case .audio:
            self = .audio(try AudioContent(from: decoder))
        case .resourceLink:
            self = .resourceLink(try ResourceLinkContent(from: decoder))
        case .resource:
            self = .resource(try ResourceContent(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let content):
            try content.encode(to: encoder)
        case .image(let content):
            try content.encode(to: encoder)
        case .audio(let content):
            try content.encode(to: encoder)
        case .resourceLink(let content):
            try content.encode(to: encoder)
        case .resource(let content):
            try content.encode(to: encoder)
        }
    }
}

/// Plain text content block.
///
/// All agents MUST support text content blocks in prompts.
public struct TextContent: Codable, Sendable, Hashable {
    /// The text content
    public let text: String

    /// Optional annotations
    public let annotations: Annotations?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates text content.
    public init(
        text: String,
        annotations: Annotations? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.text = text
        self.annotations = annotations
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case text = "text"
        case annotations = "annotations"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        annotations = try container.decodeIfPresent(Annotations.self, forKey: .annotations)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("text", forKey: .type)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(annotations, forKey: .annotations)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// Image content block.
///
/// Requires the `image` prompt capability when included in prompts.
public struct ImageContent: Codable, Sendable, Hashable {
    /// Base64-encoded image data
    public let data: String

    /// MIME type of the image
    public let mimeType: String

    /// Optional URI reference
    public let uri: String?

    /// Optional annotations
    public let annotations: Annotations?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates image content.
    public init(
        data: String,
        mimeType: String,
        uri: String? = nil,
        annotations: Annotations? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.data = data
        self.mimeType = mimeType
        self.uri = uri
        self.annotations = annotations
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case data = "data"
        case mimeType = "mimeType"
        case uri = "uri"
        case annotations = "annotations"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode(String.self, forKey: .data)
        mimeType = try container.decode(String.self, forKey: .mimeType)
        uri = try container.decodeIfPresent(String.self, forKey: .uri)
        annotations = try container.decodeIfPresent(Annotations.self, forKey: .annotations)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("image", forKey: .type)
        try container.encode(data, forKey: .data)
        try container.encode(mimeType, forKey: .mimeType)
        try container.encodeIfPresent(uri, forKey: .uri)
        try container.encodeIfPresent(annotations, forKey: .annotations)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// Audio content block.
///
/// Requires the `audio` prompt capability when included in prompts.
public struct AudioContent: Codable, Sendable, Hashable {
    /// Base64-encoded audio data
    public let data: String

    /// MIME type of the audio
    public let mimeType: String

    /// Optional annotations
    public let annotations: Annotations?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates audio content.
    public init(
        data: String,
        mimeType: String,
        annotations: Annotations? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.data = data
        self.mimeType = mimeType
        self.annotations = annotations
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case data = "data"
        case mimeType = "mimeType"
        case annotations = "annotations"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode(String.self, forKey: .data)
        mimeType = try container.decode(String.self, forKey: .mimeType)
        annotations = try container.decodeIfPresent(Annotations.self, forKey: .annotations)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("audio", forKey: .type)
        try container.encode(data, forKey: .data)
        try container.encode(mimeType, forKey: .mimeType)
        try container.encodeIfPresent(annotations, forKey: .annotations)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// Resource link content block.
///
/// References to resources that the agent can access. All agents MUST support this.
public struct ResourceLinkContent: Codable, Sendable, Hashable {
    /// Resource name
    public let name: String

    /// Resource URI
    public let uri: String

    /// Optional description
    public let description: String?

    /// Optional MIME type
    public let mimeType: String?

    /// Optional size in bytes
    public let size: Int?

    /// Optional human-readable title
    public let title: String?

    /// Optional annotations
    public let annotations: Annotations?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates resource link content.
    public init(
        name: String,
        uri: String,
        description: String? = nil,
        mimeType: String? = nil,
        size: Int? = nil,
        title: String? = nil,
        annotations: Annotations? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.name = name
        self.uri = uri
        self.description = description
        self.mimeType = mimeType
        self.size = size
        self.title = title
        self.annotations = annotations
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case name = "name"
        case uri = "uri"
        case description = "description"
        case mimeType = "mimeType"
        case size = "size"
        case title = "title"
        case annotations = "annotations"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        uri = try container.decode(String.self, forKey: .uri)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
        size = try container.decodeIfPresent(Int.self, forKey: .size)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        annotations = try container.decodeIfPresent(Annotations.self, forKey: .annotations)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("resource_link", forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(uri, forKey: .uri)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(mimeType, forKey: .mimeType)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(annotations, forKey: .annotations)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// Resource content block with embedded contents.
///
/// Requires the `embeddedContext` prompt capability when included in prompts.
public struct ResourceContent: Codable, Sendable, Hashable {
    /// The embedded resource
    public let resource: EmbeddedResource

    /// Optional annotations
    public let annotations: Annotations?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates resource content.
    public init(
        resource: EmbeddedResource,
        annotations: Annotations? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.resource = resource
        self.annotations = annotations
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case resource = "resource"
        case annotations = "annotations"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resource = try container.decode(EmbeddedResource.self, forKey: .resource)
        annotations = try container.decodeIfPresent(Annotations.self, forKey: .annotations)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("resource", forKey: .type)
        try container.encode(resource, forKey: .resource)
        try container.encodeIfPresent(annotations, forKey: .annotations)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// Resource content that can be embedded in a message.
public enum EmbeddedResource: Codable, Sendable, Hashable {
    /// Text-based resource contents
    case text(TextResourceContents)

    /// Binary resource contents
    case blob(BlobResourceContents)

    // MARK: - Codable
    // Note: This type uses field-based discrimination (no explicit "type" field required)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as TextResourceContents first (has "text" field)
        if let textContents = try? container.decode(TextResourceContents.self) {
            self = .text(textContents)
            return
        }

        // Try to decode as BlobResourceContents (has "blob" field)
        if let blobContents = try? container.decode(BlobResourceContents.self) {
            self = .blob(blobContents)
            return
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Cannot determine EmbeddedResource type; expected 'text' or 'blob' field"
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let contents):
            try container.encode(contents)
        case .blob(let contents):
            try container.encode(contents)
        }
    }
}

/// Text-based resource contents.
public struct TextResourceContents: Codable, Sendable, Hashable {
    /// The text content
    public let text: String

    /// Resource URI
    public let uri: String

    /// Optional MIME type
    public let mimeType: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates text resource contents.
    public init(
        text: String,
        uri: String,
        mimeType: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.text = text
        self.uri = uri
        self.mimeType = mimeType
        self._meta = _meta
    }
}

/// Binary resource contents.
public struct BlobResourceContents: Codable, Sendable, Hashable {
    /// Base64-encoded binary data
    public let blob: String

    /// Resource URI
    public let uri: String

    /// Optional MIME type
    public let mimeType: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates blob resource contents.
    public init(
        blob: String,
        uri: String,
        mimeType: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.blob = blob
        self.uri = uri
        self.mimeType = mimeType
        self._meta = _meta
    }
}
