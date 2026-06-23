import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var calendarPanel: NSPanel?
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var isSettingsPreviewActive = false
    private var hideAnimationToken = 0
    private let calendarPanelSize = NSSize(width: 360, height: 480)
    private let statusTitleFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupCalendarPanel()
        setupOutsideClickMonitors()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.autosaveName = "MenuBarCalendarStatusItem"
        if let button = statusItem?.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
            updateStatusBarDisplay()
        }

        scheduleNextStatusBarUpdate()

        // Observe settings changes
        let settings = AppSettings.shared
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusBarDisplay()
                    self?.scheduleNextStatusBarUpdate()
                }
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
        }
        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
        }
    }

    private func updateStatusBarDisplay() {
        guard let button = statusItem?.button else { return }
        let settings = AppSettings.shared
        let now = Date()

        button.image = nil
        button.attributedTitle = statusAttributedTitle(for: now, settings: settings)
        statusItem?.length = reservedStatusItemLength(for: now, settings: settings)
    }

    private func scheduleNextStatusBarUpdate() {
        timer?.invalidate()

        let interval = nextStatusBarUpdateInterval(settings: AppSettings.shared)
        let newTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.updateStatusBarDisplay()
            self?.scheduleNextStatusBarUpdate()
        }
        newTimer.tolerance = AppSettings.shared.showSeconds ? 0.05 : 1
        timer = newTimer
    }

    private func nextStatusBarUpdateInterval(settings: AppSettings) -> TimeInterval {
        if settings.showSeconds {
            return 1
        }

        let second = Calendar(identifier: .gregorian).component(.second, from: Date())
        return TimeInterval(max(1, 60 - second))
    }

    private func statusAttributedTitle(for date: Date, settings: AppSettings) -> NSAttributedString {
        let title = NSMutableAttributedString()
        let parts = statusParts(for: date, settings: settings)

        for (index, part) in parts.enumerated() {
            if index > 0 {
                title.append(NSAttributedString(string: " ", attributes: statusTextAttributes))
            }

            switch part {
            case .icon:
                let attachment = NSTextAttachment()
                let image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "日历")
                image?.size = NSSize(width: 15, height: 15)
                attachment.image = image
                attachment.bounds = NSRect(x: 0, y: -2, width: 15, height: 15)
                title.append(NSAttributedString(attachment: attachment))
            case .text(let value):
                title.append(NSAttributedString(string: value, attributes: statusTextAttributes))
            }
        }

        return title
    }

    private var statusTextAttributes: [NSAttributedString.Key: Any] {
        [
            .font: statusTitleFont,
            .foregroundColor: NSColor.labelColor,
        ]
    }

    private enum StatusPart {
        case icon
        case text(String)
    }

    private func statusParts(for date: Date, settings: AppSettings) -> [StatusPart] {
        settings.statusBarItemOrder.compactMap { item in
            switch item {
            case .icon:
                return settings.showIcon ? .icon : nil
            case .weekday:
                guard settings.showWeekdayInStatusBar else { return nil }
                return .text(Self.statusWeekdayFormatter.string(from: date))
            case .solar:
                guard settings.showSolarInStatusBar else { return nil }
                return .text(Self.statusDateFormatter.string(from: date))
            case .lunar:
                guard settings.showLunarInStatusBar else { return nil }
                return .text(LunarCalendar.monthDayText(for: date))
            case .time:
                return .text(statusTimeText(for: date, settings: settings))
            }
        }
    }

    private func statusTitle(for date: Date, settings: AppSettings) -> String {
        statusParts(for: date, settings: settings).compactMap { part in
            switch part {
            case .icon: return settings.showIcon ? "□" : nil
            case .text(let value): return value
            }
        }
        .joined(separator: " ")
    }

    private func statusTimeText(for date: Date, settings: AppSettings) -> String {
        if settings.use24HourFormat {
            Self.statusTimeFormatter.dateFormat = settings.showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            if settings.showAMPM {
                Self.statusTimeFormatter.dateFormat = settings.showSeconds ? "a h:mm:ss" : "a h:mm"
            } else {
                Self.statusTimeFormatter.dateFormat = settings.showSeconds ? "h:mm:ss" : "h:mm"
            }
        }
        return Self.statusTimeFormatter.string(from: date)
    }

    private func reservedStatusItemLength(for date: Date, settings: AppSettings) -> CGFloat {
        let actualTitle = statusTitle(for: date, settings: settings)
        var candidates = [actualTitle]

        if settings.use24HourFormat {
            candidates.append(settings.showSeconds ? " 00:00:00" : " 00:00")
        } else if settings.showAMPM {
            candidates.append(settings.showSeconds ? " 下午 00:00:00" : " 下午 00:00")
        } else {
            candidates.append(settings.showSeconds ? " 00:00:00" : " 00:00")
        }

        let titleWidth = candidates
            .map { ($0 as NSString).size(withAttributes: [.font: statusTitleFont]).width }
            .max() ?? 0
        let horizontalPadding: CGFloat = 18
        return ceil(titleWidth + horizontalPadding)
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let calendarPanel else { return }
        if calendarPanel.isVisible {
            guard !isSettingsPreviewActive else { return }
            hideCalendarPanel()
        } else {
            showCalendarPanel()
        }
    }

    func keepCalendarOpenForSettingsPreview() {
        isSettingsPreviewActive = true
        showCalendarPanel()
    }

    func closeSettingsPreviewCalendar() {
        isSettingsPreviewActive = false
        hideCalendarPanel()
    }

    private func setupCalendarPanel() {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: calendarPanelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = NSHostingController(rootView: CalendarView())
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.alphaValue = 0
        panel.isOpaque = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        calendarPanel = panel
    }

    private func setupOutsideClickMonitors() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.hideCalendarPanelIfNeeded(forWindowEvent: event)
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            let mouseLocation = NSEvent.mouseLocation
            DispatchQueue.main.async {
                self?.hideCalendarPanelIfNeeded(at: mouseLocation)
            }
        }
    }

    private func showCalendarPanel() {
        guard let panel = calendarPanel else { return }
        hideAnimationToken += 1
        NotificationCenter.default.post(name: .calendarPanelWillShow, object: nil)
        positionCalendarPanel(panel)

        guard !panel.isVisible else {
            panel.alphaValue = 1
            return
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    private func hideCalendarPanel() {
        guard let panel = calendarPanel, panel.isVisible else { return }

        hideAnimationToken += 1
        let token = hideAnimationToken
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self, weak panel] in
            guard let self, token == self.hideAnimationToken else { return }
            panel?.orderOut(nil)
            NotificationCenter.default.post(name: .calendarPanelDidHide, object: nil)
        }
    }

    private func hideCalendarPanelIfNeeded(forWindowEvent event: NSEvent) {
        guard shouldAutoHideCalendar,
              let panel = calendarPanel,
              panel.isVisible
        else { return }

        if event.window === panel {
            return
        }

        if SettingsWindowController.shared.containsWindow(event.window) {
            return
        }

        if let statusWindow = statusItem?.button?.window,
           event.window === statusWindow,
           isPointInStatusButton(event.locationInWindow) {
            return
        }

        hideCalendarPanel()
    }

    private func hideCalendarPanelIfNeeded(at screenPoint: NSPoint) {
        guard shouldAutoHideCalendar,
              let panel = calendarPanel,
              panel.isVisible
        else { return }

        if panel.frame.contains(screenPoint) || statusButtonFrameInScreen()?.contains(screenPoint) == true {
            return
        }

        hideCalendarPanel()
    }

    private var shouldAutoHideCalendar: Bool {
        !isSettingsPreviewActive && !SettingsWindowController.shared.isWindowVisible
    }

    private func positionCalendarPanel(_ panel: NSPanel) {
        let statusFrame = statusButtonFrameInScreen()
        let screen = statusFrame.flatMap { frame in
            NSScreen.screens.first { $0.frame.contains(NSPoint(x: frame.midX, y: frame.midY)) }
        } ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }

        let anchor = statusFrame ?? NSRect(origin: NSEvent.mouseLocation, size: .zero)
        let margin: CGFloat = 8
        let x = min(
            max(anchor.midX - calendarPanelSize.width / 2, visibleFrame.minX + margin),
            visibleFrame.maxX - calendarPanelSize.width - margin
        )
        let preferredY = anchor.minY - calendarPanelSize.height - 6
        let y = max(preferredY, visibleFrame.minY + margin)

        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: calendarPanelSize), display: true)
    }

    private func statusButtonFrameInScreen() -> NSRect? {
        guard let button = statusItem?.button, let window = button.window else { return nil }
        return window.convertToScreen(button.frame)
    }

    private func isPointInStatusButton(_ windowPoint: NSPoint) -> Bool {
        guard let button = statusItem?.button else { return false }
        return button.frame.contains(windowPoint)
    }

    private static let statusWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let statusDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    private static let statusTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }()
}
