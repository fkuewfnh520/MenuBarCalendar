import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = CalendarView()

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
            updateStatusBarDisplay()
        }

        // Update every second to keep time accurate
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateStatusBarDisplay()
        }

        // Observe settings changes
        let settings = AppSettings.shared
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusBarDisplay()
                }
            }
            .store(in: &cancellables)
    }

    private func updateStatusBarDisplay() {
        guard let button = statusItem?.button else { return }
        let settings = AppSettings.shared
        let now = Date()

        // Icon
        if settings.showIcon {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "日历")
        } else {
            button.image = nil
        }

        // Build title parts
        var parts: [String] = []

        // Time
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "zh_CN")
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        if settings.use24HourFormat {
            timeFormatter.dateFormat = settings.showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            if settings.showAMPM {
                timeFormatter.dateFormat = settings.showSeconds ? "a h:mm:ss" : "a h:mm"
            } else {
                timeFormatter.dateFormat = settings.showSeconds ? "h:mm:ss" : "h:mm"
            }
        }
        parts.append(timeFormatter.string(from: now))

        // Weekday
        if settings.showWeekdayInStatusBar {
            let wf = DateFormatter()
            wf.locale = Locale(identifier: "zh_CN")
            wf.timeZone = TimeZone(identifier: "Asia/Shanghai")
            wf.dateFormat = "EEE"
            parts.append(wf.string(from: now))
        }

        // Solar date
        if settings.showSolarInStatusBar {
            let df = DateFormatter()
            df.locale = Locale(identifier: "zh_CN")
            df.timeZone = TimeZone(identifier: "Asia/Shanghai")
            df.dateFormat = "M月d日"
            parts.append(df.string(from: now))
        }

        // Lunar date
        if settings.showLunarInStatusBar {
            parts.append(LunarCalendar.monthDayText(for: now))
        }

        button.title = " " + parts.joined(separator: " ")
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        if let popover = popover {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}
