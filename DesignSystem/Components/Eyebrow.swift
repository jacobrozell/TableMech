import SwiftUI

struct Eyebrow: View {
    var text: String
    private var accessory: AnyView?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(_ text: String) {
        self.text = text
        self.accessory = nil
    }

    init(_ text: String, @ViewBuilder accessory: () -> some View) {
        self.text = text
        self.accessory = AnyView(accessory())
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: TMSpace.sm) {
            Text(text)
                .font(dynamicTypeSize.isAccessibilitySize ? Font.caption.weight(.semibold) : TMFont.eyebrow)
                .textCase(.uppercase)
                .tracking(dynamicTypeSize.isAccessibilitySize ? 0 : 0.8)
                .foregroundStyle(.secondary)
            Spacer(minLength: TMSpace.sm)
            if let accessory {
                accessory
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#if DEBUG
#Preview("Eyebrow") {
    PreviewPair {
        VStack(alignment: .leading, spacing: TMSpace.md) {
            Eyebrow("Side A — shooting now")
            Eyebrow("If this hits") {
                Button("Swap") {}
                    .font(TMFont.detail)
            }
        }
    }
}
#endif
