import CoreGraphics

enum DefaultLayouts {
    static let halves = ZoneLayout(
        id: "halves",
        label: "Halves",
        zones: [
            Zone(id: "left-half",  label: "Left Half",  rect: CGRect(x: 0,   y: 0, width: 0.5, height: 1)),
            Zone(id: "right-half", label: "Right Half", rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1)),
        ]
    )

    static let quadrants = ZoneLayout(
        id: "quadrants",
        label: "Quadrants",
        zones: [
            Zone(id: "top-left",     label: "Top Left",     rect: CGRect(x: 0,   y: 0,   width: 0.5, height: 0.5)),
            Zone(id: "top-right",    label: "Top Right",    rect: CGRect(x: 0.5, y: 0,   width: 0.5, height: 0.5)),
            Zone(id: "bottom-left",  label: "Bottom Left",  rect: CGRect(x: 0,   y: 0.5, width: 0.5, height: 0.5)),
            Zone(id: "bottom-right", label: "Bottom Right", rect: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)),
        ]
    )

    static let maximize = Zone(
        id: "maximize",
        label: "Maximize",
        rect: CGRect(x: 0, y: 0, width: 1, height: 1)
    )
}
