import CoreGraphics

/// A single rectangular zone of the screen.
///
/// `rect` is expressed in fractional coordinates (0..1) using AX-style orientation:
/// origin `(0, 0)` is the top-left of the screen's visible area; y grows downward.
struct Zone: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let rect: CGRect
}
