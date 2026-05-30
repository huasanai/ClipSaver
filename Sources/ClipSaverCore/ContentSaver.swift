import Foundation

public enum SaveOutcome: Equatable, Sendable {
    case saved(URL)
    case skippedExisting(URL)
    case skippedEmptyContent
}

public enum ContentSaverError: Error, Equatable, Sendable {
    case disabledContentType
    case invalidSaveDirectory
}

public struct SaveOptions: Equatable, Sendable {
    public var saveText: Bool
    public var saveImages: Bool
    public var saveFiles: Bool

    public init(saveText: Bool = true, saveImages: Bool = true, saveFiles: Bool = true) {
        self.saveText = saveText
        self.saveImages = saveImages
        self.saveFiles = saveFiles
    }

    public func allows(_ content: ClipboardContent) -> Bool {
        switch content {
        case .text:
            return saveText
        case .image:
            return saveImages
        case .fileURLs:
            return saveFiles
        }
    }
}

public final class ContentSaver {
    private let fileManager: FileManager
    private let timestampProvider: TimestampProviding

    public init(
        fileManager: FileManager = .default,
        timestampProvider: TimestampProviding = SystemTimestampProvider()
    ) {
        self.fileManager = fileManager
        self.timestampProvider = timestampProvider
    }

    @discardableResult
    public func save(
        _ content: ClipboardContent,
        to directory: URL,
        options: SaveOptions = SaveOptions(),
        naming: FileNamingOptions = FileNamingOptions(),
        explicitFilename: String? = nil
    ) throws -> SaveOutcome {
        guard options.allows(content) else {
            throw ContentSaverError.disabledContentType
        }

        guard !directory.path.isEmpty else {
            throw ContentSaverError.invalidSaveDirectory
        }

        switch content {
        case let .text(text):
            guard !text.isEmpty else {
                return .skippedEmptyContent
            }

        case let .image(data, _):
            guard !data.isEmpty else {
                return .skippedEmptyContent
            }

        case let .fileURLs(urls):
            guard !urls.isEmpty else {
                return .skippedEmptyContent
            }
        }

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination: URL

        if let explicitFilename {
            destination = directory.appendingPathComponent(
                Self.normalizedFilename(explicitFilename, defaultExtension: content.fileExtension),
                isDirectory: false
            )
        } else {
            destination = makeDestinationURL(for: content, in: directory, naming: naming)
        }

        guard !fileManager.fileExists(atPath: destination.path) else {
            return .skippedExisting(destination)
        }

        switch content {
        case let .text(text):
            try text.write(to: destination, atomically: true, encoding: .utf8)

        case let .image(data, _):
            try data.write(to: destination, options: .atomic)

        case let .fileURLs(urls):
            let markdown = Self.markdownForFileURLs(urls)
            try markdown.write(to: destination, atomically: true, encoding: .utf8)
        }

        return .saved(destination)
    }

    public func makeDestinationURL(
        for content: ClipboardContent,
        in directory: URL,
        naming: FileNamingOptions = FileNamingOptions()
    ) -> URL {
        let filename = makeFilename(for: content, naming: naming)
        return directory.appendingPathComponent(filename, isDirectory: false)
    }

    public func makeFilename(
        for content: ClipboardContent,
        naming: FileNamingOptions = FileNamingOptions()
    ) -> String {
        let timestamp = timestampProvider.timestamp()

        switch naming.strategy {
        case .automatic, .askEveryTime:
            return "\(content.filenamePrefix)_\(timestamp).\(content.fileExtension)"

        case .customFormat:
            let baseName = Self.renderFormat(
                naming.customFormat,
                content: content,
                timestamp: timestamp
            )
            return Self.normalizedFilename(baseName, defaultExtension: content.fileExtension)
        }
    }

    public static func markdownForFileURLs(_ urls: [URL]) -> String {
        urls
            .map { "- \($0.path)" }
            .joined(separator: "\n")
    }

    public static func renderFormat(
        _ format: String,
        content: ClipboardContent,
        timestamp: String
    ) -> String {
        let trimmedFormat = format.trimmingCharacters(in: .whitespacesAndNewlines)
        let template = trimmedFormat.isEmpty ? "{type}_{timestamp}" : trimmedFormat
        let parts = timestamp.split(separator: "-").map(String.init)
        let date = parts.first ?? timestamp
        let time = parts.dropFirst().first ?? timestamp

        return template
            .replacingOccurrences(of: "{type}", with: content.filenamePrefix)
            .replacingOccurrences(of: "{timestamp}", with: timestamp)
            .replacingOccurrences(of: "{date}", with: date)
            .replacingOccurrences(of: "{time}", with: time)
            .replacingOccurrences(of: "{uuid}", with: UUID().uuidString)
    }

    public static func normalizedFilename(
        _ filename: String,
        defaultExtension: String
    ) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\\n\r\t")
        let components = filename
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: invalidCharacters)
        let sanitized = components
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: ". "))

        let fallback = sanitized.isEmpty ? "clip" : sanitized

        if fallback.lowercased().hasSuffix(".\(defaultExtension.lowercased())") {
            return fallback
        }

        return "\(fallback).\(defaultExtension)"
    }
}
