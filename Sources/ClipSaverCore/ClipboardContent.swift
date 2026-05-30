import Foundation

public enum ClipboardContent: Equatable, Sendable {
    case text(String)
    case image(data: Data, fileExtension: String)
    case fileURLs([URL])

    public var filenamePrefix: String {
        switch self {
        case .text:
            return "text"
        case .image:
            return "image"
        case .fileURLs:
            return "files"
        }
    }

    public var fileExtension: String {
        switch self {
        case .text, .fileURLs:
            return "md"
        case let .image(_, fileExtension):
            return fileExtension
        }
    }
}
