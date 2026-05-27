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
            existingWindow.alphaValue = 1
            scheduleDismiss()
            return
        }

        let previewContent = BackgroundPreviewContent()
        let hostingController = NSHostingController(rootView: previewContent)

        let previewWindow = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 410),
            styleMask: [.titled, .closable, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        previewWindow.contentViewController = hostingController
        previewWindow.title = "背景预览"
        previewWindow.isReleasedWhenClosed = false
        previewWindow.level = .floating
        previewWindow.isMovableByWindowBackground = true
        previewWindow.hidesOnDeactivate = false

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
                window.orderOut(nil)
                window.alphaValue = 1
                self?.window = nil
            })
        } else {
            window.orderOut(nil)
            self.window = nil
        }
    }

    private func positionNextToSettingsWindow(_ previewWindow: NSWindow) {
        if let settingsWindow = NSApp.windows.first(where: { $0.title == "设置" && $0.isVisible }) {
            let settingsFrame = settingsWindow.frame
            let previewSize = previewWindow.frame.size
            let x = settingsFrame.maxX + 12
            let y = settingsFrame.midY - previewSize.height / 2

            if let screen = settingsWindow.screen ?? NSScreen.main {
                let screenFrame = screen.visibleFrame
                let adjustedX = min(x, screenFrame.maxX - previewSize.width)
                let adjustedY = max(min(y, screenFrame.maxY - previewSize.height), screenFrame.minY)
                previewWindow.setFrameOrigin(NSPoint(x: adjustedX, y: adjustedY))
            } else {
                previewWindow.setFrameOrigin(NSPoint(x: x, y: y))
            }
        } else {
            previewWindow.center()
        }
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
