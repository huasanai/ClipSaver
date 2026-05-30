import AppKit
import ClipSaverCore
import Foundation

enum ClipboardReader {
    static func readPreferredContent(from pasteboard: NSPasteboard = .general) -> ClipboardContent? {
        if let urls = readFileURLs(from: pasteboard), !urls.isEmpty {
            return .fileURLs(urls)
        }

        if let data = pasteboard.data(forType: .png), !data.isEmpty {
            return .image(data: data, fileExtension: "png")
        }

        if let data = pasteboard.data(forType: .tiff), !data.isEmpty {
            return .image(data: data, fileExtension: "tiff")
        }

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return .text(text)
        }

        return nil
    }

    private static func readFileURLs(from pasteboard: NSPasteboard) -> [URL]? {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]

        guard pasteboard.canReadObject(forClasses: [NSURL.self], options: options) else {
            return nil
        }

        guard let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: options) else {
            return nil
        }

        return objects.compactMap { object in
            if let url = object as? URL, url.isFileURL {
                return url
            }

            if let url = object as? NSURL, (url as URL).isFileURL {
                return url as URL
            }

            return nil
        }
    }
}
