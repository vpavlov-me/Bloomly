import SnapshotTesting
import SwiftUI
import XCTest
@testable import DesignSystem

final class ButtonStyleSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
    }

    func testPrimaryButton() throws {
        let view = Button("Continue") {}
            .buttonStyle(BabyTrackPrimaryButtonStyle())
            .padding()
            .background(Color.white)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    private func referenceExists(for testName: String) -> Bool {
        let testClass = String(describing: type(of: self))
        let snapshotsPath = "__Snapshots__/\(testClass)/\(testName).png"
        return FileManager.default.fileExists(atPath: snapshotsPath)
    }
}
