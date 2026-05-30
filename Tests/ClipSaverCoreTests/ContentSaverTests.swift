import Foundation
import XCTest
@testable import ClipSaverCore

final class ContentSaverTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipSaverTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
    }

    func testTextSaveWritesMarkdownFile() throws {
        let saver = ContentSaver(timestampProvider: FixedTimestampProvider("20260531-010203-004"))

        let outcome = try saver.save(.text("hello\nworld"), to: temporaryDirectory)

        let expectedURL = temporaryDirectory.appendingPathComponent("text_20260531-010203-004.md")
        XCTAssertEqual(outcome, .saved(expectedURL))
        XCTAssertEqual(try String(contentsOf: expectedURL, encoding: .utf8), "hello\nworld")
    }

    func testImageSaveWritesOriginalDataWithExtension() throws {
        let saver = ContentSaver(timestampProvider: FixedTimestampProvider("20260531-010203-004"))
        let data = Data([0x89, 0x50, 0x4E, 0x47])

        let outcome = try saver.save(.image(data: data, fileExtension: "png"), to: temporaryDirectory)

        let expectedURL = temporaryDirectory.appendingPathComponent("image_20260531-010203-004.png")
        XCTAssertEqual(outcome, .saved(expectedURL))
        XCTAssertEqual(try Data(contentsOf: expectedURL), data)
    }

    func testFileURLsSaveAsMarkdownPathList() throws {
        let saver = ContentSaver(timestampProvider: FixedTimestampProvider("20260531-010203-004"))
        let urls = [
            URL(fileURLWithPath: "/Users/yangfan/Documents/Test File.md"),
            URL(fileURLWithPath: "/Users/yangfan/Documents/测试文件夹", isDirectory: true)
        ]

        let outcome = try saver.save(.fileURLs(urls), to: temporaryDirectory)

        let expectedURL = temporaryDirectory.appendingPathComponent("files_20260531-010203-004.md")
        XCTAssertEqual(outcome, .saved(expectedURL))
        XCTAssertEqual(
            try String(contentsOf: expectedURL, encoding: .utf8),
            "- /Users/yangfan/Documents/Test File.md\n- /Users/yangfan/Documents/测试文件夹"
        )
    }

    func testExistingFileIsSkipped() throws {
        let saver = ContentSaver(timestampProvider: FixedTimestampProvider("20260531-010203-004"))
        let expectedURL = temporaryDirectory.appendingPathComponent("text_20260531-010203-004.md")
        try "original".write(to: expectedURL, atomically: true, encoding: .utf8)

        let outcome = try saver.save(.text("replacement"), to: temporaryDirectory)

        XCTAssertEqual(outcome, .skippedExisting(expectedURL))
        XCTAssertEqual(try String(contentsOf: expectedURL, encoding: .utf8), "original")
    }

    func testDisabledTypeThrows() throws {
        let saver = ContentSaver(timestampProvider: FixedTimestampProvider("20260531-010203-004"))

        XCTAssertThrowsError(
            try saver.save(.text("hello"), to: temporaryDirectory, options: SaveOptions(saveText: false))
        ) { error in
            XCTAssertEqual(error as? ContentSaverError, .disabledContentType)
        }
    }

    func testEmptyContentIsSkipped() throws {
        let saver = ContentSaver(timestampProvider: FixedTimestampProvider("20260531-010203-004"))

        let outcome = try saver.save(.text(""), to: temporaryDirectory)

        XCTAssertEqual(outcome, .skippedEmptyContent)
    }
}
