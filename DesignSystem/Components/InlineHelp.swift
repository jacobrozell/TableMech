import SwiftUI

struct InlineHelp: View {
    var label: String = "Why?"
    var text: String

    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: TMSpace.xs) {
            Button {
                if reduceMotion {
                    expanded.toggle()
                } else {
                    withAnimation(TMMotion.reveal) {
                        expanded.toggle()
                    }
                }
            } label: {
                HStack(spacing: TMSpace.xs) {
                    Text(label)
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .font(TMFont.detail.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .accessibilityHint(expanded ? "Hides the extra note" : "Shows a short note")
            if expanded {
                Text(text)
                    .font(TMFont.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview("Inline help") {
    PreviewPair {
        InlineHelp(text: "Equal structure at the end of the last turn is a draw.")
    }
}
#endif
