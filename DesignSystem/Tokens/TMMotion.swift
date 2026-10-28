import SwiftUI

enum TMMotion {
    static let stateDuration: TimeInterval = 0.25
    static let revealDuration: TimeInterval = 0.35
    static let drainDuration: TimeInterval = 0.45
    static let phaseDuration: TimeInterval = 0.4
    static let pipStagger: TimeInterval = 0.04
    static let reducedDuration: TimeInterval = 0.15

    static var state: Animation { .snappy(duration: stateDuration) }
    static var reveal: Animation { .smooth(duration: revealDuration) }
    static var drain: Animation { .easeOut(duration: drainDuration) }
    static var phase: Animation { .spring(duration: phaseDuration, bounce: 0.15) }
    static var reduced: Animation { .easeOut(duration: reducedDuration) }
}

extension View {
    /// Substitutes a short cross-fade when Reduce Motion is on.
    func tmAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(TMReduceMotionAnimation(animation: animation, value: value))
    }

    func tmSymbolBounce<V: Equatable>(value: V) -> some View {
        modifier(TMSymbolBounce(value: value))
    }
}

private struct TMReduceMotionAnimation<V: Equatable>: ViewModifier {
    var animation: Animation
    var value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? TMMotion.reduced : animation, value: value)
    }
}

private struct TMSymbolBounce<V: Equatable>: ViewModifier {
    var value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.symbolEffect(.bounce, value: value)
        }
    }
}
