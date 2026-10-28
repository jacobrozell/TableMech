import SwiftUI

struct DiceReadout: View {
    var die1: Int
    var die2: Int
    var accessibilityIdentifier: String?

    private var total: Int { die1 + die2 }

    var body: some View {
        HStack(spacing: TMSpace.sm) {
            glyph(die1)
            glyph(die2)
            Text("= \(total)")
                .font(TMFont.readoutM)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rolled \(die1) and \(die2), total \(total)")
        .accessibilityID(accessibilityIdentifier)
    }

    private func glyph(_ face: Int) -> some View {
        Image(systemName: "die.face.\(face).fill")
            .font(.system(size: 28))
            .symbolRenderingMode(.monochrome)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Dice readout") {
    PreviewPair {
        DiceReadout(die1: 4, die2: 5)
    }
}
#endif
