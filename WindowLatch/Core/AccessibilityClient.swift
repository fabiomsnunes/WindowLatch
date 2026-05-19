import AppKit
import ApplicationServices

/// Thin wrapper over the AX C API. **All AX I/O lives here** — no other file should call AX* directly.
///
/// Frames returned/accepted by this client are in AX coordinates: top-left origin,
/// y grows downward, relative to the primary screen's top-left.
enum AccessibilityClient {
    /// Reports whether the process can drive the Accessibility API.
    ///
    /// `AXIsProcessTrusted()` caches its result per-process: once it has returned
    /// `false` it can keep doing so for the process lifetime even after the user
    /// grants permission to the already-running app. We still call it first — it
    /// registers the app in the Accessibility pane and is correct on the happy
    /// path — but fall back to a live AX read, which reflects the real grant.
    static func isTrusted() -> Bool {
        if AXIsProcessTrusted() { return true }

        let systemWide = AXUIElementCreateSystemWide()
        var ref: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &ref
        )
        // `.apiDisabled` is the only result that means "not trusted"; any other
        // outcome means the API is live for this process.
        return err != .apiDisabled
    }

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

    /// Sets the frame using the size → position → size sequence to avoid an intermediate
    /// state where a still-large window briefly straddles two displays during a cross-monitor
    /// move. Shrinking first keeps the window inside one display while we set the new origin;
    /// the trailing size write covers apps that clamp size to the *old* screen bounds before
    /// the position takes effect.
    @discardableResult
    static func setFrame(_ rect: CGRect, on window: AXUIElement) -> Bool {
        var origin = rect.origin
        var size = rect.size

        guard let posValue = AXValueCreate(.cgPoint, &origin),
              let sizeValue = AXValueCreate(.cgSize, &size) else { return false }

        let r1 = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        let r2 = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        let r3 = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        return r1 == .success && r2 == .success && r3 == .success
    }
}
