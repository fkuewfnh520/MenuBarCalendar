import AppKit
import SwiftUI

@MainActor
final class BackgroundPreviewWindowController {
    static let shared = BackgroundPreviewWindowController()

    private var window: NSWindow?
    private var dismissTimer: Timer?

    private init() {}

    // MARK: - Public

    func startObserving() {}

    func stopObserving() {
        dismissWindow(animated: false)
    }

    func showPreview() {
        dismissTimer?.invalidate()

        if let existingWindow = window, existingWindow.isVisible {
            positionNextToSettingsWindow(existingWindow)
            existingWindow.alphaValue = 1
            scheduleDismiss()
            return
        }

        let previewContent = BackgroundPreviewContent()
        let hostingController = NSHostingController(rootView: previewContent)

        let previewWindow = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 410),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        previewWindow.contentViewController = hostingController
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 360, height: 410)
        hostingController.view.layoutSubtreeIfNeeded()
        previewWindow.contentView?.layoutSubtreeIfNeeded()
        previewWindow.setContentSize(NSSize(width: 360, height: 410))
        previewWindow.title = "背景预览"
        previewWindow.isReleasedWhenClosed = false
        previewWindow.level = .floating
        previewWindow.isMovableByWindowBackground = true
        previewWindow.hidesOnDeactivate = false
        previewWindow.backgroundColor = NSColor.windowBackgroundColor

        positionNextToSettingsWindow(previewWindow)

        previewWindow.makeKeyAndOrderFront(nil)
        window = previewWindow

        scheduleDismiss()
    }

    // MARK: - Private

    private func scheduleDismiss() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.dismissWindow(animated: true)
            }
        }
    }

    private func dismissWindow(animated: Bool) {
        dismissTimer?.invalidate()
        dismissTimer = nil

        guard let window else { return }

        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                window.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                Task { @MainActor in
                    window.orderOut(nil)
                    window.alphaValue = 1
                    self?.window = nil
                }
            })
        } else {
            window.orderOut(nil)
            self.window = nil
        }
    }

    private func positionNextToSettingsWindow(_ previewWindow: NSWindow) {
        if let settingsWindow = NSApp.windows.first(where: { $0.title == "设置" && $0.isVisible }) {
            let settingsFrame = settingsWindow.frame
            let spacing: CGFloat = 12
            let margin: CGFloat = 10
            let previewSize = previewWindow.frame.size

            if let screen = settingsWindow.screen ?? NSScreen.main {
                let bounds = screen.visibleFrame.insetBy(dx: margin, dy: margin)
                let rightX = settingsFrame.maxX + spacing
                let leftX = settingsFrame.minX - previewSize.width - spacing
                let fitsRight = rightX + previewSize.width <= bounds.maxX
                let fitsLeft = leftX >= bounds.minX
                let availableRight = max(0, bounds.maxX - rightX)
                let availableLeft = max(0, settingsFrame.minX - spacing - bounds.minX)

                let preferredSide: PreviewSide
                if fitsRight {
                    preferredSide = .right
                } else if fitsLeft {
                    preferredSide = .left
                } else {
                    preferredSide = availableLeft >= availableRight ? .left : .right
                }

                let availableWidth = preferredSide == .right ? availableRight : availableLeft
                let width = min(previewSize.width, availableWidth)
                let size = NSSize(width: width, height: previewSize.height)
                let preferredX = preferredSide == .right
                    ? rightX
                    : settingsFrame.minX - size.width - spacing
                let preferredY = settingsFrame.midY - previewSize.height / 2
                let frame = clamp(
                    NSRect(origin: NSPoint(x: preferredX, y: preferredY), size: size),
                    to: bounds
                )
                previewWindow.setFrame(frame, display: true)
            } else {
                previewWindow.setFrameOrigin(NSPoint(
                    x: settingsFrame.maxX + spacing,
                    y: settingsFrame.midY - previewSize.height / 2
                ))
            }
        } else {
            previewWindow.center()
        }
    }

    private enum PreviewSide {
        case left
        case right
    }

    private func clamp(_ frame: NSRect, to bounds: NSRect) -> NSRect {
        var frame = frame

        if frame.width > bounds.width {
            frame.size.width = bounds.width
        }
        if frame.height > bounds.height {
            frame.size.height = bounds.height
        }
        if frame.maxX > bounds.maxX {
            frame.origin.x = bounds.maxX - frame.width
        }
        if frame.minX < bounds.minX {
            frame.origin.x = bounds.minX
        }
        if frame.maxY > bounds.maxY {
            frame.origin.y = bounds.maxY - frame.height
        }
        if frame.minY < bounds.minY {
            frame.origin.y = bounds.minY
        }

        return frame
    }
}

// MARK: - Preview Content View

private struct BackgroundPreviewContent: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        CalendarView()
            .frame(width: 360)
            .allowsHitTesting(false)
    }
}
