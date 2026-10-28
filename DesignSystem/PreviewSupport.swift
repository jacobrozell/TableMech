import SwiftUI

#if DEBUG
struct PreviewPair<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
                .padding(TMSpace.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
                .padding(TMSpace.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.colorScheme, .dark)
                .background(Color(.systemBackground))
        }
    }
}
#endif
