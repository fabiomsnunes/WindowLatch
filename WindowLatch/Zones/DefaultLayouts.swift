import CoreGraphics

nonisolated enum DefaultLayouts {
    // MARK: - Halves

    static let leftHalf = Zone(id: "left-half", label: "Left Half", rect: CGRect(x: 0, y: 0, width: 0.5, height: 1))
    static let rightHalf = Zone(
        id: "right-half",
        label: "Right Half",
        rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1)
    )
    static let topHalf = Zone(id: "top-half", label: "Top Half", rect: CGRect(x: 0, y: 0, width: 1, height: 0.5))
    static let bottomHalf = Zone(
        id: "bottom-half",
        label: "Bottom Half",
        rect: CGRect(x: 0, y: 0.5, width: 1, height: 0.5)
    )

    // MARK: - Thirds

    static let leftThird = Zone(
        id: "left-third",
        label: "Left Third",
        rect: CGRect(x: 0, y: 0, width: 1.0 / 3, height: 1)
    )
    static let leftTwoThirds = Zone(
        id: "left-two-thirds",
        label: "Left 2/3",
        rect: CGRect(x: 0, y: 0, width: 2.0 / 3, height: 1)
    )
    static let rightThird = Zone(
        id: "right-third",
        label: "Right Third",
        rect: CGRect(x: 2.0 / 3, y: 0, width: 1.0 / 3, height: 1)
    )
    static let rightTwoThirds = Zone(
        id: "right-two-thirds",
        label: "Right 2/3",
        rect: CGRect(x: 1.0 / 3, y: 0, width: 2.0 / 3, height: 1)
    )
    static let topThird = Zone(id: "top-third", label: "Top Third", rect: CGRect(x: 0, y: 0, width: 1, height: 1.0 / 3))
    static let topTwoThirds = Zone(
        id: "top-two-thirds",
        label: "Top 2/3",
        rect: CGRect(x: 0, y: 0, width: 1, height: 2.0 / 3)
    )
    static let bottomThird = Zone(
        id: "bottom-third",
        label: "Bottom Third",
        rect: CGRect(x: 0, y: 2.0 / 3, width: 1, height: 1.0 / 3)
    )
    static let bottomTwoThirds = Zone(
        id: "bottom-two-thirds",
        label: "Bottom 2/3",
        rect: CGRect(x: 0, y: 1.0 / 3, width: 1, height: 2.0 / 3)
    )

    // MARK: - Quadrants

    static let topLeftQuadrant = Zone(
        id: "top-left",
        label: "Top Left",
        rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
    )
    static let topRightQuadrant = Zone(
        id: "top-right",
        label: "Top Right",
        rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5)
    )
    static let bottomLeftQuadrant = Zone(
        id: "bottom-left",
        label: "Bottom Left",
        rect: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)
    )
    static let bottomRightQuadrant = Zone(
        id: "bottom-right",
        label: "Bottom Right",
        rect: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
    )

    /// All zones the cycle engine may match against (everything reachable from cycle sequences).
    static let allCycleZones: [Zone] = [
        leftHalf, rightHalf, topHalf, bottomHalf,
        leftThird, leftTwoThirds, rightThird, rightTwoThirds,
        topThird, topTwoThirds, bottomThird, bottomTwoThirds,
        topLeftQuadrant, topRightQuadrant, bottomLeftQuadrant, bottomRightQuadrant
    ]
}
