import XCTest
@testable import IPCalculator

/// The dial must stream integer values mid-drag (drag up increases).
final class DialTests: XCTestCase {
    private let rowHeight: CGFloat = 34

    func testDragUpIncreasesLive() {
        XCTAssertEqual(
            dialClampedValue(base: 192, translation: -rowHeight, rowHeight: rowHeight, range: 0...255),
            193)
    }

    func testDragDownDecreasesLive() {
        XCTAssertEqual(
            dialClampedValue(base: 192, translation: rowHeight, rowHeight: rowHeight, range: 0...255),
            191)
    }

    func testPartialDragKeepsCurrentValue() {
        // Less than half a row: no integer change yet, only visual glide.
        XCTAssertEqual(
            dialClampedValue(base: 192, translation: -10, rowHeight: rowHeight, range: 0...255),
            192)
    }

    func testClampsAtBounds() {
        XCTAssertEqual(
            dialClampedValue(base: 255, translation: -500, rowHeight: rowHeight, range: 0...255),
            255)
        XCTAssertEqual(
            dialClampedValue(base: 0, translation: 500, rowHeight: rowHeight, range: 0...255),
            0)
        XCTAssertEqual(
            dialClampedValue(base: 32, translation: -rowHeight, rowHeight: rowHeight, range: 0...32),
            32)
    }

    func testFractionalShiftGlidesBetweenRows() {
        XCTAssertEqual(
            dialFractionalShift(base: 192, value: 192, translation: 0, rowHeight: rowHeight), 0,
            accuracy: 0.001)
        XCTAssertEqual(
            dialFractionalShift(base: 192, value: 192, translation: -17, rowHeight: rowHeight), 17,
            accuracy: 0.001)
    }
}
