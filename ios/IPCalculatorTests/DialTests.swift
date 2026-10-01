import SwiftUI
import XCTest
@testable import IPCalculator

/// The native wheel must stream values mid-scroll, not only once it settles.
/// These run against the real `UIPickerView`, so they also catch an iOS
/// release changing the picker's internal views (live updates would silently
/// degrade to settle-only).
@MainActor
final class DialTests: XCTestCase {
    private var values = [192, 168, 0, 0, 16]
    private var window: UIWindow!
    private var picker: CIDRPickerView!
    private var coordinator: CIDRPicker.Coordinator!

    override func setUp() {
        super.setUp()
        let ranges = [0...255, 0...255, 0...255, 0...255, 0...32]
        let fields = ranges.indices.map { index in
            CIDRPicker.Field(label: "Field \(index)", range: ranges[index],
                             value: Binding(get: { self.values[index] },
                                            set: { self.values[index] = $0 }))
        }
        coordinator = CIDRPicker.Coordinator(fields: fields)
        picker = CIDRPickerView(frame: CGRect(x: 0, y: 0, width: 335, height: 216))
        coordinator.attach(to: picker)
        window = UIWindow(frame: picker.frame)
        window.addSubview(picker)
        window.isHidden = false
        picker.layoutIfNeeded()
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        super.tearDown()
    }

    func testFindsOneWheelPerComponent() {
        XCTAssertEqual(coordinator.wheels.count, CIDRPicker.layout.count)
    }

    func testScrollingStreamsValueBeforeSettling() throws {
        let wheel = try XCTUnwrap(coordinator.wheels.first)
        let rowHeight = picker.rowSize(forComponent: 0).height
        // Spin octet 1 down three rows without ever selecting (no didSelectRow).
        // The column's tables are synced, so moving the center one is enough.
        wheel.center.contentOffset.y += 3 * rowHeight
        XCTAssertEqual(values[0], 195)
    }

    func testWheelsStartAtBoundValues() {
        XCTAssertEqual(picker.selectedRow(inComponent: 0), 192)
        XCTAssertEqual(picker.selectedRow(inComponent: 8), 16)
    }

    func testSeparatorsDoNotScroll() {
        for (component, kind) in CIDRPicker.layout.enumerated() {
            if case .separator = kind {
                XCTAssertTrue(coordinator.wheels[component].tables.allSatisfy { !$0.isScrollEnabled })
            }
        }
    }

    func testNumberColumnsFitThreeDigits() {
        // iPhone SE/mini card width; "255" at 22pt needs ~40pt.
        XCTAssertGreaterThanOrEqual(coordinator.pickerView(picker, widthForComponent: 0), 48)
        XCTAssertGreaterThan(coordinator.pickerView(picker, widthForComponent: 1), 0)
    }

    func testBindingChangeMovesWheel() {
        values[2] = 42
        coordinator.syncSelection(of: picker)
        XCTAssertEqual(picker.selectedRow(inComponent: 4), 42)
    }

    func testSelectingRowWritesValue() {
        coordinator.pickerView(picker, didSelectRow: 10, inComponent: 6)
        XCTAssertEqual(values[3], 10)
    }

    func testPrefixClampsToRange() {
        XCTAssertEqual(coordinator.pickerView(picker, numberOfRowsInComponent: 8), 33)
        XCTAssertEqual(coordinator.title(forRow: 32, component: 8), "32")
        XCTAssertEqual(coordinator.title(forRow: 0, component: 7), "/")
    }
}
