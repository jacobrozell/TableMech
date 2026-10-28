import SwiftUI

struct OptionalAccessibilityID: ViewModifier {
    var identifier: String?

    func body(content: Content) -> some View {
        if let identifier {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}

extension View {
    func accessibilityID(_ identifier: String?) -> some View {
        modifier(OptionalAccessibilityID(identifier: identifier))
    }

    /// SwiftUI stores one identifier per element. The extra id sits on a non-interactive sibling so both stay findable.
    func accessibilityIdentifiers(primary: String, extra: String?, label: String) -> some View {
        modifier(DualAccessibilityID(primary: primary, extra: extra, label: label))
    }
}

private struct DualAccessibilityID: ViewModifier {
    var primary: String
    var extra: String?
    var label: String

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(primary)
            .background {
                if let extra {
                    Color.clear
                        .accessibilityElement()
                        .accessibilityIdentifier(extra)
                        .accessibilityLabel(label)
                        .allowsHitTesting(false)
                }
            }
    }
}
