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
                .symbolRenderingMode(.hierarchical)
                .font(.body)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .accessibilityLabel("About \(title)")
        .accessibilityID(accessibilityIdentifier)
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

    init(
        title: String,
        accessibilityIdentifier: String? = nil,
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder content: @escaping (_ dismiss: @escaping () -> Void) -> Content
    ) {
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
        self.onDismiss = onDismiss
        self.content = content
    }
}

extension InfoButton where Content == InfoContent {
    init(
        title: String,
        message: String,
        links: [InfoLink] = [],
        accessibilityIdentifier: String? = nil,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.init(
            title: title,
            accessibilityIdentifier: accessibilityIdentifier,
            onDismiss: onDismiss
        ) { _ in
            InfoContent(title: title, message: message, links: links)
        }
    }
}

#if DEBUG
#Preview("Info") {
    PreviewPair {
        InfoButton(title: "Move", message: "Inches this ’Mech can walk.")
    }
}
#endif
