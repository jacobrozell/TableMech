import SwiftUI

struct StatCell: Identifiable, Sendable {
    var id: String
    var label: String
    var value: String
    var helpTitle: String?
    var helpBody: String?
}

struct StatStrip: View {
    var cells: [StatCell]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: TMSpace.md) {
                cellRow
            }
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: TMSpace.sm) {
                cellRow
            }
        }
        .padding(TMSpace.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TMColor.readout, in: RoundedRectangle(cornerRadius: TMRadius.chip, style: .continuous))
    }

    @ViewBuilder
    private var cellRow: some View {
        ForEach(cells) { cell in
            StatCellView(cell: cell)
        }
    }
}

private struct StatCellView: View {
    var cell: StatCell
    @State private var showHelp = false

    var body: some View {
        if cell.helpBody != nil {
            Button {
                showHelp = true
            } label: {
                label
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showHelp) {
                InfoContent(title: cell.helpTitle ?? cell.label, message: cell.helpBody ?? "")
                    .padding(TMSpace.lg)
                    .frame(minWidth: 240, alignment: .leading)
                    .presentationCompactAdaptation(.popover)
            }
        } else {
            label
        }
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: TMSpace.xxs) {
            Text(cell.label)
                .font(TMFont.statLabel)
                .foregroundStyle(.secondary)
            Text(cell.value)
                .font(TMFont.stat)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cell.label) \(cell.value)")
    }
}

#if DEBUG
#Preview("Stats") {
    PreviewPair {
        StatStrip(cells: [
            StatCell(id: "mv", label: "MV", value: "10″/6″j", helpTitle: "Move", helpBody: "Inches it can walk. The number after the slash is jump."),
            StatCell(id: "tmm", label: "TMM", value: "2"),
            StatCell(id: "skl", label: "SKL", value: "4"),
            StatCell(id: "dmg", label: "DMG", value: "2·2·1", helpTitle: "Damage", helpBody: "Short, medium, and long range damage.")
        ])
    }
}

#Preview("Stats AX5") {
    StatStrip(cells: [
        StatCell(id: "mv", label: "MV", value: "10″/6″j"),
        StatCell(id: "tmm", label: "TMM", value: "2"),
        StatCell(id: "skl", label: "SKL", value: "4"),
        StatCell(id: "dmg", label: "DMG", value: "2·2·1")
    ])
    .padding()
    .environment(\.dynamicTypeSize, .accessibility5)
}
#endif
