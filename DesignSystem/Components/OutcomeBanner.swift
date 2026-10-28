import SwiftUI

struct OutcomeBanner: View {
    var hit: Bool
    var rolled: Int
    var targetNumber: Int
    var accessibilityIdentifier: String? = "as.sator.outcome"

    @State private var announced = false

    var body: some View {
        VStack(spacing: TMSpace.xs) {
            HStack(spacing: TMSpace.sm) {
                Image(systemName: hit ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .tmSymbolBounce(value: announced)
                Text(hit ? "HIT" : "MISS")
            }
            .font(TMFont.stepTitle)
            .foregroundStyle(TMColor.onSide)
            Text("Rolled \(rolled) vs \(targetNumber)+")
                .font(TMFont.detail)
                .foregroundStyle(TMColor.onSide)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(TMSpace.lg)
        .background(hit ? TMColor.success : TMColor.danger, in: RoundedRectangle(cornerRadius: TMRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(hit ? "Hit" : "Miss")
        .accessibilityValue("Rolled \(rolled) vs \(targetNumber)+")
        .accessibilityID(accessibilityIdentifier)
        .onAppear { announced = true }
        .tmHaptic(hit ? .hit : .miss, trigger: announced, when: { $0 })
    }
}

#if DEBUG
#Preview("Outcome") {
    PreviewPair {
        VStack(spacing: TMSpace.md) {
            OutcomeBanner(hit: true, rolled: 9, targetNumber: 7)
            OutcomeBanner(hit: false, rolled: 4, targetNumber: 7)
        }
    }
}
#endif
