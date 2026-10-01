import SwiftUI
import UIKit

/// The CIDR rollers as one native `UIPickerView`: system wheel look, sound,
/// haptics and VoiceOver. A plain picker only reports a row once scrolling
/// settles, so the coordinator also watches each wheel's scroll offset and
/// writes the row under the selection bar continuously, so results
/// recalculate mid-scroll. If a future iOS changes the picker's internal
/// views, it falls back to settle-only updates (caught by `DialTests`).
struct CIDRPicker: UIViewRepresentable {
    struct Field {
        let label: String
        let range: ClosedRange<Int>
        let value: Binding<Int>
    }

    enum Component: Equatable {
        case field(Int)
        case separator(String)
    }

    /// 192 . 168 . 0 . 0 / 16 — separators are fixed one-row wheels.
    static let layout: [Component] = [
        .field(0), .separator("."), .field(1), .separator("."),
        .field(2), .separator("."), .field(3), .separator("/"), .field(4),
    ]

    let fields: [Field]

    func makeCoordinator() -> Coordinator { Coordinator(fields: fields) }

    func makeUIView(context: Context) -> CIDRPickerView {
        let picker = CIDRPickerView()
        // Fill the card's width instead of UIPickerView's 320pt intrinsic size.
        picker.setContentHuggingPriority(.defaultLow, for: .horizontal)
        picker.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        context.coordinator.attach(to: picker)
        return picker
    }

    func updateUIView(_ picker: CIDRPickerView, context: Context) {
        context.coordinator.fields = fields
        context.coordinator.syncSelection(of: picker)
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate,
                             UIPickerViewAccessibilityDelegate {
        /// One spinning column. UIPickerView draws each from several synced
        /// tables (faded top, the strip under the bar, faded bottom).
        struct Wheel {
            let tables: [UITableView]
            /// The table showing the strip under the selection bar.
            let center: UITableView
            var isMoving: Bool { tables.contains { $0.isTracking || $0.isDragging || $0.isDecelerating } }
        }

        var fields: [Field]
        /// Each component's wheel, indexed by component; empty if not found.
        private(set) var wheels: [Wheel] = []
        private var observations: [NSKeyValueObservation] = []

        private static let separatorWidth: CGFloat = 10
        private static let componentSpacing: CGFloat = 5
        /// Native wheel size; monospaced so digits don't shimmy while spinning.
        private static let font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)

        init(fields: [Field]) { self.fields = fields }

        func attach(to picker: CIDRPickerView) {
            picker.dataSource = self
            picker.delegate = self
            picker.onLayout = { [weak self, weak picker] in
                guard let self, let picker else { return }
                observeScrolling(in: picker)
                syncSelection(of: picker)
            }
        }

        /// Moves wheels to the bound values, except wheels the user is spinning.
        func syncSelection(of picker: UIPickerView) {
            for (component, kind) in CIDRPicker.layout.enumerated() {
                guard case .field(let index) = kind else { continue }
                if component < wheels.count, wheels[component].isMoving { continue }
                let field = fields[index]
                let row = field.value.wrappedValue - field.range.lowerBound
                if picker.selectedRow(inComponent: component) != row {
                    picker.selectRow(row, inComponent: component, animated: false)
                }
            }
        }

        private func observeScrolling(in picker: UIPickerView) {
            let found = Self.findWheels(in: picker)
            guard found.count == CIDRPicker.layout.count else {
                observations = []
                wheels = []
                return
            }
            if found.map(\.center).elementsEqual(wheels.map(\.center), by: ===) { return }
            wheels = found
            observations = found.enumerated().map { component, wheel in
                if case .separator = CIDRPicker.layout[component] {
                    wheel.tables.forEach { $0.isScrollEnabled = false }
                }
                return wheel.center.observe(\.contentOffset) { [weak self] _, _ in
                    MainActor.assumeIsolated { self?.track(component: component) }
                }
            }
        }

        /// Groups the picker's tables by column (in component order) and picks
        /// each column's table whose clipping container is the selection strip.
        private static func findWheels(in picker: UIPickerView) -> [Wheel] {
            var columns: [(column: UIView, tables: [UITableView])] = []
            for table in picker.descendants(ofType: UITableView.self) {
                guard let column = table.superview?.superview else { return [] }
                if let index = columns.firstIndex(where: { $0.column === column }) {
                    columns[index].tables.append(table)
                } else {
                    columns.append((column, [table]))
                }
            }
            return columns.compactMap { column in
                let center = column.tables.min {
                    ($0.superview?.bounds.height ?? .infinity) < ($1.superview?.bounds.height ?? .infinity)
                }
                return center.map { Wheel(tables: column.tables, center: $0) }
            }
        }

        /// Commits whichever row currently sits under the selection bar.
        private func track(component: Int) {
            let wheel = wheels[component]
            guard let indexPath = wheel.center.indexPathForRow(
                at: CGPoint(x: wheel.center.bounds.midX, y: wheel.center.bounds.midY))
            else { return }
            commit(row: indexPath.row, component: component)
        }

        private func commit(row: Int, component: Int) {
            guard case .field(let index) = CIDRPicker.layout[component] else { return }
            let field = fields[index]
            let value = min(max(field.range.lowerBound + row, field.range.lowerBound),
                            field.range.upperBound)
            if field.value.wrappedValue != value { field.value.wrappedValue = value }
        }

        // MARK: Data source & delegate

        func numberOfComponents(in pickerView: UIPickerView) -> Int { CIDRPicker.layout.count }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch CIDRPicker.layout[component] {
            case .field(let index): fields[index].range.count
            case .separator: 1
            }
        }

        func title(forRow row: Int, component: Int) -> String {
            switch CIDRPicker.layout[component] {
            case .field(let index): "\(fields[index].range.lowerBound + row)"
            case .separator(let symbol): symbol
            }
        }

        /// Own labels rather than `titleForRow`: the system cell pads titles by
        /// ~9pt per side, which truncates "255" and hides the separators at
        /// this many columns. The wheel still applies its native 3D curve.
        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int,
                        forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            label.font = Self.font
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            label.text = title(forRow: row, component: component)
            if case .separator = CIDRPicker.layout[component] {
                label.textColor = .secondaryLabel
                label.isAccessibilityElement = false
            } else {
                label.textColor = .label
            }
            return label
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            if case .separator = CIDRPicker.layout[component] { return Self.separatorWidth }
            let separators = CIDRPicker.layout.count - fields.count
            let spacing = Self.componentSpacing * CGFloat(CIDRPicker.layout.count - 1)
            let available = pickerView.bounds.width - spacing - Self.separatorWidth * CGFloat(separators)
            return max(available / CGFloat(fields.count), 40)
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            commit(row: row, component: component)
        }

        func pickerView(_ pickerView: UIPickerView, accessibilityLabelForComponent component: Int) -> String? {
            guard case .field(let index) = CIDRPicker.layout[component] else { return nil }
            return fields[index].label
        }
    }
}

/// Re-measures component widths whenever the picker's width changes.
final class CIDRPickerView: UIPickerView {
    var onLayout: (() -> Void)?
    private var measuredWidth: CGFloat = 0

    override func layoutSubviews() {
        if bounds.width != measuredWidth {
            measuredWidth = bounds.width
            reloadAllComponents()
        }
        super.layoutSubviews()
        onLayout?()
    }
}

private extension UIView {
    /// Depth-first, so sibling columns keep their component order.
    func descendants<T: UIView>(ofType type: T.Type) -> [T] {
        subviews.flatMap { subview -> [T] in
            if let match = subview as? T { return [match] }
            return subview.descendants(ofType: type)
        }
    }
}
