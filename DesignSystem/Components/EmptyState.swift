import SwiftUI

struct EmptyState: View {
    var systemImage: String
    var title: String
    var message: String
    var actionTitle: String?
    var accessibilityIdentifier: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: TMSpace.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(TMFont.stepTitle)
                .multilineTextAlignment(.center)
            Text(message)
                .font(TMFont.detail)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryActionButton(title: actionTitle, tint: TMColor.signal, action: action)
            }
        }
        .padding(TMSpace.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityID(accessibilityIdentifier)
    }
}

#if DEBUG
#Preview("Empty") {
    PreviewPair {
        EmptyState(
            systemImage: "list.bullet.rectangle",
            title: "Nothing yet",
            message: "Shots and moves show up here.",
            actionTitle: "Back to the table",
            action: {}
        )
    }
}
#endif
