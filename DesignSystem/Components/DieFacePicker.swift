import SwiftUI

struct DieFacePicker: View {
    var title: String
    @Binding var value: Int?
    var accessibilityIdentifier: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var symbolSize: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: TMSpace.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: TMSpace.sm)
                if let value {
                    Text("\(value)")
                        .font(TMFont.stat)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            LazyVGrid(columns: columns, spacing: TMSpace.sm) {
                ForEach(1...6, id: \.self) { face in
                    faceButton(face)
                }
            }
        }
        .accessibilityID(accessibilityIdentifier)
        .tmHaptic(.dieFaceSelected, trigger: value, when: { $0 != nil })
    }

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 3 : 6
        return Array(repeating: GridItem(.flexible(), spacing: TMSpace.sm), count: count)
    }

    private func faceButton(_ face: Int) -> some View {
        let selected = value == face
        return Button {
            value = face
        } label: {
            Image(systemName: selected ? "die.face.\(face).fill" : "die.face.\(face)")
                .font(.system(size: symbolSize))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(selected ? TMColor.onSignal : Color.primary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    RoundedRectangle(cornerRadius: TMRadius.chip, style: .continuous)
                        .fill(selected ? TMColor.signal : Color.secondary.opacity(0.18))
                }
                .tmSymbolBounce(value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) \(face)")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityRemoveTraits(selected ? [] : .isSelected)
    }
}

#if DEBUG
#Preview("Die faces") {
    PreviewPair {
        DieFacePickerPreviewHost()
    }
}

#Preview("Die faces AX5") {
    DieFacePickerPreviewHost()
        .padding()
        .environment(\.dynamicTypeSize, .accessibility5)
}

private struct DieFacePickerPreviewHost: View {
    @State private var value: Int? = 4

    var body: some View {
        DieFacePicker(title: "First die", value: $value, accessibilityIdentifier: "preview.die1")
    }
}
#endif
