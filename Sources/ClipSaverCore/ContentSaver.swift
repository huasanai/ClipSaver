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
        options: SaveOptions = SaveOptions()
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
        let destination = makeDestinationURL(for: content, in: directory)

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

    public func makeDestinationURL(for content: ClipboardContent, in directory: URL) -> URL {
        let filename = "\(content.filenamePrefix)_\(timestampProvider.timestamp()).\(content.fileExtension)"
        return directory.appendingPathComponent(filename, isDirectory: false)
    }

    public static func markdownForFileURLs(_ urls: [URL]) -> String {
        urls
            .map { "- \($0.path)" }
            .joined(separator: "\n")
    }
}
