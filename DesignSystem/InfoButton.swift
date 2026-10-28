import SwiftUI

/// System info control. The label stays on the row. The explanation is a popover.
struct InfoButton<Content: View>: View {
    var title: String
    var accessibilityIdentifier: String?
    var onDismiss: () -> Void = {}
    @ViewBuilder var content: (_ dismiss: @escaping () -> Void) -> Content

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "info.circle")
                .font(.body)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .accessibilityLabel("About \(title)")
        .modifier(OptionalAccessibilityID(identifier: accessibilityIdentifier))
        .popover(isPresented: $isPresented) {
            content { isPresented = false }
                .padding(20)
                .frame(minWidth: 280, idealWidth: 320, alignment: .leading)
                .presentationCompactAdaptation(.popover)
        }
        .onChange(of: isPresented) { _, shown in
            if !shown { onDismiss() }
        }
    }
}

private struct OptionalAccessibilityID: ViewModifier {
    var identifier: String?

    func body(content: Content) -> some View {
        if let identifier {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}
