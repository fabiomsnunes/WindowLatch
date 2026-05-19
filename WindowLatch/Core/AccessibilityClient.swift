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

    /// Resolves the window to act on for the frontmost app.
    ///
    /// We identify the frontmost app via `NSWorkspace` rather than the systemwide
    /// AX element's `kAXFocusedApplicationAttribute`: some apps (Spark, …) never
    /// register as the AX focused application, so that attribute returns
    /// `kAXErrorNoValue`. `NSWorkspace` always reports the frontmost app.
    ///
    /// `kAXFocusedWindowAttribute` is then the right answer for well-behaved apps,
    /// but some Electron apps never publish it either — so we fall back to the
    /// main window, then to the first standard window in the app's window list.
    static func focusedWindow() -> AXUIElement? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        if let window = copyElement(appElement, kAXFocusedWindowAttribute) {
            return window
        }
        if let window = copyElement(appElement, kAXMainWindowAttribute) {
            return window
        }
        return firstStandardWindow(of: appElement)
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

    /// Copies an attribute expected to hold a single `AXUIElement`, or `nil`.
    private static func copyElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var ref: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &ref)
        guard result == .success, let ref else { return nil }
        return (ref as! AXUIElement)
    }

    /// Returns the app's main window if one is flagged, otherwise its first window.
    private static func firstStandardWindow(of app: AXUIElement) -> AXUIElement? {
        var ref: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &ref)
        guard result == .success, let windows = ref as? [AXUIElement], !windows.isEmpty else {
            return nil
        }
        let main = windows.first { window in
            var mainRef: CFTypeRef?
            let r = AXUIElementCopyAttributeValue(window, kAXMainAttribute as CFString, &mainRef)
            return r == .success
                && (mainRef as? Bool == true || (mainRef as? NSNumber)?.boolValue == true)
        }
        return main ?? windows.first
    }
}
