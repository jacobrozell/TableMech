import SwiftUI

enum TMFont {
    static let eyebrow = Font.caption.weight(.semibold).width(.condensed)
    static let stepTitle = Font.title2.weight(.bold).width(.condensed)
    static let cardTitle = Font.headline
    static let body = Font.body
    static let detail = Font.subheadline
    static let stat = Font.subheadline.weight(.medium).monospacedDigit()
    static let statLabel = Font.system(.caption, design: .monospaced).weight(.medium)
    static let readoutM = Font.system(.title, design: .rounded).weight(.bold).monospacedDigit()

    static let readoutLBase: CGFloat = 64

    static func readoutL(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}
