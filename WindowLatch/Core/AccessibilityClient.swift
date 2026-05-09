import AppKit
import ApplicationServices

/// Thin wrapper over the AX C API. **All AX I/O lives here** — no other file should call AX* directly.
///
/// Frames returned/accepted by this client are in AX coordinates: top-left origin,
/// y grows downward, relative to the primary screen's top-left.
enum AccessibilityClient {
    static func focusedWindow() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedAppRef: CFTypeRef?
        let appResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedAppRef
        )
        guard appResult == .success, let appRef = focusedAppRef else { return nil }
        let appElement = appRef as! AXUIElement

        var focusedWinRef: CFTypeRef?
        let winResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWinRef
        )
        guard winResult == .success, let winRef = focusedWinRef else { return nil }
        return (winRef as! AXUIElement)
    }

    static func frame(of window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?

        let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef)
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        guard posResult == .success, sizeResult == .success,
              let posValue = posRef, let sizeValue = sizeRef else { return nil }

        var origin = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posValue as! AXValue, .cgPoint, &origin)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        return CGRect(origin: origin, size: size)
    }

    /// Sets the frame using the canonical position → size → position sequence.
    /// Some apps clamp the first set when the new position would push the old size off-screen,
    /// so the second position write recovers the correct origin.
    @discardableResult
    static func setFrame(_ rect: CGRect, on window: AXUIElement) -> Bool {
        var origin = rect.origin
        var size = rect.size

        guard let posValue = AXValueCreate(.cgPoint, &origin),
              let sizeValue = AXValueCreate(.cgSize, &size) else { return false }

        let r1 = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        let r2 = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        let r3 = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        return r1 == .success && r2 == .success && r3 == .success
    }
}
